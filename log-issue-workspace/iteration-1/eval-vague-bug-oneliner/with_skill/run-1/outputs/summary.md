# log-issue run summary — "login page is broken"

## Process followed (per SKILL.md at /Users/donfelipe/.claude/skills/log-issue/SKILL.md)

1. **Repo confirmed**: `felipeazucares/fabulator`, `gh auth status` OK.
2. **Classification**: Bug (not feature). Area: judged **unknown** — the repo has a real
   `frontend/` (React) and `server/` (FastAPI) side, and "login page is broken" could plausibly be
   a frontend rendering bug, a frontend-to-backend integration bug, or a backend `/get_token` bug.
   No `frontend`/`api` labels exist yet in the repo, so per the skill no label was invented and
   label creation was skipped (Step 6 explicitly allows this for "unknown").
3. **Convention check**: Found `.github/ISSUE_TEMPLATE/bug_report.yml` (fields: Summary, Steps to
   reproduce, Expected vs actual, Affected feature/file(s), Severity [p1/p2/p3 dropdown], Acceptance
   criteria) and used exactly those fields/order. Checked `gh label list` — confirmed `bug` plus
   `p1`/`p2`/`p3` severity labels exist and are the repo's real convention (verified against closed
   issues #99, #101, #33, etc., which all pair `bug` with a `p1`/`p2`/`p3` label).
4. **Duplicate check**: `gh issue list --search "login"` and `--search "login broken"` returned no
   matches; skimmed the full open issue list — no overlap found.
5. **Investigated repo for context** (read-only) to ground the ticket: `frontend/src/pages/LoginPage.jsx`,
   `frontend/src/api/auth.js`, and confirmed the `POST /get_token` route in `server/app/api.py`
   (~line 1205). Did **not** run the app or reproduce anything — there is no reproduction evidence
   behind this ticket, only informed guesses about where the failure could live, stated explicitly
   in the ticket rather than fabricating a root-cause narrative.

## Clarifying questions I would have asked a real user (and the assumption made instead)

This is a one-shot run with no further replies possible, so each question was substituted with an
explicit, labeled assumption baked into the issue body's "Assumptions / open questions" section, so
a human triager can immediately see what still needs confirming:

1. **What exactly happens when you try to log in?** (blank page, error message, hang, wrong
   redirect, button unresponsive, etc.) -> *Assumed*: some failure in the standard
   username/password submit flow through `LoginPage.jsx` -> `auth.js` `login()` -> `POST /get_token`.
2. **Does it fail with valid credentials, invalid credentials, or both?** -> *Assumed*: valid
   credentials (i.e., the core flow is broken, not just error-path UX).
