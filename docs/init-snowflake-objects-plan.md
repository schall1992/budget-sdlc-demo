# Plan: init-snowflake-objects

Paired with `docs/init-snowflake-objects-spec.md`.

## High-level approach

1. Write the Terraform resources — a new `infra/objects.tf` defining the
   warehouse, two databases, and six schemas. Update `service_user.tf` to
   set `default_warehouse`. Validate locally with `terraform
   init`/`validate`/`plan` against `sam_test`, confirming 9 creates + 1
   in-place update.
2. Apply — `terraform apply` locally against `sam_test` to create the
   objects. Verify they exist in the account.
3. Update dbt config — `profiles.yml` targets point at the new
   databases/warehouse, `dbt_project.yml` maps staging→bronze, marts→gold.
4. Reconcile contradicting files — add superseded-by comments to
   `budget_setup.sql` and `ci_cd_setup.sql`; update the two KB observations
   to reflect the new object model.

## Breakdown

**T1 — Write `infra/objects.tf`**
Create the file with 9 resources: `snowflake_warehouse.analysis_wh`
(XSMALL, auto_suspend 60, auto_resume true, initially_suspended true),
`snowflake_database.pre_prod` / `.prod`, and
`snowflake_schema.{pre_prod,prod}_{bronze,silver,gold}` (each referencing
its parent database). Schemas depend on their database via the `database`
attribute — Terraform handles ordering automatically.
- Tests/evals: `terraform validate` passes.
- Dependencies: independent

**T2 — Update `service_user.tf`**
Add `default_warehouse = snowflake_warehouse.analysis_wh.name` to the
existing `snowflake_service_user.github_actions` resource.
- Tests/evals: `terraform validate` passes; `terraform plan` shows this as
  an in-place update (not a recreate).
- Dependencies: depends on: T1

**T3 — Terraform plan**
Run `terraform plan` against `sam_test`. Confirm the output shows exactly
9 resources to add and 1 to update in-place. No destroys, no other changes.
- Tests/evals: plan output matches expected count and types.
- Dependencies: depends on: T2

**T4 — Terraform apply**
Run `terraform apply` against `sam_test`. Verify the objects exist via SQL:
`SHOW WAREHOUSES LIKE 'ANALYSIS_WH'`, `SHOW DATABASES LIKE 'PRE_PROD_DB'`,
`SHOW DATABASES LIKE 'PROD_DB'`, `SHOW SCHEMAS IN DATABASE PRE_PROD_DB`,
`SHOW SCHEMAS IN DATABASE PROD_DB`.
- Tests/evals: apply succeeds with 9 added, 1 changed, 0 destroyed;
  all objects visible in the account; `terraform plan` after apply shows
  no changes.
- Dependencies: depends on: T3

**T5 — Update `dbt/profiles.yml`**
Set dev target to `database: PRE_PROD_DB`, `schema: bronze`,
`warehouse: analysis_wh`. Set prod target to `database: PROD_DB`,
`schema: bronze`, `warehouse: analysis_wh`.
- Tests/evals: file is valid YAML; database/schema/warehouse values match
  the spec.
- Dependencies: depends on: T4

**T6 — Update `dbt/dbt_project.yml`**
Change the models config: staging gets `+schema: bronze`, marts gets
`+schema: gold`.
- Tests/evals: file is valid YAML; staging maps to bronze, marts maps to
  gold.
- Dependencies: independent

**T7 — Add superseded comments to setup SQL files**
Add a comment block at the top of `dbt/setup/budget_setup.sql` noting
Steps 1–2 (warehouse, database, schemas) are superseded by
`infra/objects.tf` and running them would create conflicting objects. Add a
similar comment to `dbt/setup/ci_cd_setup.sql` Step 1 noting the database
model has changed to `PRE_PROD_DB`/`PROD_DB` and is Terraform-managed.
- Tests/evals: comments are accurate; no functional code changed.
- Dependencies: independent

**T8 — Update `kb/observations/snowflake-account-baseline.md`**
Rewrite the "What does not exist" section to list the new object model
(`ANALYSIS_WH`, `PRE_PROD_DB`/`PROD_DB` with bronze/silver/gold) and note
they now exist (post-apply). Update the "What exists" section if needed.
Update `kb/observations/index.md` and prepend to `kb/log.md`.
- Tests/evals: observation reflects the live account state after T4.
- Dependencies: depends on: T4

**T9 — Update `kb/observations/dbt-scaffold-drift.md`**
Mark the `budget_dbt_db.raw` vs `SOURCE_DB` contradiction as resolved: no
`raw` schema exists in the new model, `SOURCE_DB` is authoritative. Note
the new object model replaces the `budget_dbt_db` references. Update
`kb/observations/index.md` and prepend to `kb/log.md`.
- Tests/evals: the raw-schema contradiction is explicitly marked resolved;
  new object model is stated.
- Dependencies: independent

## Tasks that can run in parallel

T1 first; then T2→T3→T4 in sequence. After T4: T5 and T8 can proceed.
T6, T7, and T9 are independent and can run any time.
