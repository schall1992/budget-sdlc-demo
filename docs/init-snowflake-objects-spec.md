# Spec: init-snowflake-objects

## What

Add the project's Snowflake warehouse and databases as Terraform resources
in `infra/`, apply them to the `sam_test` account, and update the dbt
config to target the new objects. This is the "future spec" the shipped
`init-snowflake-infra` deferred for warehouse and database creation.

## Why

The account holds only source data (`SOURCE_DB.RAW.TRANSACTIONS`) and a
service user. The dbt project has nowhere to materialize models, and CI
workflows fail because the warehouse and databases don't exist. Standing
these up unblocks all downstream modeling and deployment work.

## Object model

A medallion architecture with environment separation at the database level:

| Object | Type | Notes |
|---|---|---|
| `ANALYSIS_WH` | Warehouse | XSMALL, auto_suspend 60s, auto_resume true, initially suspended |
| `PRE_PROD_DB` | Database | CI/PR builds and local dev |
| `PRE_PROD_DB.BRONZE` | Schema | Raw/staging layer |
| `PRE_PROD_DB.SILVER` | Schema | Intermediate transformations |
| `PRE_PROD_DB.GOLD` | Schema | Mart/presentation layer |
| `PROD_DB` | Database | Production deployment on merge to `main` |
| `PROD_DB.BRONZE` | Schema | Raw/staging layer |
| `PROD_DB.SILVER` | Schema | Intermediate transformations |
| `PROD_DB.GOLD` | Schema | Mart/presentation layer |

This replaces the earlier single-database design (`budget_dbt_db` with
`dev`/`prod`/`integrations`/`raw` schemas) from `budget_setup.sql`. Source
data stays in `SOURCE_DB.RAW.TRANSACTIONS` — no `raw` schema is created in
either project database.

## Terraform resources

New file `infra/objects.tf` (keeping `service_user.tf` as-is for the
existing user resource). Resources:

- `snowflake_warehouse.analysis_wh`
- `snowflake_database.pre_prod`
- `snowflake_database.prod`
- `snowflake_schema.pre_prod_bronze`
- `snowflake_schema.pre_prod_silver`
- `snowflake_schema.pre_prod_gold`
- `snowflake_schema.prod_bronze`
- `snowflake_schema.prod_silver`
- `snowflake_schema.prod_gold`

All resources use only stable attributes in the `snowflakedb/snowflake`
provider ~2.20. No preview features.

### Apply

Unlike the previous infra spec (import-only, zero-diff), this spec
**creates new objects**. `terraform plan` will show 9 resources to add.
`terraform apply` runs locally against `sam_test` as part of the build
phase — the objects must actually exist for dbt config validation. The CI
pipeline (`infra_merged.yml`) will re-apply on merge, which should then
show zero diff since the objects already exist.

### Warehouse default user assignment

The service user's `DEFAULT_WAREHOUSE` should be set to `ANALYSIS_WH`
once it exists. Add this to the existing
`snowflake_service_user.github_actions` resource in `service_user.tf`
(currently unset in Terraform — the SQL setup scripts reference it but
Terraform doesn't manage it yet). This will show as an in-place update on
the next plan/apply.

## dbt config updates

### `dbt/profiles.yml`

Update both targets to reference the new databases:

- **dev** target: `database: PRE_PROD_DB`, `schema: bronze` (default
  landing schema for dev runs; the `generate_schema_name` macro already
  strips the prefix, so `+schema:` overrides in `dbt_project.yml` control
  where each model layer lands)
- **prod** target: `database: PROD_DB`, `schema: bronze` (same logic)
- Warehouse stays `analysis_wh` for both targets.
- `account`/`user` stay `'not needed'` (CLI handles auth).

### `dbt/dbt_project.yml`

Update the model config to map model directories to medallion schemas:

```yaml
models:
  budget:
    staging:
      +materialized: view
      +schema: bronze
    marts:
      +materialized: table
      +schema: gold
```

`silver` is not mapped yet — no intermediate models exist. When they're
added (a future feature), they'll get their own directory and `+schema:
silver` config. Creating the schema now is forward-looking, not waste.

## Contradictions reconciled

These files contradict the new object model and are updated as part of this
spec:

### `kb/observations/snowflake-account-baseline.md`

The "What does not exist" section lists `budget_dbt_db` and its schemas.
Update to reflect the new object model (`PRE_PROD_DB`/`PROD_DB` with
`bronze`/`silver`/`gold`), and note that once this spec ships, those objects
will exist.

### `kb/observations/dbt-scaffold-drift.md`

The `budget_dbt_db.raw` vs `SOURCE_DB` contradiction resolves: there is no
`raw` schema in the new model. `SOURCE_DB.RAW.TRANSACTIONS` remains the
sole source, referenced directly in `__sources.yml` (already fixed in the
previous spec). Update to mark this contradiction resolved and note the new
object model.

### `dbt/setup/budget_setup.sql`

Steps 1–2 (warehouse, database, schemas) are now fully superseded by
Terraform. Leave the file in place (it still holds the API integration and
observability setup for a future spec) but add a comment at the top noting
that Steps 1–2 are superseded by `infra/objects.tf`, and that running them
would create conflicting objects.

### `dbt/setup/ci_cd_setup.sql`

Step 1 references `budget_dbt_db`. Add a comment noting the database model
has changed to `PRE_PROD_DB`/`PROD_DB` and that database/schema creation is
now managed by Terraform.

## Explicitly out of scope

- **GitHub environment variables** (`SNOWFLAKE_DATABASE`/`SNOWFLAKE_SCHEMA`
  in the `prod` GitHub environment) — these need updating from
  `budget_dbt_db`/`prod` to `PROD_DB`/`bronze` (and the PR workflow
  similarly for `PRE_PROD_DB`), but that's a CI config change via `gh`, not
  an infra-as-code or dbt-config concern. Separate feature.
- **Observability settings** (`LOG_LEVEL`, `TRACE_LEVEL`, `METRIC_LEVEL` on
  schemas) — `budget_setup.sql` Step 3. Deferred.
- **GitHub API integration / git-workspace connection** —
  `budget_setup.sql` Step 4. Deferred (and the previous spec explicitly
  dropped it due to provider instability).
- **Network rules / external access integration** — `budget_setup.sql`
  Step 5. Deferred.
- **`dbt/schedules.sql`** — still references stale model names; no models
  exist to schedule yet.
- **`dbt/packages.yml`** — still fully commented out; needed for
  `dbt_semantic_view` later, not now.
- **Role separation** — both profiles run as `ACCOUNTADMIN`. Noted as
  tech debt in `dbt-scaffold-drift.md`; not addressed here.
- **Deleting `budget_setup.sql` / `ci_cd_setup.sql`** — they still hold
  future-spec content (API integration, observability, network rules).
  Superseded steps get a comment, not a deletion.

## Done when

- `terraform plan` against `sam_test` shows 9 new resources (1 warehouse,
  2 databases, 6 schemas) plus 1 in-place update (service user
  `default_warehouse`). No other changes.
- `terraform apply` succeeds, objects exist in the account.
- `dbt/profiles.yml` targets reference `PRE_PROD_DB`/`PROD_DB` with
  `bronze` as the default schema.
- `dbt/dbt_project.yml` maps `staging` → `+schema: bronze` and `marts` →
  `+schema: gold`.
- `kb/observations/snowflake-account-baseline.md` and
  `kb/observations/dbt-scaffold-drift.md` are updated to reflect the new
  object model.
- `budget_setup.sql` and `ci_cd_setup.sql` carry comments noting their
  DB/schema steps are superseded by Terraform.