3. **Which environment — local dev, staging, production?** -> *Assumed*: local dev
   (`npm run dev` + `uvicorn --reload`), the same setup used to reproduce the two most recent
   related bugs (#99, #101).
4. **Is this a new regression or has it never worked?** -> *Not assumed as fact*; flagged as
   unconfirmed and pointed at commit `cbba82f` ("Implement JWT-in-memory auth...") as a starting
   point for a `git log` bisect if a regression window is suspected.
5. **How severe / how many users affected?** -> *Assumed*: p1 (blocks all access to the app for
   everyone), matching the p1 bar the repo already uses for #99 and #101 (both post-login crashes).
   Flagged as assumption-based and revisit-if-scope-turns-out-narrower.

Deliberately did **not** invent a specific root cause or a "suggested fix" (unlike e.g. issue #99,
which had actual Playwright reproduction behind it) — the skill instructs recording symptoms and
requirements, not a prescribed solution, and there was no evidence to back a root-cause claim.

## Final drafted ticket

**Title:**
```
Login page broken — users cannot sign in (root cause not yet diagnosed)
```

**Labels:** `bug`, `p1`

**Body (full markdown, as posted):**

## Summary
Reporter says "the login page is broken." No further detail (exact failure mode, environment, or when it started) was provided at report time. This ticket captures the report as-is and lists the specific follow-up info an implementer needs before this can be diagnosed or fixed. See "Assumptions / open questions" below for everything that was inferred rather than confirmed.

## Steps to reproduce
1. Start the backend (`cd server && uvicorn app.api:app --reload`) and frontend (`cd frontend && npm run dev`).
2. Navigate to the login page (`/login`).
3. Enter credentials for an existing account and submit the form.

*(Assumption: this is the standard flow through `frontend/src/pages/LoginPage.jsx` -> `frontend/src/api/auth.js` `login()` -> `POST /get_token`. Not confirmed — the reporter did not say whether the failure happens on page load, on submit, with valid credentials, with invalid credentials, or something else entirely.)*

## Expected vs actual
- **Expected:** Submitting valid credentials authenticates the user, stores the JWT via `useAuthStore` (`frontend/src/store/authStore.js`), and navigates to `/works`. Submitting invalid credentials shows an inline error (`role="alert"` in `LoginPage.jsx`) without crashing.
- **Actual:** Unknown/unconfirmed. "Broken" was not further specified — could mean, among other possibilities: page fails to render, form fields don't accept input, submit button does nothing, a network/CORS error is thrown, the backend returns 401/422/500, the JWT decode fails, or post-login navigation fails (this repo has two recent precedents of post-login navigation crashes: #99 and #101, both `<page>.map is not a function` on paginated API responses — worth ruling out as a related pattern even though this report is specifically about the login page itself, not what it navigates to).

## Affected feature / file(s)
Likely candidates, not yet confirmed:
- `frontend/src/pages/LoginPage.jsx` — form/UI
- `frontend/src/api/auth.js` — `POST /get_token` call (note: deliberately bypasses the shared `apiFetch` 401 handler, see comment at top of file)
- `frontend/src/store/authStore.js` — token storage
- `server/app/api.py` (`/get_token` route, ~line 1205) — backend auth issuance, in case the failure is server-side rather than in the frontend

## Severity
p1 *(assumption — a broken login blocks all access to the app for every user, which matches the p1 bar used for #99 and #101 in this repo. Not confirmed with the reporter; if this only affects one account or one environment, it may actually be p2/p3.)*

## Acceptance criteria
- [ ] The reporter's actual failure mode is reproduced and documented (exact steps, browser/OS, environment, console/network errors or screenshot).
- [ ] Root cause identified and stated as frontend, backend, or integration (CORS/env config).
- [ ] A valid username/password successfully authenticates and lands the user on `/works`.
- [ ] An invalid username/password shows the existing inline error without crashing the page.
- [ ] A regression test is added covering the actual failure mode (e.g. `frontend/src/pages/LoginPage.test.jsx` or a `server/tests/` case, depending on where the root cause turns out to live).

## Assumptions / open questions
This report was a single line ("login page is broken") with no reply channel available to ask follow-ups before filing, so the following were assumed rather than confirmed. A human triager or the implementer picking this up should confirm these first:
1. **What exactly happens?** Assumed: some failure in the standard username/password submit flow. Not confirmed: blank page, error message, hang, wrong redirect, etc.
2. **Does it happen with valid credentials, invalid credentials, or both?** Assumed: valid credentials (i.e. the core flow is broken, not just error-path UX). Not confirmed.
3. **Which environment?** Assumed: local dev (`npm run dev` + `uvicorn --reload`), matching how #99/#101 were reproduced. Not confirmed — could be a staging/production-only issue (e.g. `CORS_ORIGINS` misconfiguration, `VITE_API_BASE_URL` pointed at the wrong host).
4. **Is this a regression (worked before) or has it never worked?** Not confirmed — no timeframe given. `frontend/src/pages/LoginPage.jsx` was last touched in `cbba82f` ("Implement JWT-in-memory auth: login, logout, protected routes"); worth checking `git log` around that commit and after if a specific regression window is suspected.
5. **Severity** — set to p1 by assumption (see above); should be revisited once the actual scope (all users vs. one account/environment) is known.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

## `gh issue create` command run

```bash
gh issue create \
  --title "Login page broken — users cannot sign in (root cause not yet diagnosed)" \
  --body-file "/private/tmp/claude-501/-Users-donfelipe-dev-fabulator/be8fb7a7-18e8-4b92-8a3f-9f3026c3eb40/scratchpad/issue-body.md" \
  --label bug --label p1
```

(Body was passed via `--body-file` pointing at a scratchpad file to avoid shell-quoting issues; the
file's contents are reproduced verbatim above.)

## Result

- **Issue number:** #105
- **URL:** https://github.com/felipeazucares/fabulator/issues/105

## Source code touched?

**No.** This run only read files for investigation (`LoginPage.jsx`, `auth.js`, grep for
`get_token` in `api.py`, `git log`) and wrote one scratchpad file (the issue body) plus this summary
file — no files under `frontend/` or `server/` were edited, and no branch/commit/PR was created,
consistent with the skill's scope of "draft and file, never implement."
