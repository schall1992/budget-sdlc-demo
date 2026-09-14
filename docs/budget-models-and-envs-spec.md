---
status: draft
class: elevated
---

# Spec: budget-models-and-envs

## Intent

Stand up a real environment and promotion flow for the budget dbt project:
a developer sandbox, a per-PR CI build, a shared pre-production build, and a
production build — each running as its own least-privilege Snowflake role and
identity, promoted through a `dev` → `main` branching model. Prove it end to
end with a single staging model on the raw transaction data.

Today every dbt path runs as `ACCOUNTADMIN` through one shared service user,
there is one undifferentiated branch, one Terraform root module hand-copies
the same shape of resources per environment, Terraform state is committed to
the repo, and no models exist. That is a security problem, a maintenance
problem, and a poor thing to demonstrate in a repo about SDLC practice. This
work fixes it.

## Current state

- `PRE_PROD_DB` and `PROD_DB` exist, each with `BRONZE`, `SILVER`, `GOLD`
  schemas, alongside `ANALYSIS_WH`. All Terraform-managed from a **single
  root module** at `infra/` with one **committed** state file
  (`infra/terraform.tfstate`), which CI writes back to the branch after
  every apply.
- `SOURCE_DB.RAW.TRANSACTIONS` holds 1,738 rows, all `VARCHAR` except
  `DATE`: `ACCOUNT`, `DATE`, `PAYEE`, `CATEGORY_GROUP`, `CATEGORY`, `MEMO`,
  `OUTFLOW`, `INFLOW`. Not Terraform-managed.
- `GITHUB_ACTIONS_SERVICE_USER` (`ACCOUNTADMIN`) runs both the Terraform jobs
  (RSA key pair, `SNOWFLAKE_JWT`) and the dbt jobs (OIDC).
- `models/staging/` and `models/marts/` are empty.
- dbt runs via **dbt Projects on Snowflake** (`snow dbt deploy` /
  `snow dbt execute`), not dbt Core in a runner.
- Only `main` exists. Workflows are `incoming_pr.yml` (PR to `main`) and
  `pr_merged.yml` (push to `main`).

## Design

### Branching and promotion

`main` is the production branch. A new long-lived `dev` branch is the
pre-production preview. **Every feature branch is cut from `main`**, never
from `dev`, and takes two PRs.

```
main (prod)
  └─► feature/x               cut from main
        ├─► PR → dev          terraform plan (all three workspaces)
        │                     dbt build → per-PR PRE_PROD schemas
        │   merge to dev      terraform apply (pre_prod workspace)
        │                     dbt build → PRE_PROD_DB.BRONZE/SILVER/GOLD
        └─► PR → main         no workflows; review approval required
            merge to main     terraform apply (shared workspace, then prod)
                              dbt build → PROD_DB.BRONZE/SILVER/GOLD
```

`dev` never merges into `main`, so it accumulates drift. It is reset to
`main` **manually**, by the user, when it gets noisy. No automation.

**Known limitation, accepted:** what is validated on `dev` is the feature
integrated with everything else already merged there, while what ships to
`main` is the feature alone. A green `dev` build is therefore not proof that
the `main` merge is green. This is inherent to the branching shape, not a
defect in the implementation.

### Roles and identities

Four new Snowflake objects:

| Object | Purpose |
|---|---|
| `PRE_PROD_DBT_ROLE` | Owns and writes everything in `PRE_PROD_DB` |
| `PROD_DBT_ROLE` | Owns and writes everything in `PROD_DB` |
| `PRE_PROD_DBT_USER` | Service user, RSA key pair, default role `PRE_PROD_DBT_ROLE` |
| `PROD_DBT_USER` | Service user, RSA key pair, default role `PROD_DBT_ROLE` |

Each user is granted only its own role. A leaked pre_prod credential cannot
reach `PROD_DB`. Both roles are granted to `SYSADMIN` so `ACCOUNTADMIN`
retains effective control of objects it no longer owns and Terraform can keep
managing the schemas.

