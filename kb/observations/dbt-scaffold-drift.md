---
type: Observation
title: Scaffold drift — setup scripts and CI/CD carry unrunnable placeholders
description: >
  The dbt/CI-CD scaffold was adapted from Snowflake's tasty-bytes tutorials and
  still holds template placeholders, stale model names, and a source database
  that does not exist. Recorded 2026-09-10, unresolved.
tags: [dbt, cicd, setup, technical-debt]
occurred_at: 2026-09-10
timestamp: 2026-09-10
confidence: high
---

# Scaffold drift

The repo was restructured from Snowflake's tasty-bytes tutorial template in a
single commit (`ee81c6b`). The rename landed, but several template values did
not, so the scripts cannot be executed as written. Found by reading the files
on 2026-09-10; **none of this has been fixed or decided yet.**

## Contradiction: the declared source does not exist

`dbt/models/staging/__sources.yml` declares `database: SOURCE`, schema `RAW`,
table `TRANSACTIONS`. There is no `SOURCE` database in the account — the real
table is `SOURCE_DB.RAW.TRANSACTIONS` (see
[snowflake-account-baseline.md](snowflake-account-baseline.md)).

Separately, `dbt/setup/budget_setup.sql` creates a `budget_dbt_db.raw` schema
"for the budget foundational source data, once loaded" and leaves a Step 6
TODO to load it. So the repo currently implies two different homes for raw
data — an external `SOURCE`/`SOURCE_DB`, and a project-owned
`budget_dbt_db.raw`. Which is authoritative is an open question for the user;
do not pick one silently.

## Blockers that stop the scripts running

- `dbt/setup/ci_cd_setup.sql` — the network policy contains a literal
  `<other required rules>` placeholder, which is a syntax error. The script
  cannot run at all until that line is resolved.
- `dbt/setup/ci_cd_setup.sql` — the OIDC subject is
  `repo:your_repo_org/your_dbt_repo:environment:prod`. The real remote is
  `git@github.com:schall1992/budget-sdlc-demo.git`, so the subject must be
  `repo:schall1992/budget-sdlc-demo:environment:prod` for OIDC to match.
- `dbt/setup/budget_setup.sql` — the GitHub secret holds
  `your-gh-username` / `YOUR_PERSONAL_ACCESS_TOKEN`, and the API integration
  allows the prefix `https://github.com/my-github-account`.
- `dbt/setup/budget_setup.sql` — Step 1 uses a bare `CREATE WAREHOUSE`, which
  fails on a second run, while every other statement in the script is
  idempotent (`CREATE ... IF NOT EXISTS`).

## Stale and questionable values

- `dbt/schedules.sql` still selects tasty-bytes models:
  `build --select raw_customers stg_customers customers`. None of those exist
  in this project.
- `ci_cd_setup.sql` grants the service user `ACCOUNTADMIN` as its default
  role, and `dbt/profiles.yml` runs both targets as `accountadmin`. Fine for
  a trial account, but a poor thing to demonstrate in a repo about good SDLC
  practice — worth a deliberate decision either way.
- `dbt/packages.yml` is entirely commented out, including
  `Snowflake-Labs/dbt_semantic_view` — which the semantic-layer goal in
  `README.md` will need.
- Both workflows pin `--dbt-version 1.10.15`; nothing in the repo records why
  that version.
