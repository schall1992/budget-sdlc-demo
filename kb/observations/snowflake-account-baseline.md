---
type: Observation
title: Snowflake account baseline — nothing from the setup scripts has been run
description: >
  As of 2026-09-10 the demo's Snowflake account holds the source data only.
  None of the objects budget_setup.sql / ci_cd_setup.sql create exist yet, and
  the default CLI connection is broken.
tags: [snowflake, environment, setup, connections]
occurred_at: 2026-09-10
timestamp: 2026-09-10
confidence: high
---

# Snowflake account baseline

Established by running read-only SQL against the account on 2026-09-10 (via
the `cortex` CLI — the `snow` CLI is **not** installed locally, so anything
depending on `snow` only runs in GitHub Actions, not on this machine).

## Connections

`~/.snowflake/connections.toml` defines two connections, both user `SHALL`:

| Connection | Account identifier | State |
|---|---|---|
| `trial` | `kn46620` | **Broken** — every query returns a 404. Identifier appears to be missing the org prefix. It is also the active/default connection. |
| `sam_test` | `epgqqsk-kn46620` | **Works.** Resolves to account `ZV96105`, region `AWS_US_EAST_2`, role `ACCOUNTADMIN`. |

All findings below come from `sam_test`. Which of the two is *meant* to be the
demo target is still an open question for the user.

## What exists

Databases in the account: `SNOWFLAKE`, `SNOWFLAKE_LEARNING_DB`,
`SNOWFLAKE_SAMPLE_DATA`, `SOURCE_DB`, `USER$SHALL`.

The only project-relevant object is the source table
**`SOURCE_DB.RAW.TRANSACTIONS`** — 1,738 rows, 8 columns, all `VARCHAR`
except `DATE`:

`ACCOUNT`, `DATE`, `PAYEE`, `CATEGORY_GROUP`, `CATEGORY`, `MEMO`, `OUTFLOW`,
`INFLOW`

The `OUTFLOW`/`INFLOW` split plus `CATEGORY_GROUP`/`CATEGORY` is the shape of a
personal-budgeting export. Amounts arriving as `VARCHAR` means staging has to
cast them, and the generic test `is_positive_amount` cannot apply until it
does.

## What does not exist

None of these have been created — the setup scripts have never been run
successfully against this account:

- Warehouse `budget_dbt_wh`
- Database `budget_dbt_db` and its `dev` / `prod` / `integrations` / `raw` schemas
- Any API integration (so no GitHub/Snowsight workspace link)
- User `github_actions_service_user`
- Network policy `github_actions_policy`
- Tasks `run_budget_subset` / `run_budget_full` (the only task in the account
  is the system task `CORTEX_BASE_MODELS_REFRESH_TASK`)
- Any dbt project object — zero in the account, so
  `budget_dbt_object_gh_action` does not exist

Practical consequence: both GitHub Actions workflows would fail today, and
`dbt run` has nowhere to materialize into. Standing the environment up is a
prerequisite for any modeling work.

See [dbt-scaffold-drift.md](dbt-scaffold-drift.md) for the repo-side reasons
the scripts cannot simply be run as written.
