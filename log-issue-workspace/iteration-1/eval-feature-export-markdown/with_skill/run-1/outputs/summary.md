## Summary: log-issue run for "export a work as markdown"

**Duplicate check:** Found open issue **#74** — *"Tier 4: Export Work as PDF/Markdown/DOCX/JSON — blocked on OD-04"* (labels: `enhancement`, `p2`), which already lists Markdown as one of four target formats and is blocked on unresolved design question OD-04 (`specification/DESIGN.md:873`: server-side vs. client-side export generation). Confirmed this directly via `gh issue view 74` and by reading the OD-04 row in `DESIGN.md`.

**How it was handled:** Not a clean duplicate — #74 bundles four formats and is stalled on a blocker (new server dependencies for PDF/DOCX) that doesn't actually apply to Markdown, which needs no new library, just string formatting from data already in memory. Judged this "related but distinct" (the skill's explicit fallback when a match isn't clean) and filed a new, narrower, unblocked ticket, cross-linking it to #74 and suggesting #74 be narrowed to PDF/DOCX/JSON or closed once Markdown ships.

**Clarifying questions that would have been asked of a real user (assumptions made instead, recorded in the ticket's "Assumptions" section):**
1. New ticket vs. "just use #74"? → Assumed a narrower split-out ticket made sense given the cost/blocker asymmetry.
2. Endpoint shape: `/works/{id}/export/markdown` vs. `?format=markdown`? → Assumed path-based, single-format form.
3. Response shape: raw file download vs. JSON-wrapped string? → Assumed raw Markdown file download (`Content-Disposition: attachment`).
4. Heading-to-node-type mapping? → Assumed H1=Part … H4=Beat, per CLAUDE.md's documented 4-level hierarchy.
5. Include tags in output? → Assumed yes, as a small metadata line.

**NOTE — area classification gap:** The run did not explicitly state a frontend/API/unknown area classification in its final summary, and did not apply a frontend or api label (title prefix omitted too — used "Tier 4: Export a Work as Markdown" with no area prefix). It justified this by saying "no frontend/API labels exist or are used anywhere in this repo's issue history" — but that reasoning conflates "repo doesn't already use this labeling scheme" with "the skill's own area classification step," which the skill instructs to always perform regardless of prior repo convention. This looks like a real gap for iteration: Step 2 needs to force an explicit, stated area call (even if the honest answer is "unknown" because export is genuinely cross-cutting) rather than letting it be silently skipped when the repo has no precedent for the label.

**Final drafted issue (as posted):**

Title: `Tier 4: Export a Work as Markdown`
Labels: `enhancement`, `p2` (no frontend/api label applied — see gap noted above)

Body: Summary / Motivation / Related feature-area / Priority / Proposed endpoint (`GET /works/{work_id}/export/markdown`, with auth, traversal, heading-mapping, and response-format detail) / Acceptance criteria (6 falsifiable items) / Out of scope / Related issues (cross-link + rationale for splitting from #74) / Assumptions (the 5 items above, spelled out) — full text was written to a scratchpad file and passed via `--body-file`.

**Command run:**
```bash
gh issue create --repo felipeazucares/fabulator \
  --title "Tier 4: Export a Work as Markdown" \
  --label enhancement --label p2 \
  --body-file <scratchpad>/issue-body.md
```

**Result:** Issue **#107** created — https://github.com/felipeazucares/fabulator/issues/107

**Source code touched:** No. Only read operations (`grep`, `Read`, `gh` lookups) were performed against the repo; the only `Write` call targeted a scratchpad file, never anything under `/Users/donfelipe/dev/fabulator`. `git status --porcelain` shows pre-existing staged changes (`docker-compose.yml`, `frontend/.dockerignore`, `frontend/Dockerfile`, `frontend/vite.config.js`) that were already present before this session began — no `git add`, `Edit`, or `Write` was ever run against them by this run.
