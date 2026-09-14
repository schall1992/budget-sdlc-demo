# Budget dbt Project

## Overview

A dbt project for the budget data model, running on [dbt Projects on Snowflake](https://docs.snowflake.com/en/user-guide/data-engineering/dbt-projects-on-snowflake) — environment setup, data modeling, CI/CD, and scheduling, all native to Snowflake.

This repo doubles as a demo of AI SDLC practice: the process that governs
changes here is as much the point as the data model.

The scaffold (directory layout, CI/CD workflows, setup script shape) is adapted from Snowflake's tutorials:
- [Get started with dbt Projects on Snowflake](https://docs.snowflake.com/en/user-guide/tutorials/dbt-projects-on-snowflake-getting-started-tutorial)
- [Set up CI/CD for dbt Projects on Snowflake](https://docs.snowflake.com/en/user-guide/tutorials/dbt-projects-on-snowflake-ci-cd-tutorial)

## Onboarding: start here

A new session picking this repo up should read these in order. Only
`CLAUDE.md` is loaded automatically; everything else is read on demand, and
each layer points at the next.

| Layer | File(s) | Loaded how | Covers |
|---|---|---|---|
| 1. Rules | `CLAUDE.md` | **Auto-loaded** into context | Content discipline, how `kb/` is used as durable memory, the SDLC logging contract |
| 2. Repo map | [index.md](index.md) | Read on demand | What each top-level path is for |
| 3. Process | [sdlc/states.md](sdlc/states.md), [sdlc/classes.md](sdlc/classes.md) | Read before acting | The state machine, and the risk class that decides which states a change visits and which need sign-off |
| 4. Phase how-to | [discovery](sdlc/discovery.md), [spec](sdlc/spec.md), [plan](sdlc/plan.md), [build](sdlc/build.md), [pull-request](sdlc/pull-request.md) | Read per state | How to do the work once in a given state |
| 5. Environment facts | [kb/observations/](kb/observations/) | Read on demand | What actually exists in Snowflake and in this repo; known drift |
| 6. Design history | [docs/prod/](docs/prod/) | Read on demand | Specs and plans of shipped work — why things are shaped the way they are |
| 7. Process history | [log.md](log.md), [kb/log.md](kb/log.md) | **Not** auto-loaded; read only when asked | What was asked and answered, interaction by interaction |

Two things worth knowing before making any change:

- **Current state is never asked about — it's derived.** Which state a slug
  is in comes from whether its spec/plan exist in `docs/`, their `status:`
  frontmatter, per-task status in the plan, and git/GitHub state. See
  "Resolving current state" in [sdlc/states.md](sdlc/states.md).
- **Risk class is derived from the paths a change touches, never chosen.**
  A change touching `infra/` is `elevated` no matter how small. See
  [sdlc/classes.md](sdlc/classes.md).

## Current state

Infrastructure is **Terraform-managed** (`infra/`), not created by the setup
scripts. `ANALYSIS_WH`, `PRE_PROD_DB` and `PROD_DB` (each with
`BRONZE`/`SILVER`/`GOLD`), and `GITHUB_ACTIONS_SERVICE_USER` all exist. Source
data is in `SOURCE_DB.RAW.TRANSACTIONS`, which is *not* Terraform-managed.
See [kb/observations/snowflake-account-baseline.md](kb/observations/snowflake-account-baseline.md)
for the authoritative detail, and
[kb/observations/repo-and-cicd-baseline.md](kb/observations/repo-and-cicd-baseline.md)
for the repo, branching, and CI/CD shape.

Staging and mart models are still empty — see `docs/` for the live spec
driving that work.

## What's Included

### dbt project (`dbt/`)

- **Staging models** (`models/staging/`) — empty; `__sources.yml` declares the source.
- **Mart models** (`models/marts/`) — empty.
- **Custom macros** (`macros/generate_schema_name.sql`) — schema-name generation for multi-environment deployments.
- **Generic tests** (`tests/generic/`) — reusable test for validating positive amounts.

### Infrastructure (`infra/`)

Terraform (Snowflake provider) defining the warehouse, databases, schemas, and
the CI service user. State is committed to the repo and written back by CI.

### CI/CD (`.github/workflows/`)

- **`incoming_pr.yml`** — on PR to `main`: `terraform plan` (path-filtered on `infra/**`), plus a dbt deploy/build job.
- **`pr_merged.yml`** — on push to `main`: `terraform apply -auto-approve`, then commits updated state back to the branch.

Terraform jobs authenticate with an RSA key pair (`SNOWFLAKE_JWT`); the dbt
jobs use OIDC.

### Scheduling (`dbt/schedules.sql`)

Snowflake Task definitions for running the dbt project on a schedule.
Currently uninvoked.

### Setup scripts (`dbt/setup/`)

> **Do not run these.** `budget_setup.sql` and `ci_cd_setup.sql` are leftover
> tutorial scaffold. They carry unresolved template placeholders and stale
> `tasty-bytes` references that make them unrunnable as written, and
> Terraform has owned this infrastructure since `init-snowflake-infra`
> shipped. See
> [kb/observations/dbt-scaffold-drift.md](kb/observations/dbt-scaffold-drift.md).
> They are slated for deletion.

## Quick Start

Infrastructure already exists; you do not need to create it. To work on the
dbt project:

1. Read the onboarding chain above — `CLAUDE.md` and `sdlc/states.md` at minimum.
2. Create a [workspace in Snowsight](https://docs.snowflake.com/en/user-guide/ui-snowsight/workspaces) connected to this repo.
3. Run `dbt deps`, then `dbt run` from the workspace.

Infrastructure changes go through Terraform in `infra/` and are applied by CI
on merge — never applied by hand.