[dbt Projects on Snowflake uses a two-role model](https://docs.snowflake.com/en/user-guide/data-engineering/dbt-projects-on-snowflake-access-control):
the *calling* role on `EXECUTE DBT PROJECT` and the *profile* role from
`profiles.yml`. Both resolve to the same role per environment — the calling
role from the connection user's default, the profile role from the target
block.

`GITHUB_ACTIONS_SERVICE_USER` is untouched and continues to run every
Terraform job as `ACCOUNTADMIN`. **Accepted risk:** because pre_prod infra
applies on merge to `dev`, anyone who can merge to `dev` can change anything
in the account. The demo shows least privilege for dbt, not for Terraform.

### State: HCP Terraform

State moves out of the repo entirely, into **HCP Terraform** (free tier),
with one workspace per environment:

| Workspace | Holds |
|---|---|
| `budget-shared` | `ANALYSIS_WH`, `GITHUB_ACTIONS_SERVICE_USER` |
| `budget-pre-prod` | Everything in `PRE_PROD_DB` and its role/user |
| `budget-prod` | Everything in `PROD_DB` and its role/user |

Execution mode is **local** — HCP Terraform stores state and provides
locking, but plans and applies run in GitHub Actions, where the Snowflake
credentials already live. Authentication is a single `TF_API_TOKEN` secret
in the `infra` GitHub environment, supplied to
`hashicorp/setup-terraform` via `cli_config_credentials_token`.

This replaces committed state, and with it three problems the previous
design had to accept:

- **Branch divergence.** Committed state is per-branch: `pre_prod.tfstate`
  would only ever be written on `dev` and `shared`/`prod` only on `main`. A
  feature branch cut from `main` would carry stale pre_prod state, so the
  PR-to-`dev` plan — the flow's only gate — would show diffs for resources
  that already exist. Remote state is branch-independent, so every plan
  reads the same truth.
- **The commit-state-back step.** No workflow writes to the repo any more.
- **The force-push footgun.** Resetting `dev` can no longer roll state back,
  because state no longer travels with the branch.

Terraform still runs `-auto-approve` on merge; the gate is the PR plan, not
the backend.

### Infrastructure layout

`infra/` stays a **single Terraform module** — no per-environment
directories. What varies between `shared`, `pre_prod`, and `prod` is
expressed as **variables**, supplied by one `.tfvars` file per environment.
The same resource definitions (database, schemas, role, user, grants) are
written once and instantiated per apply via `count`, driven by boolean
variables — nothing about a resource's shape is copy-pasted between
environments.

| Env-var file | Workspace | Applied on | Enables |
|---|---|---|---|
| `infra/envs/shared.tfvars` | `budget-shared` | merge to `main` | `create_shared = true` → `ANALYSIS_WH`, `GITHUB_ACTIONS_SERVICE_USER` |
| `infra/envs/pre_prod.tfvars` | `budget-pre-prod` | merge to `dev` | `create_env = true`, `env_name = "pre_prod"`, `grant_create_schema = true` |
| `infra/envs/prod.tfvars` | `budget-prod` | merge to `main` | `create_env = true`, `env_name = "prod"`, `grant_create_schema = false` |

Workspace selection is by `TF_WORKSPACE` environment variable per job, with
a single `cloud` block in the module naming the org and a workspace *tag*
rather than a fixed name. Each job therefore runs
`terraform init` then `terraform plan -var-file=envs/<env>.tfvars` with
`TF_WORKSPACE` set — no `-state` flag anywhere.

Each environment's apply owns *all* grants to its own role — including
`USAGE` on `ANALYSIS_WH` and read on `SOURCE_DB` — referencing those objects
by variable/literal name (e.g. `var.warehouse_name`) rather than by
cross-workspace remote-state lookup. This keeps the `shared` workspace free
of anything that depends on a role defined elsewhere, and avoids coupling
the workspaces together.

`budget-shared` must apply before either environment workspace. It already
has, in the sense that `ANALYSIS_WH` and the CI service user exist today.

**State migration.** All nine current resources live in the committed
`infra/terraform.tfstate`. They move to HCP Terraform by pushing that state
into the `budget-shared` workspace (`terraform state push`), then moving the
environment-specific resources out into their own workspaces with
`terraform state mv`. Nothing is destroyed or recreated. Once all three
workspaces are correct and each reports a clean plan,
`infra/terraform.tfstate` and `infra/terraform.tfstate.backup` are deleted
from the repo and `.gitignore` is updated to exclude `*.tfstate*`.

### Grants

`PRE_PROD_DBT_ROLE` (`grant_create_schema = true`):
- `USAGE` on `ANALYSIS_WH`
- `USAGE` + `CREATE SCHEMA` on `PRE_PROD_DB`
- `OWNERSHIP` on `PRE_PROD_DB.BRONZE`, `.SILVER`, `.GOLD`
- `USAGE` on `SOURCE_DB` and `SOURCE_DB.RAW`; `SELECT` on
  `SOURCE_DB.RAW.TRANSACTIONS` and future tables in that schema

`PROD_DBT_ROLE` (`grant_create_schema = false`): the same against `PROD_DB`,
minus `CREATE SCHEMA` — prod has no dynamic schemas. Both roles' grants come
from the same module code; only the tfvars-driven booleans differ.

No separate `CREATE DBT PROJECT` grant is needed: the role owns every schema
a dbt project object is deployed into, either statically (`BRONZE`) or
because it created the schema itself (the suffixed ones).

`SOURCE_DB` is not Terraform-managed, so Terraform issues grants on a
database it does not own. Accepted, and recorded here so it is not later
mistaken for drift.

Databases stay owned by `ACCOUNTADMIN`; only schemas transfer ownership.

### Execution contexts

The dbt project object is named `budget_dbt` in every context. It lives in
that context's **bronze** schema, so the schema suffix isolates the deployed
project code as well as the output it produces — no two contexts can
overwrite each other's code, and a PR's object is removed when its schema is.

| Context | Schemas written | dbt project object |
|---|---|---|
| Local dev | `PRE_PROD_DB.BRONZE_<user>`, `SILVER_<user>`, `GOLD_<user>` | `PRE_PROD_DB.BRONZE_<user>.budget_dbt` |
| PR → `dev` | `PRE_PROD_DB.BRONZE_PR_<n>`, `SILVER_PR_<n>`, `GOLD_PR_<n>` | `PRE_PROD_DB.BRONZE_PR_<n>.budget_dbt` |
| Merge to `dev` | `PRE_PROD_DB.BRONZE`, `SILVER`, `GOLD` | `PRE_PROD_DB.BRONZE.budget_dbt` |
| Merge to `main` | `PROD_DB.BRONZE`, `SILVER`, `GOLD` | `PROD_DB.BRONZE.budget_dbt` |

**Consequence:** `snow dbt deploy` requires its target schema to already
exist, and it runs before dbt would create one. The PR job and the local
flow therefore each issue a `CREATE SCHEMA IF NOT EXISTS` for their bronze
schema before deploying. The `dev` and `main` contexts need no such step —
those schemas are Terraform-managed.

### Suffix mechanism

`profiles.yml` keeps two targets: `dev` (→ `PRE_PROD_DB`,
`PRE_PROD_DBT_ROLE`) and `prod` (→ `PROD_DB`, `PROD_DBT_ROLE`). The suffix,
not the target, distinguishes the three pre_prod contexts.

The suffix travels as the Snowflake environment variable
`DBT_DEV_SCHEMA_SUFFIX`, read by `generate_schema_name` as
`env_var('DBT_DEV_SCHEMA_SUFFIX', '')`. An empty value yields unsuffixed
names.

- Local: `export DBT_DEV_SCHEMA_SUFFIX=shall`, executed with
  `--use-shell-env-vars`. Only `DBT_`-prefixed shell vars pass through, which
  is why the name carries that prefix.
- PR → `dev`: `--env-vars '{"DBT_DEV_SCHEMA_SUFFIX":"pr_<n>"}'`.
- Merge to `dev` and merge to `main`: unset.

An `env.yml` at the dbt project root declares the default environment with an
empty `DBT_DEV_SCHEMA_SUFFIX`.

**Constraint:** deploy-time compilation does not see environment variables at
all, so the macro's default is load-bearing — without it `snow dbt deploy`
fails to compile.

### Authentication and GitHub environments

Key-pair auth for the dbt jobs; the existing OIDC path is retired along with
the workflows that used it. A GitHub environment is a named bucket of
secrets that a job opts into with `environment:`, and a job declaring one can
read *every* secret it holds. Three environments, so no job can reach a
credential it has no business with:

| Environment | Secrets | Declared by | Branch rule |
|---|---|---|---|
| `infra` | `SNOWFLAKE_PRIVATE_KEY_RAW` (existing, `ACCOUNTADMIN`), `TF_API_TOKEN` | all Terraform jobs | none |
| `pre_prod` | `PRE_PROD_DBT_PRIVATE_KEY` | PR-to-`dev` and `dev`-merge dbt jobs | none |
| `prod` | `PROD_DBT_PRIVATE_KEY` | `main`-merge dbt job only | **restricted to `main`** |

Terraform gets its own `infra` environment because its job runs on dev PRs;
sharing `prod` with it would let any PR read the prod dbt key. The `prod`
environment additionally carries a deployment branch rule limiting it to
`main`, so no job on any other branch can use it regardless of what a
workflow file claims.

The `ACCOUNTADMIN` credential and the HCP token both remain reachable from a
PR, per the accepted risk above.

The `PRE_PROD_DBT_USER` private key is also generated locally and stored at
`~/.snowflake/keys/pre_prod_dbt_user.p8` (mode `600`), with a
`budget_pre_prod` entry in `~/.snowflake/connections.toml`. It never enters
the repo. `PROD_DBT_USER`'s private key is generated in CI-only form and is
deliberately never stored locally. Public keys are committed in Terraform.

`GITHUB_ACTIONS_SERVICE_USER`'s now-unused OIDC configuration stays as-is.

### Workflows

| File | Trigger | Jobs |
|---|---|---|
| `pr_to_dev.yml` *(replaces `incoming_pr.yml`)* | PR to `dev` | `terraform plan` against **all three workspaces**; create PR bronze schema, then dbt build into per-PR schemas |
| `dev_merged.yml` *(new)* | push to `dev` | `terraform apply` (pre_prod workspace); dbt build into `PRE_PROD_DB` |
| `main_merged.yml` *(replaces `pr_merged.yml`)* | push to `main` | `terraform apply` (shared workspace), then prod workspace; dbt build into `PROD_DB` |
| `pr_closed.yml` *(new)* | PR closed with base `dev` | drop that PR's three schemas, which removes its dbt project object with them |

The PR-to-`dev` job plans **all three** workspaces, not just pre_prod. It is
the only gate in the flow — the PR into `main` runs nothing — so without it
a prod infra change would apply on merge having never been previewed.

Terraform jobs stay path-filtered on `infra/**` as they are today. They no
longer commit state back to the branch — that step is deleted. No tasks are
created, resumed, or scheduled. `schedules.sql` is updated to reference the
real object and model names instead of the leftover tasty-bytes ones, and
remains uninvoked.

### Repository configuration

Not code, but required for the flow to behave as specified:

- Create the `dev` branch from `main`.
- Branch protection on `main`: require a review approval. No status checks,
  since nothing runs on the PR into `main`.
- Create the `infra` and `pre_prod` environments; add the `main` deployment
  branch rule to `prod`.
- Create the HCP Terraform organization and the three workspaces, each in
  **local execution mode**.

### The model

One staging model, `models/staging/stg_transactions.sql`, materialized as a
view in the bronze layer: casts `DATE` to `date`, converts `OUTFLOW` and
`INFLOW` from currency-formatted text to `number(38,2)`, and derives a signed
`amount` as inflow minus outflow. Accompanied by a `schema.yml` with
not-null tests on the key columns and the existing `test_is_positive_amount`
generic test applied to the two currency columns.

Its only job is to prove the pipeline runs in all four contexts.

### Removals

`dbt/setup/budget_setup.sql` and `dbt/setup/ci_cd_setup.sql` are deleted.
Terraform owns infrastructure now, and both scripts carry unresolved template
placeholders that make them unrunnable as written.

`infra/terraform.tfstate` and `infra/terraform.tfstate.backup` are deleted
once the HCP migration is verified.

## Prerequisites

- The Snowflake CLI is not installed on the development machine. It must be
  installed before the local half can be exercised.
- An HCP Terraform account and organization must exist, with an API token
  issued for CI.

## Out of scope

Silver and gold models, the semantic layer, the app, task scheduling,
automated `dev` resets, and retiring `GITHUB_ACTIONS_SERVICE_USER`.

## Known follow-up

`sdlc/classes.md` names `incoming_pr.yml` and `pr_merged.yml` explicitly
when justifying the `elevated` class. This spec renames both. The fix is to
rephrase that passage in terms of the mechanism ("CI applies to prod on
merge with no review step after") rather than filenames, so renames never
invalidate it again — a `governing`-class edit, tracked separately from this
change so it does not bump this one's class.

## Test plan

1. All three workspaces plan and apply cleanly after the state migration,
   and a second `plan` on each reports zero changes — proving nothing was
   recreated.
2. No `.tfstate` file remains in the repo, and no workflow writes to the
   repo.
3. `snow connection test` succeeds for `budget_pre_prod`.
4. A local deploy and `build --target dev` with `DBT_DEV_SCHEMA_SUFFIX=shall`
   creates `PRE_PROD_DB.BRONZE_SHALL.STG_TRANSACTIONS`, and its tests pass.
5. **Negative test:** `PRE_PROD_DBT_ROLE` is denied when attempting to create
   an object in `PROD_DB`.
6. A PR into `dev` creates `PRE_PROD_DB.BRONZE_PR_<n>.STG_TRANSACTIONS`, and
   its pre_prod plan shows **zero** unexpected diffs — proving state is no
   longer branch-dependent.
7. Merging that PR creates `PRE_PROD_DB.BRONZE.STG_TRANSACTIONS`.
8. Closing the PR removes the `PR_<n>` schemas and the dbt project object
   inside them.
9. A PR from the same feature branch into `main` triggers no workflow runs.
10. Merging it creates `PROD_DB.BRONZE.STG_TRANSACTIONS`.
