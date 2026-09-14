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
(`infra/terraform.tfstate`). Ten resources. `.terraform/` and
`terraform.tfstate.backup` are gitignored; the state file itself is
deliberately committed and written back by CI.

Snowflake provider `snowflakedb/snowflake` v2.20.0.

**Superseded 2026-09-14** by the `budget-models-and-envs` work: the module
is now parameterized across three HCP Terraform workspaces and no state
file is committed. See
[hcp-terraform-backend.md](hcp-terraform-backend.md). The paragraph above
is retained as the "before" picture the change was measured against.

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

**The dbt job in `incoming_pr.yml` has never succeeded.** Every run of that
workflow since the repo began — 2026-09-10 through 2026-09-14, eight runs
across three PRs — has ended in failure, always at `snow connection test -x`
with `251001: Account must be specified`. The `prod` GitHub environment
holds exactly one secret (`SNOWFLAKE_PRIVATE_KEY_RAW`) and **zero
variables**, so `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_DATABASE`, and
`SNOWFLAKE_SCHEMA` all resolve to empty strings. Both prior PRs were merged
red. The Terraform jobs are unaffected — they hardcode
`SNOWFLAKE_ORGANIZATION_NAME`/`SNOWFLAKE_ACCOUNT_NAME` rather than reading a
secret.

Two consequences: the OIDC path has never been proven to work end to end
(the run fails before authentication is even attempted), and the job runs
unconditionally on every PR to `main` — it has no `paths-filter` gate, so a
docs-only PR is gated on a dbt build that cannot pass.

### OIDC is configured, but with a subject that does not match

Setting a repo-level `SNOWFLAKE_ACCOUNT` secret (`epgqqsk-kn46620`) on
2026-09-14 got the job past the account error and to a second, deeper
failure:

```
394729 (08001): ... attempting to authenticate the JWT with issuer
'https://token.actions.githubusercontent.com' and subject
'repo:schall1992@104527486/budget-sdlc-demo@1357515027:environment:prod'.
Either the subject or issuer claims were not recognized, or the JWT's
signature could not be verified.
```

`DESC USER GITHUB_ACTIONS_SERVICE_USER` on 2026-09-14 settled which of two
candidate causes it is:

```
HAS_WORKLOAD_IDENTITY   true
```

So workload identity **is** configured, and the comment in
`infra/service_user.tf` asserting as much is correct — the failure is a
**subject mismatch**, not an absence. The part of that comment that is
wrong is the parenthetical "(used by the dbt workflows via the Snowflake
CLI)": no workflow run has ever authenticated successfully, so the
configuration has never actually been exercised.

**Snowflake does not expose the registered subject.** `DESC USER` reports
only the boolean; there is no `SHOW WORKLOAD IDENTITIES`, and
`SNOWFLAKE.ACCOUNT_USAGE.USERS` carries the same boolean and nothing more.
The value can be overwritten with `ALTER USER ... SET WORKLOAD_IDENTITY`
but never read back. Diagnosing a mismatch therefore means re-setting the
subject to a known value and retrying, not comparing the two.

The likely mismatch is form: GitHub is presenting the immutable-ID variant
(`repo:schall1992@104527486/budget-sdlc-demo@1357515027:environment:prod`),
while a subject registered by hand would almost certainly have used the
human-readable `repo:schall1992/budget-sdlc-demo:environment:prod`. Not
confirmed, and not worth confirming — see below.

**Not being fixed.** The approved `budget-models-and-envs` design retires
OIDC entirely in favour of per-environment key-pair service users
(`PRE_PROD_DBT_USER`, `PROD_DBT_USER`), matching what the Terraform jobs
already do. Repairing the subject would be work on a mechanism scheduled
for deletion. When OIDC goes, `default_workload_identity` should come out
of `lifecycle.ignore_changes` along with the comment.

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
