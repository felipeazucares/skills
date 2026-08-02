---
name: build-crit-auto
description: >-
  A worker/critic agentic dev loop that AUTOMATES the build-critique-loop:
  implement the requested piece of work, hand the resulting diff to a
  self-selected STRONGER REASONING MODEL (chosen at runtime, not hardcoded)
  for a broad critique, then automatically apply EVERY actionable finding it
  raises — no stop-and-confirm gate, no user prompting mid-cycle — and verify
  with the project's tests plus a re-check by the same critic model. Use this
  whenever the user wants the next plan item or piece of work BUILT *and*
  CRITIQUED *and* hardened in one pass without reviewing findings first, e.g.
  "build it then have the critic check it and fix everything it finds",
  "auto build-crit loop", "do the next thing, critique it, and apply all
  issues automatically", "implement then review-and-fix without asking",
  "worker-critic loop with no gate". Prefer this over build-critique-loop
  whenever the user explicitly wants findings applied automatically.
---

# Build–Critique–Auto Loop

A worker/critic development cycle that runs the whole loop with NO user gate.
The **worker** (this session) implements the requested work; a **critic** — a
stronger reasoning model, *self-selected* at runtime — tears the diff apart
with fresh eyes; the worker then **automatically applies every actionable
finding** and verifies. One item per invocation — then stop and hand back.

The value of the pattern is the *asymmetry and the fresh eyes*: the model that
just wrote the code is the worst judge of it (it's invested in its own
approach, and it can't see the assumptions it made). Delegating the critique to
a separate, stronger-reasoning agent that sees only the diff — not the
reasoning that produced it — surfaces bugs and shortcuts the author is blind
to, and keeps the heavy review reasoning out of this session's context.

> **Why "self-select" instead of a fixed model:** a hardcoded model (e.g. "Opus
> 4.8") goes stale — the user's available providers change, and the "best"
> reasoning model is environment-specific. Selecting the strongest reasoning
> model *available right now* (and falling back gracefully when there is none)
> keeps the critique as strong as the environment allows without breaking when
> the model isn't configured.

## The loop

1. **Implement** the requested work (test-first). If it's a plan item, use
   `/donext`; otherwise FOCUS ON THE WORK SPECIFIED.
2. **Self-select a stronger reasoning model** for the critique and spawn the
   critic on it.
3. **Present** the findings as a numbered severity list — then **immediately
   implement ALL actionable findings** (this skill has no step-3 gate).
4. **Verify** — run the project's relevant tests *and* a quick re-check of the
   applied fixes by the same critic model.
5. **Report** and stop. Do not roll on to the next plan item.

---

## Step 0 — Preflight

- **Identify the work.** If it's the next item of an agreed plan, execute via
  `/donext`. If the prompt specifies a concrete piece of work, do that. If
  there's no plan and no concrete task, stop and say so — don't invent scope.
- **Snapshot the git state.** Note the current branch and whether the working
  tree is clean (`git status --short`). You'll scope the critic's diff in
  step 2, and respect the project's branch conventions (implement on a feature
  branch, never straight on `main`, unless the project says otherwise).
- **Record your own model.** Read your model id from your system prompt (it
  says "You are powered by the model named …"). You need it in step 2 to avoid
  critiquing with the same model that did the work.

## Step 1 — Implement (worker)

If the work is a plan item, invoke the `/donext` skill and let it run to
completion (writes the item's tests first, confirms they fail for the right
reason, implements until they pass). Otherwise implement the specified work
directly, test-first.

Capture for the critic: **what was built** (its name/goal) and **what files it
touched**. You'll pass the intent so the critic can judge whether the code
actually does what was asked — a diff alone doesn't reveal intent.

If the work turns out to be a no-op, stop and tell the user — there's nothing
to critique.

## Step 2 — Select the critic model, then critique

### 2a. Self-select the critic model

The critic must run on a *stronger reasoning model* than the worker, if one is
available. Resolve the model id in this precedence order:

1. **Explicit override.** Check, in order:
   - environment variable `CRIT_MODEL` (e.g. `CRIT_MODEL=opencode/gpt-5.1-codex`);
   - a `critic`/`review` agent already defined in `opencode.json`,
     `~/.config/opencode/agents/`, or `.opencode/agents/` that pins a `model`
     (use that model id).
   An explicit override is the user's deliberate choice — honor it as-is, **no
   cost guard** (if they named a model, they own the bill). The cost guard
   below applies ONLY to the self-selection path.
2. **Self-select from the environment.** If no override exists, pick the
   strongest reasoning model that is ALSO **not ridiculously expensive** — a
   critique loop must not blow the budget on a flagship. Apply the cost guard
   BEFORE ranking:
   - List what's actually available: `opencode models` (openCode — include its
     pricing column if it shows one), your provider's model list, or the agent
     configs you can see.
   - **Rule out, in order:**
     a. the worker's own model id (from step 0) — the critique must come from a
        different model;
     b. every model in the **very-expensive deny-list** (models the user has
        flagged + known flagship tiers; prices change, so verify against the
        live model list rather than trusting memory):
        - **Fable** — the Claude Opus-class flagship, Anthropic's most
          expensive tier. Any Opus-class model is presumed expensive unless its
          listing says otherwise;
        - **GPT-5.x "sol" / premium-reasoning tiers** — e.g. `gpt-5.x-sol`,
          `openai/gpt-5*` variants with heavy reasoning effort that bill per
          reasoning token;
        - other very-high tiers you encounter (o-series "pro" tiers, any model
          whose price is clearly the most expensive available).
     c. if pricing IS visible, anything above a reasonable critique budget —
       roughly a blended cost over ~$10–20 per 1M tokens, or simply "the most
       expensive tier on offer". A critique touches thousands of tokens; the
       difference between a mid-tier and flagship price adds up fast for no
       better review.
   - Then prefer the first remaining entry in this order — reasoning-class
     models critique code better than non-reasoning ones, staying below the
     flagship tier:
     a. a strong-but-reasonable Claude model (e.g. a Sonnet-class
        `anthropic/claude-sonnet-4-*`, or an Opus-class model only if it is
        NOT the blocklisted flagship);
     b. a reasoning-tuned GPT/o-series model that is NOT a premium-reasoning
        tier (e.g. `opencode/gpt-5.x` standard, `openai/gpt-5-mini`,
        `gpt-5.1-codex` — unless it lands in the deny-list);
     c. any other reasoning-capable model that is available and reasonably
        priced (e.g. `deepseek-r1`, `kimi-k3-reasoning`, `x-ai/grok-3`).
   - If every candidate is blocked by the cost guard, use the strongest general
     subagent and say so plainly in the report.
