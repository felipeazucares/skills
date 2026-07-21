# handoff

**Name:** handoff
**Description:** Update PROGRESS.md, summarise open issues, and save session context for the next session.

Save session context for the next session. Project progress lives in `PROGRESS.md` (specifications directory); session state lives in `.claude/` so it is shared with Claude Code.

## Update PROGRESS.md

Update PROGRESS.md in the specifications directory to reflect this session:

- Mark as complete **only** items that were actually finished **and** verified this session.
- Add any new tasks or sub-tasks that emerged during the work.
- Correct any entries that are now stale or inaccurate.
- Explicitly flag anything left in an in-progress or indeterminate state.

Do not mark anything complete that was not verified, and do not invent progress.

## Housekeeping

- Capture open issues: run `gh issue list --state open` so the summary below can include them.
- Set `.claude/mode` to `normal`.
- Delete `.claude/current-task.md`, `.claude/task-history.md`, `.claude/current-bug.md` if they exist.

## Write `.claude/context.md` (max 50 lines)

Use this structure:

```markdown
# Session Context

## Current Work
[What was being worked on — 3-5 lines]

## Recent Changes
[Files modified this session]

## Stable Features
[Working features to avoid re-implementing]

## Open Issues
[Open GitHub issues by number + title + priority]

## Build
[Essential build commands]

## Key Patterns
[Non-obvious patterns needed to continue — max 5 lines]

## Next Steps
[Ordered list]
```

Before writing: drop `/tmp/*` paths, dedupe entries, and don't reference files that no longer exist.

After writing, report: which PROGRESS.md items changed, which files were created or deleted, the open-issue count, and the resulting mode.