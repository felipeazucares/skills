# startup

**Name:** startup
**Description:** Load prior session context and specification docs, summarise current state and next tasks.

#startup

Load prior session context and project specifications to resume work. Session state lives in `.claude/`; project progress lives in `PROGRESS.md` (specifications directory).

## Step 1 — Load context

1. Read `.claude/context.md` if it exists (session context from the last handoff).
2. Read `.claude/mode` if it exists.
3. Read `PROGRESS.md` in the specifications directory.
4. Read `CONSTITUTION.md` if it exists.

## Step 2 — Load open issues

Run `gh issue list --state open` to get current open issues.

## Step 3 — Summarise

Report back:

- **Current work:** what was being worked on last session.
- **Stable features:** working features not to re-implement.
- **Open issues:** by number + title + priority.
- **Next steps:** ordered list from context, cross-checked against PROGRESS.md.
- **Mode:** current value of `.claude/mode`.

Flag anything in `.claude/context.md` that appears stale (references files, issues, or tasks that no longer exist) rather than silently carrying it