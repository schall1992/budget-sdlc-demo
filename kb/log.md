# Knowledge base log

Newest entry first. Records additions and meaningful changes to concepts in
this bundle. Distinct from the repo-root `log.md`, which logs the SDLC
process itself.

## 2026-09-14 — CI service user key rotated; secrets placed

- Added `observations/github-environments-and-secrets.md`: the three GitHub
  environments, which credential sits in each, the `main`-only restriction on
  `prod`, and the rotation of `GITHUB_ACTIONS_SERVICE_USER`'s key pair.
  Written because GitHub cannot read a secret back, so nothing else records
  this.

## 2026-09-14

- Updated `observations/snowflake-account-baseline.md` — added why the
  Terraform provider can use neither `connections.toml` profile
  (`OAUTH_AUTHORIZATION_CODE` unsupported, `externalbrowser` rejected by
  the account, and the file's top-level key breaks the provider's TOML
  decoder) and the RSA key pair added to `SHALL` to work around it.
- Updated `observations/repo-and-cicd-baseline.md` — corrected the
  Terraform resource count (ten, not nine) and marked the whole Terraform
  section superseded by the HCP/parameterized-module refactor.
- Added `observations/hcp-terraform-backend.md` — HCP Terraform org
  `osusam28-main` and the three `local`-execution workspaces
  (`budget-shared`, `budget-pre-prod`, `budget-prod`) tagged `budget`,
  created as stage 1 of `budget-models-and-envs`. Records that the org
  default execution mode is `remote` and each workspace overrides it, and
  that workspace tags must be set through the tags relationship endpoint
  because `tag-names` on create is silently ignored.
- Updated `observations/repo-and-cicd-baseline.md` twice — first to record
  that the `incoming_pr.yml` dbt job has never succeeded (empty
  `SNOWFLAKE_ACCOUNT`), then to record that OIDC workload identity is not
  configured for the subject GitHub presents, contradicting a comment in
  `infra/service_user.tf`. Logged as a disagreement, not reconciled.

- Added `observations/repo-and-cicd-baseline.md` — the repo's own current
  shape (single Terraform root with committed state, `main`-only branching,
  the two workflows and their two different auth mechanisms, dbt-on-Snowflake
  execution path). Created because current state was previously described
  only inside live specs, which are archived to `docs/prod/` on ship.
- Updated `observations/index.md` to list it.

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
