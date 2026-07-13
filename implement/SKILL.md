---
name: implement
description: Fetches a specific GitHub issue by number from the current repo, cross-references it against the repo's spec/design docs and CLAUDE.md conventions, and produces a costed (S/M/L) implementation plan for that one issue — then, only once the user explicitly approves, works through it step by step on a feature branch, pausing for confirmation before every individual step and again before the final commit. Trigger this whenever the user says "implement issue #N", "implement N", "let's build ticket N", "work on issue N", "pick up #N", or gives a bare issue number together with clear intent to build it (not just look it up). This is the execution counterpart to a planning-only skill — unlike a pure planner, this one DOES write code, run tests, create a branch, and commit, but never without the user's go-ahead at each gate, and never pushes or opens a PR without being asked separately.
---

# Implement

Take one GitHub issue from idea to committed, tested code on a feature
branch — but never skip a confirmation gate to get there faster. The
whole point of this skill is that the user sees the plan and each step
before it happens, so they can catch a wrong assumption while it's
still cheap to fix, not after three files have changed.

Two phases: **Plan** (read-only, ends in "does this look right?") and
**Build** (writes code, one step at a time, each step gated). Never
slide from Plan into Build without an explicit yes — a well-scoped
plan that looks obviously correct is not the same as permission.

## Phase 1: Plan

### 1. Retrieve the issue and surrounding state

Run the bundled script — it gathers everything below in one pass so
you're not re-deriving the same `find`/`gh` calls by hand:

```bash
bash <skill-dir>/scripts/fetch_issue_context.sh <issue-number> <repo-root>
```

It prints, in order: the full issue (title/body/labels/comments) as
JSON; current git branch and working-tree status; any existing branch
or PR (open, merged, or closed) already referencing this issue number;
the nearest `CLAUDE.md`; any spec/design doc that explicitly mentions
this issue number; and the full list of spec/roadmap docs in the repo
for topic-matching by title.

Handle what it turns up before going further:

- **`gh` missing/unauthenticated, or the issue number doesn't
  resolve** — say so plainly and stop; ask the user for the issue
  number/repo or to authenticate, rather than guessing at issue
  content.
- **Dirty working tree** — per standard git safety practice, don't
  branch off uncommitted changes silently. Show the user what's
  modified and ask whether to stash, commit first, or abort, before
  doing anything else.
- **A branch or PR already exists for this issue** — this is
  in-progress work, not a fresh start. Tell the user what you found
  (branch name, PR state) and ask whether to continue that work or
  start over, rather than creating a second competing branch.
- **The issue is already closed** — flag it and confirm the user still
  wants to (re)implement it before treating it as live work.
- **The issue reads as an epic** (a checklist of other issues, "Epic:"
  in the title, no concrete file-level scope of its own) — implementing
  an epic directly usually means implementing nothing concrete. Say so,
  and ask which child issue to run this skill on instead.
