# fixissue

**Name:** fixissue
**Description:** Fix a specified GitHub issue within constitution and feature scope, verify, then close on confirmation.

Fix GitHub issue `#$ARGUMENTS` end-to-end. If no number was supplied, run `gh issue list --state open` and ask which one.

## Step 1 — Context

1. `gh issue view $ARGUMENTS` — load the full issue, including comments.
2. `CONSTITUTION.md` — its controls and restrictions win over everything else. Confirm whether to create a fix branch in git; if so, create one of the form `fix/fix{number}-{brief-bug-description-in-kebab-case}`. All commits for the fix should happen on this branch.
3. The `FEATURE.md` for the feature this issue affects. Consult `DESIGN.md` / `REQUIREMENTS.md` only if the fix requires it.

## Step 2 — Plan and constitution check

- State the fix and a concrete, ordered, atomic plan **before** changing any code.
- Confirm it complies with `CONSTITUTION.md`.
- If the fix would violate a rule, or the issue is ambiguous or under-specified, **stop and ask** rather than guess.

## Step 3 — Execute

- Implement in atomic operations, editing **one file at a time**, stating each change and why.
- Stay strictly within the scope of the issue. Do not add behaviour that was not requested.

## Step 4 — Verify

- Verify against the issue's acceptance criteria (tests pass or behaviour confirmed). Hold predictions lightly; never claim success before verifying.

## Step 5 — Close (with confirmation only)

- Summarise what changed and the verification result. Propose a commit message that contains `fixes #$ARGUMENTS`.
- Do **not** close the issue and do **not** commit without explicit confirmation. Ask first; only on a yes do you commit (the merge will close the issue).

Think step-by-step throughout.