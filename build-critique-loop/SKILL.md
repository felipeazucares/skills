---
name: build-critique-loop
description: >-
  A worker/critic agentic dev loop. First implements the next item from an
  existing plan with the /donext skill, then hands the resulting diff to a
  fresh Opus 4.8 sub-reviewer for a broad critique (correctness bugs,
  performance issues, simplification, style, and test-coverage gaps), presents
  a severity-prioritized findings list with a pithy one-line fix for each, and
  — only after the user picks which findings to apply — implements them and
  verifies with the project's tests plus a quick Opus re-check. Use this
  whenever the user wants the next plan item BUILT *and* CRITIQUED by a stronger
  model in one pass, not just implemented. Trigger on phrasings like
  "worker-critic loop", "build and critique", "do the next thing then review
  it", "implement the next item and have Opus check it", "critique loop",
  "donext then review", or any request to pair /donext execution with a
  follow-up expert review-and-fix cycle. Prefer this over a bare /donext
  whenever the user wants the work hardened and reviewed, not merely written.
---

# Build–Critique Loop

A worker/critic development cycle. The **worker** (this session) implements the
next planned item; a stronger **critic** (a fresh Opus 4.8 sub-reviewer) tears
the diff apart with fresh eyes; the user chooses which findings matter; the
worker applies them and verifies. One item per invocation — then stop and hand
back.

The value of the pattern is the *asymmetry and the fresh eyes*: the model that
just wrote the code is the worst judge of it (it's invested in its own
approach, and it can't see the assumptions it made). Delegating the critique to
a separate Opus 4.8 agent that sees only the diff — not the reasoning that
produced it — surfaces bugs and shortcuts the author is blind to, and keeps the
heavy review reasoning out of this session's context.

> **On "switch to Opus 4.8, then switch back":** a session can't retarget its
> own model mid-run. This loop realizes that intent with an Opus 4.8 *subagent*
> for the critique instead — which is strictly better than a literal toggle:
> genuine independent review rather than the author grading its own homework,
> and no context pollution. The worker session simply continues as itself; there
> is nothing to "switch back."

## The loop

1. **Implement** the next plan item with `/donext` (test-first, one item).
2. **Critique** the diff with an Opus 4.8 sub-reviewer (broad review).
3. **Present** a prioritized findings list — then **STOP** and let the user pick.
4. **Apply** only the findings the user selected.
5. **Verify** — run the project's relevant tests *and* a quick Opus re-check of
   the applied fixes.
6. **Report** and stop. Do not roll on to the next plan item.

Run these in order. Do not skip the stop-and-confirm gate at step 3, and do not
start step 4 on findings the user hasn't chosen.

---

## Step 0 — Preflight

- **Confirm a plan exists.** `/donext` executes the next item of an
  *already-agreed* plan (a `nextup` to-do list, a PROGRESS.md "Next Steps"
  section, `.claude/context.md`, etc.). If there's no such plan, stop and say
  so — offer `/nextup` to make one. Don't invent a plan here; that's not this
  skill's job.
- **Snapshot the git state.** Note the current branch and whether the working
  tree is clean (`git status --short`). You'll use this to scope the critic's
  diff in step 2, and to respect the project's branch conventions (implement on
  a feature branch, never straight on `main`, unless the project says otherwise).

## Step 1 — Implement (worker)

Invoke the `/donext` skill and let it run to completion. It writes the item's
tests first, confirms they fail for the right reason, implements until they
pass, verifies against the acceptance criteria, marks the item done, and stops.

Capture, for the critic: **what item was built** (its name/goal) and **what
files it touched**. You'll pass the intent to the critic so it can judge whether
the code actually does what the item asked — a diff alone doesn't reveal intent.

If `/donext` reports there's nothing to do, or the item was a pure no-op, stop
and tell the user — there's nothing to critique.

## Step 2 — Critique (Opus 4.8 sub-reviewer)

**Scope the diff first**, so the critic reviews *the change*, not the whole
codebase:

- If the working tree has changes (`git status --short` is non-empty), the
  worker left the item uncommitted — the critic reviews `git diff HEAD` for
  edits **plus** every untracked (`??`) file read in full.
- If the working tree is clean, `/donext` committed — the critic reviews the
  branch's own commits: `git diff $(git merge-base HEAD <base>)...HEAD`,
  substituting the real base branch (usually `main`).

