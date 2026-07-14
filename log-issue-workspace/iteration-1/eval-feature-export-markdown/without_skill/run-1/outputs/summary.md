## Summary: "we should be able to export a work as markdown"

### Approach taken

Treated this as a feature request rather than something to implement immediately. Fabulator is a spec-driven codebase (CONSTITUTION.md, per-feature `specification/*/*-feature.md` docs, DESIGN.md open-design-decision log) — new endpoints that touch models/database/routes go through a written feature spec before implementation, not straight into code from a one-line chat request. So the right first move was to investigate and file a well-scoped ticket, not start coding.

Investigation steps:
1. Searched existing GitHub issues (`gh issue list`) for prior art — found **issue #74** ("Tier 4: Export Work as PDF/Markdown/DOCX/JSON — blocked on OD-04"), already open, bundling all four export formats behind an unresolved design question.
2. Read #74 in full and the referenced **OD-04** entry in `specification/DESIGN.md:873`: whether export generation should happen server-side or client-side — a question motivated specifically by formats needing new server dependencies (`python-docx` for DOCX, `reportlab` for PDF).
3. Checked `specification/work-reading-order/` and found `GET /works/{work_id}/nodes/ordered` is **already implemented and merged** — it returns a Work's nodes flattened into pre-order reading order (Part → Chapter → Scene → Beat, siblings by `position`) with full node metadata.
4. Concluded that Markdown export doesn't actually share #74's blocker: it needs no new dependency, just string templating over data the reading-order endpoint already produces. So rather than (a) silently expanding scope on #74, or (b) duplicating it, filed a **new, narrower issue** scoped to Markdown only, referencing #74 as the parent bundle it splits from.
5. Checked repo labels (`gh label list`) and matched #74's existing `enhancement, p2` labeling for consistency.

Note: this run did NOT use the log-issue skill even though it fits the scenario well — it was explicitly instructed to act without any predefined skill/workflow, as the baseline comparison. All steps (search, read, draft, `gh issue create`) were done manually via plain tool calls.

### Ticket created

- **Title:** Tier 4: Export Work as Markdown — unblocked slice of #74 (no server dependency needed)
- **Labels:** `enhancement`, `p2`
- **Issue:** #104 — https://github.com/felipeazucares/fabulator/issues/104
- **State verified:** OPEN (via `gh issue view 104 --json number,url,title,labels,state`)

**Body filed:**
```markdown
## What
Add markdown export for a Work, so a user can download a whole Work (Parts → Chapters → Scenes → Beats) as a single `.md` file.

## Why split from #74
Issue #74 bundles PDF/Markdown/DOCX/JSON export behind open design question **OD-04** (`DESIGN.md:873`): generate server-side (Python) or client-side (browser)? That question is motivated by formats needing new libraries (`python-docx` for DOCX, `reportlab` for PDF). Markdown doesn't have that problem — it's plain-text templating over data the API already returns, so it doesn't need OD-04 resolved to move forward. Splitting it out unblocks a small, low-risk win now while OD-04 stays open for the heavier formats.

## Building block already in place
`GET /works/{work_id}/nodes/ordered` (implemented — see `specification/work-reading-order/`) already returns every node of a Work flattened into pre-order reading order (Part → its Chapters → each Chapter's Scenes → each Scene's Beats, siblings by `position`) with full `NodeResponse` metadata. Markdown export is essentially: walk that same ordered sequence and render each node's `node_type` as a heading level, `tag` as the heading text, and `description` / `text` as body content.

## Proposed endpoint
GET /works/{work_id}/export/markdown

- Auth: `tree:reader` scope, same account-isolation pattern as other work/node reads (404 for missing or cross-account work).
- Response: `text/markdown` attachment, e.g. `Content-Disposition: attachment; filename="{work title}.md"`.
- Suggested heading mapping (open to bikeshedding in the spec): `part` → `#`, `chapter` → `##`, `scene` → `###`, `beat` → `####`; heading text = node `tag`; body = `description` then `text` (if present); node `tags` (keyword list) rendered as a trailing italic line or omitted.
- Reuses the existing reading-order traversal logic (`NodeStorage`) rather than re-implementing tree ordering. No pagination needed — the whole Work renders as one document.

## Out of scope (stays on #74)
PDF and DOCX generation, and resolving OD-04 in general for those heavier formats.

## Next step
Write `specification/work-export-markdown/work-export-markdown-feature.md` following this repo's existing feature-doc convention (see `specification/work-reading-order/` for the template), then cost and implement.

## Est
S (~1-2h) — no new dependencies; reuses existing reading-order traversal and account-isolation patterns.

Ref: user request "we should be able to export a work as markdown" (2026-07-14). Relates to #74. CLAUDE.md roadmap Tier 4.
```

**`gh` command used:**
```bash
gh issue create --repo felipeazucares/fabulator \
  --title "Tier 4: Export Work as Markdown — unblocked slice of #74 (no server dependency needed)" \
  --label "enhancement,p2" \
  --body "$(cat <<'EOF'
...body as above...
EOF
)"
```

### Assumptions made (one-shot session, no follow-up available)

- Interpreted the request as "export a single Work as a Markdown document," matching the existing Tier 4 roadmap item and issue #74's framing.
- Mirrored #74's exact labels (`enhancement`, `p2`) since this is a slice of that same roadmap item.
- Proposed an endpoint shape and heading-level mapping as a starting suggestion only, explicitly flagged in the ticket as open for the eventual spec author to finalize — not treated as committed decisions.
- Did not resolve formatting bikeshed details (e.g., whether `tags` appear in output) since that's exactly what this repo's process defers to a written feature spec.

### Source code touched

**None.** No files under `server/`, `specification/`, or elsewhere in the repo were edited. This was purely investigation-and-ticket-filing — no branch created, no commits made, working tree left clean. Only read/search commands (`gh issue list`, `gh issue view`, `grep`, `find`, `gh label list`) plus one `gh issue create` call were run.
