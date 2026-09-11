---
type: Observation
title: Snowflake account baseline — project objects now exist
description: >
  As of 2026-09-10 the demo's Snowflake account holds the source data and all
  project infrastructure: ANALYSIS_WH, PRE_PROD_DB (bronze/silver/gold),
  PROD_DB (bronze/silver/gold), and GITHUB_ACTIONS_SERVICE_USER. All managed
  by Terraform (infra/).
tags: [snowflake, environment, setup, connections]
occurred_at: 2026-09-10
timestamp: 2026-09-10
confidence: high
---

# Snowflake account baseline

Originally established by read-only SQL on 2026-09-10; updated same day
after `init-snowflake-objects` terraform apply.

## Connections

`~/.snowflake/connections.toml` defines two connections, both user `SHALL`:

| Connection | Account identifier | State |
|---|---|---|
| `trial` | `kn46620` | **Broken** — every query returns a 404. Identifier appears to be missing the org prefix. It is also the active/default connection. |
| `sam_test` | `epgqqsk-kn46620` | **Works.** Resolves to account `ZV96105`, region `AWS_US_EAST_2`, role `ACCOUNTADMIN`. |

All findings below come from `sam_test`.

## What exists

**Source data:** `SOURCE_DB.RAW.TRANSACTIONS` — 1,738 rows, 8 columns, all
`VARCHAR` except `DATE`: `ACCOUNT`, `DATE`, `PAYEE`, `CATEGORY_GROUP`,
`CATEGORY`, `MEMO`, `OUTFLOW`, `INFLOW`. External to this project; not
Terraform-managed.

**Project infrastructure (Terraform-managed, `infra/`):**

| Object | Type | Notes |
|---|---|---|
| `ANALYSIS_WH` | Warehouse | XSMALL, auto_suspend 60s, Gen2, suspended |
| `PRE_PROD_DB` | Database | CI/PR builds and local dev |
| `PRE_PROD_DB.BRONZE` | Schema | Raw/staging layer |
| `PRE_PROD_DB.SILVER` | Schema | Intermediate transformations |
| `PRE_PROD_DB.GOLD` | Schema | Mart/presentation layer |
| `PROD_DB` | Database | Production deployment on merge to `main` |
| `PROD_DB.BRONZE` | Schema | Raw/staging layer |
| `PROD_DB.SILVER` | Schema | Intermediate transformations |
| `PROD_DB.GOLD` | Schema | Mart/presentation layer |
| `GITHUB_ACTIONS_SERVICE_USER` | Service user | ACCOUNTADMIN, OIDC + RSA key pair, default_warehouse ANALYSIS_WH |

**Not Terraform-managed:** `COMPUTE_WH`, `SNOWFLAKE_LEARNING_WH`,
`SYSTEM$STREAMLIT_NOTEBOOK_WH` (account defaults); `SNOWFLAKE`,
`SNOWFLAKE_LEARNING_DB`, `SNOWFLAKE_SAMPLE_DATA` (system databases);
`USER$SHALL` (personal database).

## What does not yet exist

- Any API integration (no GitHub/Snowsight workspace link)
- Network policy `github_actions_policy`
- Tasks `run_budget_subset` / `run_budget_full`
- Any dbt project object
- Observability settings on schemas (LOG_LEVEL, TRACE_LEVEL, METRIC_LEVEL)