- **The issue body mentions a dependency** ("Depends on #N", "blocked
  on #N") — check that issue's state too (`gh issue view N --json
  state`). If it's still open, surface that as a real blocker before
  planning around it, don't quietly assume it's done.

### 2. Read the context that actually bears on this issue

Don't read every file the script lists at full length — use the issue
title/body to figure out which spec docs are relevant, then read
those, plus `CLAUDE.md`, in full. In repos that write issues well, the
issue body may already sketch a TDD plan, file scope, and even its own
size estimate — treat that as a strong draft, not gospel: verify it
against the actual spec doc(s) it references (specs get more detail;
issue bodies can drift out of sync with them), and adjust anything that
doesn't hold up before it reaches the user.

Look specifically for repo conventions that should shape *how* you
build, not just *what*:
- A test-first workflow (write test red → implement green) — if that's
  how this repo works, size and order the plan around that unit, don't
  flatten it into a single "implement X" step.
- The repo's git workflow and commit-message conventions (`CLAUDE.md`
  often documents branch-naming and commit style directly) — use them
  for the branch name and the eventual commit rather than inventing
  your own.
- Any project-specific guardrail the code must respect (e.g. a
  "don't build abstractions you don't need yet" doc, a "no comments
  unless X" rule, a required test file that must stay green) — carry
  these into the plan as constraints, not afterthoughts.

### 3. Build the costed plan

Break the issue into concrete steps — as many as it actually needs.
Sizing follows the same S/M/L convention used elsewhere in this
workflow:
- **S** — a single well-understood change, low risk of surprises.
- **M** — touches a few files or has a design decision to make, but the
  shape is known.
- **L** — meaningfully uncertain: touches many files, has an unresolved
  question, or depends on something not yet nailed down.

Also work out, but don't act on yet:
- The **branch name** you'll create (repo convention if one exists,
  otherwise something like `issue-<number>-<slug>`).
- The **commit message shape** you'll use at the end (repo convention
  if documented; otherwise a short imperative summary referencing the
  issue).

### 4. Present the plan — Gate 1

Reply in the chat with:

```markdown
## Issue
**#<number> — <title>** (<state>) — <url>
<one or two sentences of what it actually asks for>

## Findings
<anything from step 1 worth flagging: existing branch/PR, dirty tree,
epic warning, unresolved dependency — omit if none>

## Plan
| # | Step | Size |
|---|------|------|
| 1 | ...  | S    |
...

**Total:** <counts, e.g. "3 S, 2 M, 1 L">
**Branch:** `<proposed-branch-name>`

## Risks / open questions
- ...
```

Then explicitly ask whether to proceed — something like "Want me to
start on this, or adjust the plan first?" Do not treat silence,
a topic change, or your own confidence in the plan as a yes. Wait for
an actual go-ahead.

If the user pushes back on sizing, scope, or the branch name, revise
and re-present rather than defending the original — they're reviewing
this precisely because they might know something you don't (a
constraint, a preference, a reason this isn't as simple as it looks).

## Phase 2: Build (only after Gate 1 is cleared)

### 5. Set up the branch

Create (or switch to, if one already exists and the user chose to
continue it) the feature branch agreed in the plan. If the working
tree needed stashing/committing per step 1, resolve that first.

### 6. Walk the plan one step at a time — a gate before each

For every step in the approved plan, in order:

1. State which step you're about to do (by number and name) — don't
   silently reorder or merge steps because it seems more efficient;
   if you think two steps should merge, say so and ask.
2. Ask for confirmation to proceed with *that specific step*. This is
   the one requirement to hold onto even under time pressure: no step
   runs without its own go-ahead, not just the Gate 1 approval for the
   plan as a whole.
3. Once confirmed, do the work for that step — following whatever
   test-first convention step 2 identified (write the failing test,
   confirm it fails for the right reason, implement, confirm it
   passes), not just writing implementation code and calling it done.
4. Report what changed and the test result before moving to the next
   step's confirmation ask.

If something in a step reveals the plan was wrong (a file doesn't
exist where the spec said it would, a step turns out to need something
step 2's research missed), stop and say so — re-scope that step or the
remaining ones with the user rather than pushing through on a plan you
now know is off.

### 7. Finish up

Once every step is done and green, summarize what was implemented and
the final test results, then commit the work using the repo's standard
git commit process (status/diff/log review, a message that explains
*why*, staging only the relevant files) — and stop there. Do not push
and do not open a pull request; those are separate actions the user
asks for explicitly when they're ready, same as any other
hard-to-reverse or shared-visibility git action.

## Guardrails

- Two kinds of gate exist and neither substitutes for the other: the
  Gate 1 plan approval, and a per-step confirmation inside Build. Get
  both, every time.
- Never push, force-push, amend a previous commit, open a PR, or close
  the GitHub issue yourself — all separate, explicitly-requested
  actions.
- Never skip test hooks or use `--no-verify` to get past a failing
  check — if a hook fails, fix the underlying issue.
- If asked to plan several issues at once, run Phase 1 for each, but
  still gate Phase 2 per issue — approving issue A's plan is not
  approval for issue B's.
