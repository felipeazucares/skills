# handoff

**Name:** handoff
**Description:** Update PROGRESS.md, summarise open issues, and save session context for the next session.

Save session context for the next session. Project progress lives in `PROGRESS.md` (specifications directory); session state lives in `.claude/` so it is shared with Claude Code.

## Update PROGRESS.md

PROGRESS.md can grow to hundreds of KB of session history — do not read or
rewrite it wholesale. Locate its sections first (`grep -n '^## ' PROGRESS.md`),
then read only the ones you need via offset/limit, not the whole file. It
splits into two kinds of section (check its own preamble; if it declares a
different structure, follow that instead — and if the structure is genuinely
unclear, default to treating any dated, past-tense entry as frozen and only
append, never edit, since that's the safer failure mode):

- **Live/current-state sections** (often named "Status", "Open Items", "Next
  Phase", or similar) — read and edit these in place:
  - Mark as complete **only** items that were actually finished **and**
    verified this session.
  - Add any new tasks or sub-tasks that emerged during the work.
  - Correct any entries that are now stale or inaccurate.
  - Explicitly flag anything left in an in-progress or indeterminate state.
- **An append-only historical log** (often named "Log") — this is usually
  the largest section by far, and you don't need most of it: read only its
  first entry or two (via offset/limit, not the whole section) to match
  style and tone, then never edit or rewrite an existing entry, even a
  stale-looking one — entries are frozen once written. Record this session
  by adding **one new dated entry** in the same style as the entries already
  there, placed where new entries actually go — the top, if the log reads
  newest-first (the common case, and where a quick read already put you);
  the bottom, if it reads oldest-first. Match the existing order, don't
  assume. If the doc also keeps a rotated-out archive (e.g.
  `PROGRESS_ARCHIVE.md`, possibly moved there by a project script such as
  `specification/rotate_progress.py`) for entries past a certain age, leave
  it alone — that rotation isn't this skill's job.

Do not mark anything complete that was not verified, and do not invent
progress.

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