3. **Spawn the critic on the chosen model.**
   - If your Agent/Task tool accepts a `model` parameter, pass the resolved id.
   - If you're in opencode and it doesn't, ensure a `critic` subagent exists
     that pins that model (define one in `opencode.json` — `"agent": { "critic":
     { "mode": "subagent", "model": "<id>", "prompt": "..." } }` — or
     `.opencode/agents/critic.md` — if none exists) and spawn it by that name
     via the Task tool's `subagent_type`. Creating the agent config is
     legitimate setup for the loop; don't change the agent's prompt beyond
     making it a read-only critic.
   - **Fallback:** if no stronger model is available in this environment, use
     the strongest general subagent and say so plainly in the report ("critic
     ran on the worker's model — no stronger reasoning model was available").

### 2b. Scope the diff

Keep the critic on *the change*, not the whole codebase:

- If the working tree has changes (`git status --short` non-empty), the worker
  left the work uncommitted — the critic reviews `git diff HEAD` **plus** every
  untracked (`??`) file read in full.
- If the working tree is clean, the work was committed — the critic reviews the
  branch's own commits: `git diff $(git merge-base HEAD <base>)...HEAD`,
  substituting the real base branch (usually `main`).

### 2c. The critic prompt

Give the critic a self-contained prompt — it starts cold with none of this
session's context:

```
You are an independent code critic running on a stronger reasoning model. A
worker just implemented this piece of work:

  <work name + one-paragraph goal, from step 1>

Review ONLY the changes it made — not the pre-existing codebase.
See exactly what changed by running:
  <the exact git command(s) from 2b>
For any untracked new files, read them in full.

Critique the diff broadly, most-severe first:
  - Correctness bugs: logic errors, wrong edge-case handling, broken
    contracts, anything that fails the stated goal.
  - Performance: needless O(n^2)/N+1 patterns, repeated work, avoidable
    allocations or round-trips in the CHANGED code.
  - Simplification / reuse: dead code, reinvented helpers, over-abstraction.
  - Style: deviations from the surrounding code's conventions (read a couple
    of neighboring files to learn them — match the codebase, not your taste).
  - Test coverage: paths the new tests miss; assertions that would pass even
    if the code were wrong.

For each finding return:
  - severity: Critical | High | Medium | Low
  - location: file:line
  - problem: ONE sentence — the concrete failure or smell, not a vague worry.
  - fix: ONE pithy sentence — the recommended change.
  - confidence: high | medium (flag anything you couldn't fully verify).

If a finding exists only because the work deliberately left an adjacent area
for a later, separately-planned item — not because of a mistake in the worker's
own change — say so in the finding ("belongs to a later plan item"). These are
NOT actionable here and the worker will record them as accepted notes.

Report only findings you can point to a specific line for. If the diff is
clean, say so — do not manufacture nitpicks to look thorough. Return a
severity-ordered markdown list; do not edit any files.
```

The critic is **read-only** — it reports, it does not touch the tree.

## Step 3 — Present findings, then AUTO-APPLY all (no gate)

Relay the critic's findings to the user as a prioritized, **numbered** list for
transparency (severity, `file:line`, the one-line problem, the pithy fix). Then
**immediately implement every actionable finding — do NOT stop to ask which to
apply.** This skill's contract is automatic application.

- Apply every finding the critic recommends, using its suggested fix (or a
  better one you now see), matching the surrounding code.
- A finding marked **"no action required" / "noting only" / "belongs to a later
  plan item"** is NOT actionable — record it as an accepted note and move on.
- If applying a fix changes behavior the work's tests assert, update those
  tests deliberately and say why — never silently loosen a test to make a fix
  pass.
- Keep a tally for the report: **N applied / M accepted-as-notes**.

## Step 4 — Verify (tests + critic re-check)

Two checks, because a fix can both break a test and be subtly wrong in a way
tests don't catch:

1. **Run the project's relevant tests.** Find the command in CLAUDE.md /
   README / the project's test config, and scope it to what changed rather
   than blindly running everything. Report pass/fail with the real output. If
   anything went red, fix it or surface it — don't report success over a
   failing suite. If the applied fixes have no test surface (docs-only or
   config-only cycle), say so plainly and let the re-check carry verification.
2. **Critic re-check.** Spawn a second, lighter review on the SAME self-selected
   model from step 2a, over the *newly applied* fixes (`git diff` since step 3).
   Ask it to confirm each applied fix actually resolves its finding and
   introduces no new problem. Keep it tight — a confirmation pass, not a fresh
   full review. The re-check is read-only.

## Step 5 — Report and stop

Give the user a short wrap-up:

- **Built:** the work, and that its tests pass.
- **Critic model:** which model ran the critique, why it was selected, and that
  it passed the cost guard (or that an override was honored / the fallback was
  used).
- **Critique:** findings applied vs. accepted-as-notes (list the notes).
- **Verify:** test result (pass/fail + counts) and the critic re-check verdict.

Then **stop**. This skill does one worker/critic cycle per invocation — it does
not advance to the next plan item on its own. If the user wants to continue,
they can invoke the loop again.

---

## Guardrails

- **One cycle per invocation.** Implement one piece of work, critique, fix,
  verify, stop. Never chain into the next plan item automatically.
- **Auto-apply is the contract.** Never stop mid-cycle to ask the user which
  findings to apply — that's the whole difference from build-critique-loop.
  (You still STOP at the end and hand back.)
- **Critic reviews the diff, not the repo.** Keep it scoped to what the worker
  changed — a whole-codebase review is a different, much slower task.
- **The critic and re-checker are read-only.** All edits happen in the worker
  session, never in a subagent.
- **Self-select honestly.** Pick the strongest reasoning model actually
  available; never claim a stronger model was used when the fallback ran. The
  worker's own model must not be the critic.
- **Respect the cost guard.** Never swap to a ridiculously expensive model
  (the flagship/deny-list tiers) on the self-select path just because it's the
  strongest — the loop must stay within a reasonable budget. Only an explicit
  `CRIT_MODEL`/agent-model override may bypass it.
- **Respect the project's git workflow.** If it mandates feature branches, the
  changes belong on one. Don't commit or push unless the user asks; if you do
  commit, follow the project's message conventions.
- **Don't fabricate findings.** A clean diff is a valid outcome. A short, real
  list beats a long, padded one.
