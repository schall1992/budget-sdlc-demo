# Spec: init-snowflake-infra

## What

Write the Terraform code and GitHub Actions CI/CD lifecycle needed to
manage this dbt project's Snowflake infrastructure — the *ability* to
create and manage it going forward, not the act of creating it now. No new
Snowflake object gets created against the account as part of this spec.
The one Snowflake object that already exists — a manually-created service
user — is imported into Terraform state, not recreated. This spec
introduces no new Snowflake object at all: it's purely standing up the
Terraform/CI harness itself, proven against the one thing that already
exists.

## Why

The inherited scaffold (from Snowflake's tasty-bytes tutorials) manages
Snowflake objects via manually-run SQL scripts full of template
placeholders. Moving to Terraform makes the infra declarative, reviewable
in PRs, and reproducible — matching how the dbt side already goes through
PR review before deploying. This spec gets the tooling and pipeline in
place first, scoped to the smallest possible slice: import the one
existing object and prove the plan/apply pipeline works. Everything that
would actually add new infrastructure — warehouse, database, and the
Snowsight git-workspace connection — is a separate, future decision.

## Target account

`sam_test` CLI connection (account `epgqqsk-kn46620` / `ZV96105`, region
`AWS_US_EAST_2`, role `ACCOUNTADMIN`, auth `OAUTH_AUTHORIZATION_CODE` via
browser SSO). The `trial` connection is broken and out of scope.

## Source data

`SOURCE_DB.RAW.TRANSACTIONS` (already populated, external to this project)
is authoritative — not a project-owned copy. Terraform does not create or
manage `SOURCE_DB`; it's out of this project's control. Fix
`dbt/models/staging/__sources.yml` to reference it directly instead of the
nonexistent `SOURCE.RAW.TRANSACTIONS`. This is a repo-only config change,
not a live Snowflake change, so it's in scope here.

## Infra as Terraform (written, not applied)

New `infra/` folder at repo root, using the official `snowflakedb/snowflake`
Terraform provider. Terraform manages, as code, exactly one object:

- **`github_actions_service_user`** — **already exists** in the account,
  hand-created 2026-09-10 ahead of this spec (see
  `kb/observations/github-actions-service-user-bootstrap.md`). The
  Terraform resource must be written to match its live configuration
  exactly — `DEFAULT_ROLE = ACCOUNTADMIN`, both auth methods below — and
  brought into state via `terraform import`, never created fresh:
  - OIDC workload identity (`repo:schall1992/budget-sdlc-demo:environment:prod`),
    used by the existing dbt workflows (`incoming_pr.yml`, `pr_merged.yml`)
    via the Snowflake CLI
  - An RSA key pair, used by the new Terraform CI workflows (see below);
    the private key already exists as the `SNOWFLAKE_PRIVATE_KEY_RAW`
    secret in the `prod` GitHub environment — Terraform does not generate
    or rotate it as part of this spec

**Not in this spec's Terraform code at all:** warehouse `budget_dbt_wh`;
database `budget_dbt_db` and its schemas; network policy
`github_actions_policy`; and the Snowsight git-workspace connection
(API integration + secret + git repository object). The git-workspace
connection was investigated and dropped — see "Explicitly out of scope"
below. Warehouse and database are deferred to a future spec, definition
and apply together.

### One service user, two auth methods

A single Snowflake user isn't restricted to one auth method, so
`github_actions_service_user` carries both: OIDC (already in place, used by
the dbt Snowflake CLI steps) and an RSA key pair (already in place, for the
new Terraform provider — which doesn't yet support OIDC/workload-identity
auth, only the Snowflake CLI does). Both auth paths resolve to the same
user and the same `ACCOUNTADMIN` default role. The Terraform resource
models this existing reality; it doesn't create or change either auth
method.

### State

Local backend, `infra/terraform.tfstate` committed to git — no separate
state-storage service. Accepted tradeoffs, given this is a solo demo repo:
no state locking (two concurrent applies could race), and the state file
holds resource attributes in plaintext (secret *values* like any future
credentials still come from variables, not state, but the state file is
still sensitive and must never be assumed safe to expose beyond this
repo's existing access).

### No apply against the account, this spec

Because `github_actions_service_user` already exists, there's no
chicken-and-egg bootstrap problem to solve by hand — `terraform import`
reads the account and writes state, it does not create or modify anything.
With only the service user in scope, `terraform plan` after that import
should show **no changes at all** (a clean, empty diff) — there is nothing
left in this spec's code to propose creating. That's expected and is the
proof the pipeline works end to end, even with nothing new to build yet.

## CI/CD lifecycle (written, not exercised end-to-end)

Two new workflows, mirroring the existing dbt PR/merge pattern:

- **`infra_pr.yml`** — on a PR touching `infra/**`: `terraform init` +
  `terraform plan`, authenticated as `github_actions_service_user` via its
  existing key-pair secret. Surfaces the plan for review; does not apply.
  Proving this works (opening a PR that touches `infra/` and seeing a real
  plan posted — showing zero changes, since the only resource in scope is
  already imported) is in scope and doesn't create anything.
- **`infra_merged.yml`** — on merge to `main` touching `infra/**`:
  `terraform apply -auto-approve`, then commits the updated
  `infra/terraform.tfstate` back to `main`. This workflow is written and
  wired up, but **no PR touching `infra/` is merged to `main` as part of
  this spec** — merging would run a real (if empty) apply, and exercising
  that end-to-end is left for when there's an actual change to apply.

`pr_merged.yml` (the existing dbt deploy workflow) gets a `needs:`
dependency on the new infra-apply job so that, when a single PR changes
both `infra/` and `dbt/`, the infra apply completes before the dbt project
object deploys against it. `incoming_pr.yml` is unchanged — it only reads
already-applied infra, it doesn't need to wait on anything new.

## GitHub repo configuration (via `gh` CLI)

The `SNOWFLAKE_ACCOUNT` secret and `SNOWFLAKE_DATABASE`/`SNOWFLAKE_SCHEMA`
variables the dbt workflows reference, and the key-pair private-key secret
for `github_actions_service_user`, already exist in the `prod` environment
(set 2026-09-10 alongside the manual service-user creation). No new
secrets/variables are needed for this spec.

## Explicitly out of scope

- The warehouse `budget_dbt_wh` and database `budget_dbt_db` (with its
  schemas) — no Terraform code for either, and no apply. Both come
  together in a future spec.
- The network policy `github_actions_policy` — not planned as part of
  this spec at all; it isn't required for anything currently working.
- **The Snowsight git-workspace connection** (GitHub API integration +
  secret + git repository object) — investigated and dropped. The
  git-flavored API integration resource
  (`snowflake_api_integration_git_repository_token` or its OAuth2/GitHub
  App/private-link siblings) is a **preview** resource in the
  `snowflakedb/snowflake` Terraform provider, explicitly documented as
  unstable with breaking changes expected outside major version bumps.
  Committing this feature to Terraform now would mean absorbing that churn
  for a nice-to-have. If wanted later, do it by hand with a few SQL
  statements outside Terraform, or revisit once the provider resource
  stabilizes.
- Deleting `dbt/setup/budget_setup.sql` / `dbt/setup/ci_cd_setup.sql` —
  they still reference the warehouse/database this spec doesn't touch, so
  they stay until that future spec replaces them wholesale.
- `dbt/schedules.sql`'s stale tasty-bytes model names — no staging/mart
  models exist yet, nothing correct to schedule.
- Fixing the `trial` connection.
- Building staging/mart models — `dbt/models/staging/` and
  `dbt/models/marts/` stay empty.
- `dbt/packages.yml` staying fully commented out (needed later for
  `dbt_semantic_view`, not this feature).
- Moving Terraform state off local/git-committed to a locking remote
  backend (S3, Terraform Cloud) — explicitly declined for this feature; a
  future revisit if this stops being a solo demo repo.

## Done when

- `infra/` Terraform code exists for `github_actions_service_user` only.
  `terraform validate` passes, and `terraform plan` runs cleanly against
  `sam_test` showing `github_actions_service_user` reconciled via
  `terraform import` with **zero diff** — nothing proposed to create,
  change, or destroy.
- `dbt/models/staging/__sources.yml` resolves to the real
  `SOURCE_DB.RAW.TRANSACTIONS` table.
- `infra_pr.yml` and `infra_merged.yml` exist and are wired into the repo;
  a PR that changes `infra/` triggers `infra_pr.yml` and shows a real
  (empty) plan. That PR is **not** merged as part of this spec.
- A PR against `main` still successfully triggers `incoming_pr.yml`, and
  merging still triggers `pr_merged.yml` (dbt project object deploys and
  builds, even with zero staging models) — unaffected by any of the above.
- The Snowflake account holds nothing new at all: no `budget_dbt_wh`, no
  `budget_dbt_db`, no API integration, no network policy, no git
  repository object. Only `github_actions_service_user`, which already
  existed before this spec.
