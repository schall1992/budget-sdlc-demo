# Budget dbt Project

## Overview

A dbt project for the budget data model, running on [dbt Projects on Snowflake](https://docs.snowflake.com/en/user-guide/data-engineering/dbt-projects-on-snowflake) — environment setup, data modeling, CI/CD, and scheduling, all native to Snowflake.

The scaffold (directory layout, CI/CD workflows, setup script shape) is adapted from Snowflake's tutorials:
- [Get started with dbt Projects on Snowflake](https://docs.snowflake.com/en/user-guide/tutorials/dbt-projects-on-snowflake-getting-started-tutorial)
- [Set up CI/CD for dbt Projects on Snowflake](https://docs.snowflake.com/en/user-guide/tutorials/dbt-projects-on-snowflake-ci-cd-tutorial)

Staging/mart models and source data are not yet built out — see `docs/` for the current spec/plan driving this project.

## What's Included

### Setup Scripts (`dbt/setup/`)

- **`budget_setup.sql`** — Creates the warehouse, database, schemas, and GitHub integration/network rules. Source data load (Step 6) is a placeholder until the budget data source is known.
- **`ci_cd_setup.sql`** — Creates a GitHub Actions service user with OIDC authentication and optional network policies for CI/CD pipelines.

### dbt Project (`dbt/`)

- **Staging models** (`models/staging/`) — empty, to be filled in once source data is known.
- **Mart models** (`models/marts/`) — empty, to be filled in as the data model takes shape.
- **Custom macros** — Schema name generation for multi-environment deployments (dev/prod).
- **Generic tests** — Reusable test for validating positive amounts.

### CI/CD (`.github/workflows/`)

- **`incoming_pr.yml`** — Runs dbt checks against a dev environment when a PR is opened.
- **`pr_merged.yml`** — Deploys the dbt project to production when a PR is merged.

### Scheduling (`dbt/schedules.sql`)

Task definitions for running the dbt project on a schedule using Snowflake Tasks.

## Quick Start

1. Run `dbt/setup/budget_setup.sql` in a Snowflake worksheet to create the environment (fill in Step 6 once source data is known).
2. Create a [workspace in Snowsight](https://docs.snowflake.com/en/user-guide/ui-snowsight/workspaces) connected to this repo.
3. Run `dbt deps`, then `dbt run` from the workspace.
