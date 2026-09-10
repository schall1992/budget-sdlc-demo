# Knowledge base log

Newest entry first. Records additions and meaningful changes to concepts in
this bundle. Distinct from the repo-root `log.md`, which logs the SDLC
process itself.

## 2026-09-10 (3)

- Updated `observations/snowflake-account-baseline.md` — project objects now
  exist after `init-snowflake-objects` terraform apply: ANALYSIS_WH,
  PRE_PROD_DB (bronze/silver/gold), PROD_DB (bronze/silver/gold), service
  user default_warehouse set to ANALYSIS_WH. Rewrote "What exists" and
  "What does not exist" sections to reflect the live account state.
- Updated `observations/dbt-scaffold-drift.md` — marked the
  `budget_dbt_db.raw` vs `SOURCE_DB` contradiction as resolved: no raw
  schema in the new medallion model, SOURCE_DB is the sole source.
- Updated `observations/index.md` to reflect both changes.

## 2026-09-10 (2)

- Added `observations/github-actions-service-user-bootstrap.md` — user
  requested `github_actions_service_user` be hand-created via Cortex right
  now, ahead of `infra/` Terraform code, despite the spec's bootstrap flow
  being designed to avoid exactly that. Created with `DEFAULT_ROLE =
  ACCOUNTADMIN`, OIDC workload identity, and an RSA key pair. Terraform will
  need to `import` it later. Edited `observations/snowflake-account-baseline.md`
  to remove the now-stale "does not exist" line for this user and link to
  the new observation. Later same day: installed and authenticated `gh`,
  created the previously-nonexistent `prod` GitHub environment, and stored
  the private key there as `SNOWFLAKE_PRIVATE_KEY_RAW`; updated the
  observation to record where the key lives.

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
