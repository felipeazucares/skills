---
name: spec-review
description: Runs the spec-reviewer subagent to compare uncommitted changes against this repo's specs, CONSTITUTION.md, and CLAUDE.md conventions, producing a severity-ranked findings report. Read-only -- never edits or commits. Trigger this when the user says "review my changes", "code review this", "check this against spec", "does this comply with the constitution", "review before I commit", or similar -- especially as the final gate right before committing or opening a PR.
context: fork
agent: spec-reviewer
---

Review the current uncommitted changes (or, if none, the current branch's
committed-but-unmerged changes) against this repository's specs,
CONSTITUTION.md (or equivalent rules doc), and CLAUDE.md conventions.
Produce the structured findings report.
