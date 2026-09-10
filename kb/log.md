# Knowledge base log

Newest entry first. Records additions and meaningful changes to concepts in
this bundle. Distinct from the repo-root `log.md`, which logs the SDLC
process itself.

## 2026-09-10

- Added `observations/snowflake-account-baseline.md` — live read-only probe of
  the Snowflake account: only `SOURCE_DB.RAW.TRANSACTIONS` exists (1,738 rows,
  8 columns), no setup-script objects at all, `trial` connection 404s while
  `sam_test` works.
- Added `observations/dbt-scaffold-drift.md` — the scaffold's unrunnable
  placeholders, stale tasty-bytes model selectors, and the contradiction
  between `__sources.yml` (`SOURCE`) and the real `SOURCE_DB`. Raised with the
  user; not resolved.
- Created `observations/` with its `index.md`; listed it in `kb/index.md`.
