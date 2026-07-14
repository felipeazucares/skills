---
name: log-issue
description: Collects the information needed to file a well-scoped GitHub issue (bug or feature, tagged frontend/API/unknown) and creates it with the gh CLI — but never implements the fix or feature itself, only the ticket. Trigger this whenever the user wants to file a bug report, log a feature request, open a GitHub issue, "create a ticket", "file a ticket", "raise an issue", says something "needs a ticket" or "should be tracked for later", or describes a problem/idea they want captured rather than fixed in this session. Also trigger when the user reports a bug in passing ("hey this crashes when...") and it's unclear whether they want it fixed now or tracked — ask. Prefer this over jumping straight into a code fix whenever the user's actual intent is to record work for someone (possibly a future agentic session) to pick up later.
compatibility: Requires the gh CLI, installed and authenticated with issue-creation permission on the target repo.
---

# GitHub Ticket Filer

## Scope: draft and file, never implement

This skill produces exactly one thing: a GitHub issue, created via `gh issue create`. It does not
edit code, does not open a branch or PR, and does not start fixing the bug or building the
feature — even if the fix looks trivial once you understand it. The whole point is to hand a
self-contained ticket to *someone else* (often a fresh agentic session with zero context on this
conversation) to pick up later. If you start touching source files, you've left the scope of this
skill — stop and ask the user whether they actually want it implemented now instead.

## Step 1 — Establish the repo

If the current directory is a git repo with a GitHub remote, use it (`gh repo view` confirms).
Otherwise ask which repo. Confirm `gh auth status` is authenticated — if not, tell the user and
still offer to draft the ticket as a markdown block they can paste in manually; you just can't
create it for them.

## Step 2 — Classify: bug or feature, and area

Two axes: **bug vs. feature**, and **area — frontend / API / unknown**. If the user's message
already makes one or both obvious, don't re-ask — just state your read of it in a sentence so they
can correct you. "Unknown" is a legitimate, real answer, not a placeholder to avoid — use it when
the issue genuinely could sit in either layer, or the user doesn't know yet. Guessing an area you
aren't confident about produces worse routing than honestly saying unknown.

## Step 3 — Match the repo's own conventions

Before deciding what fields to ask for, check what this repo already uses:

- `ls .github/ISSUE_TEMPLATE/` and read any template whose name/title matches the category (bug
  report, enhancement, feature request, etc.)
- `gh label list`

Why bother: a ticket that looks like every other ticket in this tracker is easier for a human
triager or a future implementer to trust and act on than one in a skill-invented format. If a
matching template exists, ask for exactly the fields it defines, in its order — read the template,
don't reconstruct it from memory.

Some templates (e.g. an `enhancement.yml` with a "Related feature / area" text field) already have
a place to *write* the area as prose. That's still worth filling in, but it doesn't replace Step 6
below — a text field is something a human has to read to know the area, while a label is something
anyone can filter/query by. Do both whenever the template offers a text field; don't treat filling
the text field as "done" for area classification.

If no matching template exists, fall back to this default schema:

**Bug**
- Summary
- Steps to reproduce
- Expected vs. actual behavior
- Affected area / file(s), if known
- Severity (only ask if the repo already has p1/p2/p3-style priority labels — otherwise skip it,
  don't invent a priority scheme the repo doesn't use)
- Acceptance criteria — what does "fixed" look like, concretely

**Feature**
- Summary
- Motivation — why this matters, what it unblocks
- Affected area / file(s), if known
- Acceptance criteria — what does "done" look like, concretely
- Out of scope (optional) — anything adjacent that should explicitly *not* be bundled in

## Step 4 — Interview like the implementer has zero context

This is the actual job of the skill, so don't rush it. A fresh agentic session picking this ticket
up later has none of the context you and the user have right now — it can't ask a quick follow-up
mid-implementation the way you can ask one now. So:

- If the user's first description is a single line, don't accept it as-is. Ask 2-4 concrete
  follow-ups an implementer would actually need: what's expected vs. what happens, which
  files/components are likely involved, any edge cases, what's explicitly out of scope.
- If you can find the likely files yourself (grep/read the repo), do that and offer what you find
  rather than asking the user to already know exact paths — confirm your guess instead of
  outsourcing the research to them.
- If earlier turns in this conversation already established relevant context (a bug you both just
  diagnosed, a file you just read), reuse it — cite real file paths/line numbers instead of asking
  the user to restate what you already know.
- Push for specific, falsifiable acceptance criteria ("submitting the form with an empty title
  shows a 'Title is required' error and does not call the API") over vague ones ("should validate
  input better").
- Don't invent implementation detail the user never gave you. Record symptoms and requirements,
  not a prescribed solution — deciding *how* to fix it is the implementer's job, unless the user
  already has a specific approach in mind and states it.

## Step 5 — Check for duplicates

Search open issues for likely overlap before drafting further:

```
gh issue list --search "<2-4 keywords from the summary>" --state open
```

Show any close matches (number, title, URL) to the user. If one looks like a genuine duplicate,
ask whether to stop, or proceed anyway because this is related-but-distinct.

## Step 6 — Handle the area label

If the area is frontend or API, apply a real GitHub label for it — always, regardless of whether
the template you used in Step 3 already has its own text field for area. The two aren't
substitutes: a text field documents the reasoning for a human reading that one ticket, a label is
what makes every ticket this skill has ever filed filterable and consistent as a set. If the label
doesn't exist yet (`gh label list`), create it first:

```
gh label create api --color <hex not already used> --description "..."
```

Then apply it in Step 8 alongside the category label (`bug`/`enhancement`), the same way every time
— don't let "the template already covers this" be a reason to skip it.

Skip label creation for "unknown" — it's a note for the implementer, not something worth making
queryable.

## Step 7 — Draft, then confirm before creating

Assemble the full issue — title, body, labels — and show the complete draft to the user exactly as
it will be posted. Get explicit go-ahead before running `gh issue create`. Filing a GitHub issue is
visible to everyone with repo access and isn't cheaply undone (closing it still leaves a public
trail) — treat this the same way you'd treat a push or opening a PR, and confirm first.

Title convention: `<Area prefix if known>: <short imperative summary>`, e.g. `Frontend: Duplicate
button silently fails on root nodes`. Skip the prefix when area is unknown.

## Step 8 — Create it

```
gh issue create --title "..." --body "..." --label bug --label frontend
```

Report back the issue number and URL. If creation fails (permission scope issues are common — some
tokens can create issues but not PRs, or the reverse), don't just give up: show the user the fully
drafted title/body/labels as a markdown block they can paste into GitHub manually instead.
