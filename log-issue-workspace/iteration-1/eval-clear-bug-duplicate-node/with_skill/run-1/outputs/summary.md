## Summary: log-issue run — deep-duplicate description bug

**Issue created:** #106 — https://github.com/felipeazucares/fabulator/issues/106

### Clarifying questions I'd have asked a real user (and the assumption made instead)

1. **Does this affect all node types (Chapter/Scene/Beat) or just one?** → Assumed all types; report said "the copies" generically.
2. **Does the root copy itself lose its description, or only descendants?** → Assumed both, since the code path branches differently for root vs. descendant (`_is_root_call` in `duplicate_deep`) and the report didn't distinguish.
3. **Is "empty" `null` or `""`?** → Treated both as the same symptom rather than over-specifying.
4. **Were originals' descriptions definitely non-empty before duplicating?** → Assumed yes (implied by report).
5. **Is shallow duplicate (`deep=false`) also affected?** → Assumed not, per reporter's explicit `?deep=true` wording, but added a shallow-path regression check to acceptance criteria anyway since both functions share the same copy pattern.
6. **Severity?** → Not given; assumed **p2** (real data loss on a shipped feature, not security-critical, not blocking core CRUD). Repo's `bug_report.yml` template requires a p1/p2/p3 value.

### Investigation (research only — no source files edited)

Read `server/app/database.py` (`NodeStorage.duplicate_shallow()` lines 1094–1140, `duplicate_deep()` lines 1142–1224, `get_node()` 656–666, `get_children()` 777–790), `server/app/api.py` (duplicate route handler, 1156–1201), and `server/app/models.py`. Notable finding, included in the ticket: on static read, `description` is copied identically to `tags` in both duplicate paths (`node.get("description")` alongside `node.get("tags")`), with no projection excluding it anywhere — couldn't spot an obvious smoking gun without live MongoDB. Flagged this so the implementer reproduces live rather than assumes it's visible in a diff. Also found a genuine test gap: `T-DUP-03`/`T-DUP-04` in `server/tests/test_integration_normalised.py` only check child count and UUID freshness, never field-level content — folded into acceptance criteria.

### Ticket details

- **Title:** `API: Deep duplicate loses description field on copied nodes`
- **Labels:** `bug`, `api` (created new — none existed; ran `gh label create api --color 1d76db --description "Server-side / FastAPI backend"`), `p2`
- **Body:** followed the repo's `bug_report.yml` template fields exactly (Summary / Steps to reproduce / Expected vs actual / Affected feature-file(s) / Severity / Acceptance criteria), plus an "Assumptions" section listing the six judgment calls above.

### Command run

```bash
gh issue create \
  --repo felipeazucares/fabulator \
  --title "API: Deep duplicate loses description field on copied nodes" \
  --body-file <scratchpad>/issue_body.md \
  --label bug --label api --label p2
```

### Duplicate check

`gh issue list --search "duplicate"` (open+closed) found #44 (deep-duplicate leaf guard) and #89 (frontend duplicate UI), both closed and related-but-distinct. No open duplicates — proceeded to file.

### Source code touched

**None.** Only reads for investigation, one scratchpad file used as `--body-file` input, and the new `api` label. No files under `server/` or elsewhere were edited, consistent with the skill's scope (file the ticket, never implement).