**Spawn the critic** with the `Agent` tool: `subagent_type: "general-purpose"`,
`model: "opus"` (this is what pins it to Opus 4.8 regardless of the worker's
model — do **not** use `subagent_type: "fork"`, which ignores the model override
and runs on the worker's model). Give it a self-contained prompt — it starts
cold with none of this session's context:

```
You are an independent code critic. A worker just implemented this plan item:

  <item name + one-paragraph goal, from step 1>

Review ONLY the changes it made — not the pre-existing codebase.
See exactly what changed by running:
  <the exact git command(s) from the scoping rules above>
For any untracked new files, read them in full.

Critique the diff broadly, most-severe first:
  - Correctness bugs: logic errors, wrong edge-case handling, broken
    contracts, anything that fails the item's stated goal.
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

If a finding exists only because this item deliberately left an adjacent
area for a later, separately-planned item — not because of a mistake in the
worker's own change — say so in the finding ("belongs to a later plan item").
The user decides scope at the review gate, so surfacing whether a fix would
pull future work forward is exactly the signal they need.

Report only findings you can point to a specific line for. If the diff is
clean, say so — do not manufacture nitpicks to look thorough. Return a
severity-ordered markdown list; do not edit any files.
```

The critic is **read-only** — it reports, it does not touch the tree.

## Step 3 — Present findings, then STOP

Relay the critic's findings to the user as a prioritized, **numbered** list so
they can refer to items by number. Keep each to the critic's shape — severity,
`file:line`, the one-line problem, and the **pithy** recommended fix. Lead with
the highest severity. Example:

```
## Critique — <N> findings

1. **[Critical]** `api.py:212` — Character delete cascade runs after the
   document delete, so a mid-cascade failure orphans scene references.
   → Reorder: $pull from scenes before deleting the character doc.

2. **[Medium]** `CharactersView.jsx:88` — Appearance counts recompute on every
   render from the full nodes array.
   → Memoize the per-character count with useMemo keyed on the nodes query.

3. **[Low]** ...
```

If the critic found nothing worth acting on, say that plainly and note the loop
is complete — don't pad the list.

Then **stop and ask which findings to apply** (e.g. "which of these should I
fix — all, a subset, or none?"). Do **not** implement anything yet. This gate is
the point of the loop: the user, not the critic, decides what's worth changing.

## Step 4 — Apply selected fixes (worker)

Implement **only** the findings the user chose, in this session. For each, make
the change the finding recommended (or a better one if you now see it), matching
the surrounding code. If the user deferred some findings, note them so they're
not lost — offer to file them as tickets if the project tracks work that way.

If applying a fix means changing behavior the item's tests assert, update those
tests deliberately and say why — don't silently loosen a test to make a fix pass.

## Step 5 — Verify (tests + Opus re-check)

Two checks, because a fix can both break a test and be subtly wrong in a way
tests don't catch:

1. **Run the project's relevant tests.** Find the command in CLAUDE.md /
   README / the project's test config, and scope it to what changed (e.g. the
   frontend suite for `.jsx` changes, the backend suite for API changes) rather
   than blindly running everything. Report pass/fail with the real output. If
   anything went red, fix it or surface it — don't report success over a
   failing suite. If the applied fixes have no test surface (a docs-only or
   config-only cycle), say so plainly and let the Opus re-check carry
   verification on its own — don't run an unrelated suite just to have run
   something.
2. **Opus re-check.** Spawn a second, lighter Opus 4.8 sub-reviewer
   (`model: "opus"`) over the *newly applied* fixes (`git diff` since step 4).
   Ask it to confirm each applied fix actually resolves its finding and
   introduces no new problem. Keep it tight — this is a confirmation pass, not
   a fresh full review.

## Step 6 — Report and stop

Give the user a short wrap-up:

- **Built:** the plan item, and that its tests pass.
- **Critique:** findings applied vs. deferred (with the deferred ones listed).
- **Verify:** test result (pass/fail + counts) and the Opus re-check verdict.

Then **stop**. This skill does one worker/critic cycle per invocation — it does
not advance to the next plan item on its own. If the user wants to continue,
they can invoke the loop again.

---

## Guardrails

- **One cycle per invocation.** Implement one item, critique, fix, verify, stop.
  Never chain into the next plan item automatically.
- **The step-3 gate is mandatory.** Never apply fixes before the user has picked
  them. The critic advises; the user decides.
- **Critic reviews the diff, not the repo.** Keep it scoped to what the worker
  changed — a whole-codebase review is a different, much slower task.
- **The critic and re-checker are read-only.** All edits happen in the worker
  session, never in a subagent.
- **Respect the project's git workflow.** If it mandates feature branches (many
  do — check CLAUDE.md), the worker's changes belong on one. Don't commit or
  push unless the user asks; if you do commit, follow the project's message
  conventions.
- **Don't fabricate findings.** A clean diff is a valid outcome. A short,
  real list beats a long, padded one.
