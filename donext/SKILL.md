---
name: donext
description: Executes the single next unstarted item from a plan that's already been agreed (e.g. the to-do list from the `nextup` skill, or the Next Steps section of a project's PROGRESS.md or `.claude/context.md`) — without re-deriving, re-scoping, or reworking the plan itself. Test-first: before writing any implementation, checks for that item's test spec (or writes the tests from its acceptance criteria if none exist) and confirms they fail for the right reason, then implements to make them pass. Reads only the context that one item needs, confirms it doesn't violate the project's rules doc, verifies the result against its acceptance criteria, marks it done, then stops and reports rather than continuing to the next item. Trigger this when the user says "do next", "donext", "do the next thing", "continue with the plan", "implement the next step", or similar — especially right after a planning skill has already produced a to-do list and the user wants execution to proceed one item at a time without a fresh plan-and-confirm cycle for every step.
---

# Do Next

Execute the single next unstarted item from a plan that's already been
agreed — a `nextup` to-do list, or the Next Steps section of
`PROGRESS.md`/`.claude/context.md` — and stop. This is deliberately
narrower than a full plan-and-build skill: it does not re-derive,
re-scope, or expand the plan, and it does not walk multiple items in
one pass. It exists for the case where planning already happened and
the user just wants the next box ticked, one at a time, without a
fresh planning cycle before every step.

If no plan exists yet — nothing in `context.md`'s Next Steps, no
PROGRESS.md pointer, no prior `nextup` output the user is referring
to — say so and suggest running `nextup` first rather than inventing a
plan to execute.

## 1. Find the current plan

Read, in order, whichever of these exist:
- `.claude/context.md` — Next Steps section, if this session or a
  prior one left one.
- `PROGRESS.md` (or the project's equivalent progress-tracking doc) —
  for the current task and which plan item is next outstanding.

Then read only what that one item needs to be implemented correctly:
the relevant feature/design doc (`FEATURE.md`, a `DESIGN.md` section,
etc.) and `CONSTITUTION.md` or equivalent rules doc — its constraints
override everything else. Pull in `DESIGN.md`/`REQUIREMENTS.md` only
if the item actually requires that context, not as a matter of course.

## 2. Identify the next item — don't re-plan

Take the single next outstanding item exactly as the existing plan
states it. Do not regenerate, reorder, or expand the plan — that's
`nextup`'s job, not this skill's. State plainly which item you're
about to do and where it came from (which doc/section).

Before touching anything, confirm the item doesn't conflict with the
project's rules doc (naming conventions, locked architecture, whatever
constitution-equivalent constraints apply). If the item is missing,
ambiguous, or would violate a rule, stop and ask rather than guessing
at what was meant or silently reinterpreting it.

## 3. Check for or build the test spec

Before writing any implementation code, check whether this item has
tests already defined: a test-planning doc referenced by its
feature/design doc (a `*_tests.md`-style companion, a "Testing" or
"Acceptance Criteria" section), or existing test files that already
cover it but haven't been run yet.

- If tests already exist for this item, confirm you understand them
  and run them first to see the current (expected-red) state before
  changing anything else.
- If no tests exist yet, write them now, before any implementation —
  derive concrete test cases from the item's acceptance criteria in
  the plan/spec, following the project's existing test conventions and
  file layout. Confirm the new tests fail for the right reason (red),
  not for an unrelated error like a missing import or typo — a test
  failing for the wrong reason isn't proof of anything yet.
- If the item genuinely has no test surface (a pure doc edit, a
  config-only change with no behavior to verify), say so explicitly
  and skip to implementation — don't invent a test for its own sake.

Do not proceed to step 4 until this is done: either the relevant
tests exist and are confirmed red, or you've stated plainly why none
apply.

## 4. Implement

Implement that one item atomically: one file at a time, stating each
change and why as you go, until the test(s) from step 3 pass (green).
Stay strictly inside the item's own scope and whatever constraints
step 1 surfaced — don't invent behavior the plan, spec docs, or tests
don't call for, even if it looks like an obvious adjacent improvement.

## 5. Verify and record

Verify the item against its acceptance criteria — tests passing,
behavior confirmed directly, whatever "done" means for this project.
Hold predictions lightly: don't report something as working until
you've actually checked it, not just written code that looks right.

Once verified, mark that item done in the plan (`PROGRESS.md` and/or
`context.md`, matching wherever step 1 found it). Do not mark anything
done that wasn't actually verified.

## 6. Stop

When that one item is done and verified, stop. Report what you
implemented, what you verified it against, and — for the user's
benefit, not as a prompt to continue automatically — what the next
item in the plan is. Do not start on it without being asked again.

## Guardrails

- This skill executes exactly one plan item per invocation. Multiple
  items in one pass is scope creep, even if the remaining items look
  small.
- Never rework, re-size, or re-prioritize the plan itself — if the
  plan looks wrong once you're looking closely at the item, say so and
  ask, rather than quietly fixing the plan and proceeding.
- Never write implementation code before its test(s) exist and are
  confirmed red (step 3). The only exception is an item with no test
  surface, and that must be stated explicitly, not assumed silently.
- Complements `nextup` (produces the plan) and `implement` (fetches a
  fresh GitHub issue, plans it from scratch, and gates every build
  step individually). Use `donext` specifically when a plan already
  exists and the user wants low-ceremony execution of its next item —
  not a substitute for either when there is no existing plan, or when
  the user wants per-step confirmation gates during the build.
