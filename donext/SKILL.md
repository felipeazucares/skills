---
name: donext
description: Executes the single next unstarted item from a plan that's already been agreed (e.g. the to-do list from the `nextup` skill, or the Next Steps section of a project's PROGRESS.md or `.claude/context.md`) — without re-deriving, re-scoping, or reworking the plan itself. Reads only the context that one item needs, confirms it doesn't violate the project's rules doc, implements it atomically, verifies it against its acceptance criteria, marks it done, then stops and reports rather than continuing to the next item. Trigger this when the user says "do next", "donext", "do the next thing", "continue with the plan", "implement the next step", or similar — especially right after a planning skill has already produced a to-do list and the user wants execution to proceed one item at a time without a fresh plan-and-confirm cycle for every step.
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

## 3. Implement

Implement that one item atomically: one file at a time, stating each
change and why as you go. Stay strictly inside the item's own scope
and whatever constraints step 1 surfaced — don't invent behavior the
plan and spec docs don't call for, even if it looks like an obvious
adjacent improvement.

## 4. Verify and record

Verify the item against its acceptance criteria — tests passing,
behavior confirmed directly, whatever "done" means for this project.
Hold predictions lightly: don't report something as working until
you've actually checked it, not just written code that looks right.

Once verified, mark that item done in the plan (`PROGRESS.md` and/or
`context.md`, matching wherever step 1 found it). Do not mark anything
done that wasn't actually verified.

## 5. Stop

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
- Complements `nextup` (produces the plan) and `implement` (fetches a
  fresh GitHub issue, plans it from scratch, and gates every build
  step individually). Use `donext` specifically when a plan already
  exists and the user wants low-ceremony execution of its next item —
  not a substitute for either when there is no existing plan, or when
  the user wants per-step confirmation gates during the build.
