---
name: nextup
description: Figures out what to work on next in a software project by reading its specification/roadmap markdown docs, CLAUDE.md, and open GitHub issues/PRs, then produces a sized (S/M/L) To Do list for that item, test-first when the item involves code (writing/locating its tests is always the plan's leading step, before any implementation step). This is a PLANNING-ONLY skill — it never writes code, edits files, or opens branches/PRs/issues, including the tests it plans for. Use it whenever the user asks "what should I work on next", "what's next on the roadmap", "plan out the next ticket", "scope issue #N for me", "what's left before we can ship", or similar — especially in repos that track work across a mix of markdown docs (PROGRESS.md, ROADMAP.md, design docs) and GitHub issues, where the answer isn't obvious from either source alone. Also trigger when the user wants a task broken down and estimated before committing to implementation.
---

# Nextup

Answer two questions for the user, in order, using only read-only
research: **"what should I work on next?"** and **"what will it take?"**
Then stop. Do not implement, edit, commit, branch, or file anything —
the deliverable is the plan itself, presented in the chat.

This matters because premature implementation defeats the point of
asking for a plan first: the user wants to review scope and sizing
*before* anything changes, and possibly redirect you toward a
different item entirely. Treat any temptation to "just start on step
1" as a bug in your own behavior.

## 1. Gather context

Run the bundled discovery script first — it finds the same sources by
hand every time, so use it instead of re-deriving the search with ad
hoc `find`/`grep` calls:

```bash
bash <skill-dir>/scripts/discover_context.sh <repo-root>
```

It prints a manifest: the nearest `CLAUDE.md`, every markdown file
under common spec/doc directories (`specification/`, `docs/`, `spec/`,
`design/`) plus well-known root-level files (`PROGRESS.md`,
`ROADMAP.md`, `TODO.md`, `DESIGN.md`, `CONSTITUTION.md`,
`CODEBASE_ASSESSMENT.md`, `REQUIREMENTS.md`, `BACKLOG.md`), current git
branch/status/recent log, and — if `gh` is installed and authenticated
against a GitHub remote — open issues (with labels/milestone) and open
PRs as JSON.

The script only *discovers*; it does not dump full file contents (spec
docs can be long and you don't need all of them at full detail). After
it runs:

- **Read** the docs that look load-bearing for prioritization: files
  named like PROGRESS/ROADMAP/TODO first, then CLAUDE.md, then
  design/feature-spec docs relevant to whatever candidate item you're
  converging on. Don't read every file in a large `specification/`
  tree at full length — skim filenames and headers, then go deep only
  on what's relevant to the leading candidate(s).
- Treat the `gh issue list` / `gh pr list` JSON as authoritative for
  *current* open work — it reflects live state, whereas a markdown
  roadmap can go stale the moment someone merges a PR without updating
  it. When the two disagree (e.g. a doc says an item is done but its
  issue is still open, or vice versa), say so explicitly rather than
  silently picking one.
- If `gh` isn't installed, isn't authenticated, or the repo has no
  GitHub remote, the script will say so plainly — fall back to the
  markdown docs alone and tell the user you did, rather than treating
  the absence as an error.
- If nothing is found by either channel (no spec docs, no CLAUDE.md,
  no GitHub remote), tell the user directly instead of guessing at
  project structure — ask them where work is tracked.

## 2. Decide the next work item

Look for explicit signals before inventing your own priority order:

- Priority labels or markers (`p1`/`p2`/`p3`, "High Priority", "Tier
  1", milestone assignment).
- Explicit "what's next" pointers — a "Next Steps" section in a
  progress doc, an epic issue with a checklist, a milestone with one
  open item.
- Dependency ordering — an item explicitly blocked on another
  ("blocked on OD-04", "depends on #71") is not the next item; whatever
  unblocks it might be.
- Work already in flight — an open PR, a feature branch matching an
  issue number, or a partially-checked-off section in a progress doc
  is a strong signal to *finish that* before starting something new.
  Prefer continuing in-progress work over starting fresh work unless
  the user's request clearly asks to look further ahead.

Land on one recommended item. State it plainly, then justify it with
the specific signals you found (cite the doc section or issue number —
don't just assert). Name one or two runner-up candidates and why they
lost, so the user can redirect in one line if you read the priorities
wrong. If two sources conflict about what's next, surface the conflict
instead of quietly resolving it yourself.

## 3. Produce the costed To Do list

Break the chosen item into concrete steps — as many as the item
actually needs, no more. A one-file bug fix might be three steps; a
new feature spanning a design doc might be eight. Pad nothing:
inventing steps to look thorough is as much a failure as missing real
ones.

Size each step **S / M / L** (relative effort, not time):
- **S** — a single well-understood change, low risk of surprises.
- **M** — touches a few files or has a design decision to make, but
  the shape is known.
- **L** — meaningfully uncertain, touches many files, or depends on
  something not yet nailed down (an unresolved design question, an
  external dependency, unclear requirements).

Before sizing, check whether the item has a test spec: a dedicated
test-planning doc (e.g. a `*_tests.md` companion to the spec suite, or
a "Testing"/"Acceptance Criteria" section in its FEATURE.md or design
doc), or a documented test-first convention in CLAUDE.md or a
contributing/testing doc. If the item involves writing or changing
code, the plan's first step(s) MUST be building out that test spec —
writing the actual test case(s), from the existing test-planning doc
if one exists, or derived directly from the item's acceptance criteria
if it doesn't — with implementation steps ordered strictly after them,
never before. This is a requirement, not a preference: never propose
"implement X" as step 1 when the item involves code. The only
exception is an item with no meaningful test surface (a pure doc edit,
a config-only change) — say explicitly why testing doesn't apply
rather than silently omitting the step.

Beyond that ordering, prefer the repo's own conventions for step
*shape* when they're visible (e.g. "write test → confirm red →
implement → confirm green" as one combined unit of work, vs. separate
steps for each). Check CLAUDE.md and any contributing/testing docs for
how this repo likes it structured.

Call out risks separately from the steps: unresolved design questions,
things you're inferring rather than reading directly, anything that
could blow up an "S" into an "L" once someone actually starts.

## 4. Present the plan

Reply in the chat using this shape:

```markdown
## Current state
<2-4 sentences: branch/PR state, what's clearly done, what the sources
disagree on if anything>

## Recommended next item
**<item name / issue #>** — <one line on what it is>

Why: <the specific signals that pointed here>
Runner-up: <next candidate and why it lost>

## To Do list
| # | Step | Size |
|---|------|------|
| 1 | ...  | S    |
...

**Total:** <counts, e.g. "3 S, 2 M, 1 L">

## Risks / open questions
- ...
```

Do not create a file for this — it's a conversational deliverable. If
the user wants it persisted, that's their call to make explicitly; do
not do it preemptively.

## Guardrails

- Read-only research tools only: reading files, `git status`/`log`/
  `branch` (no mutating git commands), `gh issue list`/`view`, `gh pr
  list`/`view`. Never `Edit`/`Write`/`NotebookEdit`, never `git commit`/
  `checkout -b`/`push`, never `gh issue create`/`pr create`. This
  applies to the tests the plan calls for too — you plan that they get
  written first, you don't write them yourself.
- Any plan involving code changes must open with the test-writing
  step(s) for that code, sized before the implementation steps that
  make them pass — never the other way round.
- If the user's message asks you to plan *and* implement in the same
  breath, do the planning, present it, and then explicitly ask before
  touching any code — don't silently roll straight into
  implementation because a plan looks obviously right to you.
- If asked to plan for a specific named item (an issue number, a
  ticket name) rather than "what's next", skip step 2's prioritization
  and go straight to sizing that item — but still do step 1's context
  gathering so the sizing is grounded in the actual spec/design docs,
  not guessed from the title alone.
