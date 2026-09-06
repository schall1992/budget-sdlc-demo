# SDLC process log

Newest entry first. Records every interaction in the SDLC process (see
`CLAUDE.md` → Log), not just file changes.

## 2026-09-06 — Direct

- **Prompt:** Add `SOURCE.RAW.TRANSACTIONS` as the primary dbt source for the
  project; also asked to document a direct-change bypass of the SDLC for
  early repo setup.
- **Response:** Added a "Direct changes (bypassing the SDLC)" exception to
  `CLAUDE.md`, then declared `SOURCE.RAW.TRANSACTIONS` as source `raw.transactions`
  in `__sources.yml`, straight to `main` per the new exception.
- **Files touched:** `CLAUDE.md` (edited), `dbt/models/staging/__sources.yml`
  (edited).
