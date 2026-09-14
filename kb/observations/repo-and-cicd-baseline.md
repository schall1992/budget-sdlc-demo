---
type: Observation
title: Repo, branching, and CI/CD baseline
description: >
  The current shape of the repository itself — single Terraform root, single
  branch, empty models, and the two workflows that plan and apply
  infrastructure. Recorded 2026-09-14 by inspecting the repo and workflows
  directly.
tags: [repo, cicd, terraform, branching, baseline]
occurred_at: 2026-09-14
timestamp: 2026-09-14
confidence: high
---

# Repo, branching, and CI/CD baseline

Companion to [snowflake-account-baseline.md](snowflake-account-baseline.md),
which covers what exists *in Snowflake*. This one covers what exists *in the
repo*. Kept here rather than in a spec because a spec's "Current state"
section is archived to `docs/prod/` when it ships, taking the description
with it.

## Terraform

One root module at `infra/` — `provider.tf`, `versions.tf`, `objects.tf`,
`service_user.tf` — with a **single committed state file**
(`infra/terraform.tfstate`). Nine resources. `.terraform/` and
`terraform.tfstate.backup` are gitignored; the state file itself is
deliberately committed and written back by CI.

Snowflake provider `snowflakedb/snowflake` v2.20.0.

## Branching

Only `main` is long-lived. Feature branches are cut from `main` and merged
back via PR; there is no `dev` or staging branch. Shipped so far:
`init-snowflake-infra`, `init-snowflake-objects`.

## Workflows

Both live in `.github/workflows/` and are path-filtered on `infra/**` for
their Terraform jobs via `dorny/paths-filter`.

| File | Trigger | What it does |
|---|---|---|
| `incoming_pr.yml` | PR to `main` | `terraform plan`; separately deploys a `tester_budget_dbt_project_object_gh_action` dbt project object and runs `snow dbt execute ... build --target dev` |
| `pr_merged.yml` | push to `main` | `terraform apply -auto-approve`, then commits the updated state file back to the branch |

**Two different auth mechanisms.** The Terraform jobs authenticate as
`GITHUB_ACTIONS_SERVICE_USER` with an RSA key pair
(`SNOWFLAKE_AUTHENTICATOR: SNOWFLAKE_JWT`, key from the
`SNOWFLAKE_PRIVATE_KEY_RAW` secret). The dbt jobs use OIDC
(`use-oidc: true`) and declare `environment: prod` to match the OIDC
subject. Easy to misread as one scheme — it is not.

`pr_merged.yml` applies to production with no review step after the merge.
This is why `infra/**` and `.github/workflows/**` are `elevated` class in
[sdlc/classes.md](../../sdlc/classes.md): the merge *is* the deploy.

## dbt

Runs via **dbt Projects on Snowflake** (`snow dbt deploy` / `snow dbt
execute`), not dbt Core in a runner. `models/staging/` and `models/marts/`
are empty apart from `.gitkeep` and `__sources.yml`. `dbt/setup/*.sql` is
unrunnable scaffold — see [dbt-scaffold-drift.md](dbt-scaffold-drift.md).

## How this was learned

Read directly from the working tree on 2026-09-14: `git branch -a`,
`git ls-files infra/`, `.gitignore`, and the two workflow files.
