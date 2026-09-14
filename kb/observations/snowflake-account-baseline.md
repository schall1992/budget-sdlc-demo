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

### The Terraform provider cannot use either connection

`sam_test` authenticates with `OAUTH_AUTHORIZATION_CODE`, which the
Snowflake Terraform provider does not implement, and `externalbrowser`
fails on this account (`390190`: SAML IdP account parameter). The provider
also cannot read `connections.toml` at all — its TOML schema admits only
profile tables, so the top-level `default_connection_name` key makes the
whole file fail to decode.

So on 2026-09-14 `SHALL` was given an RSA key pair for Terraform's use:
private key at `~/.snowflake/keys/shall_terraform.p8` (mode 600, never in
the repo), public half registered with `ALTER USER SHALL SET
RSA_PUBLIC_KEY`. This grants no new privilege — `SHALL` already holds
`ACCOUNTADMIN` — it only adds an auth method the provider supports, and
leaves the MFA/OAuth login untouched. Local runs use the same four
environment variables CI does, plus the key:

```
SNOWFLAKE_ORGANIZATION_NAME=epgqqsk SNOWFLAKE_ACCOUNT_NAME=kn46620 \
SNOWFLAKE_USER=SHALL SNOWFLAKE_AUTHENTICATOR=SNOWFLAKE_JWT \
SNOWFLAKE_PRIVATE_KEY="$(cat ~/.snowflake/keys/shall_terraform.p8)"
```

This credential is deliberately **not** in Terraform state: it is the
credential Terraform authenticates with, so managing it would be circular.

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

## Cross-environment denial reads as "does not exist"

Established 2026-09-14 by attempting `CREATE TABLE PROD_DB.BRONZE.x` as
`PRE_PROD_DBT_ROLE`.

Snowflake refuses with `002003 (02000): SQL compilation error: Database
'PROD_DB' does not exist or not authorized.` — it will not tell an
unauthorized role which of the two it is, deliberately, so the role cannot
probe for the existence of objects it has no rights to.

The consequence for testing: that message alone proves nothing. It is
identical to what a typo in the database name produces. The isolation is only
demonstrated by pairing it with a privileged read showing the object does
exist — `SHOW SCHEMAS IN DATABASE PROD_DB` as `ACCOUNTADMIN` lists BRONZE,
SILVER and GOLD (created 2026-09-10). Both halves together are the evidence;
either alone is not.
