---
type: Observation
title: GitHub environments and where each credential lives
description: >
  The three GitHub environments the CI redesign uses, which secret sits in
  each, and the CI service user key rotation of 2026-09-14.
tags: [ci, credentials, github]
timestamp: 2026-09-14
confidence: high
---

# GitHub environments and where each credential lives

Established 2026-09-14 while building `budget-models-and-envs` (T12),
verified with `gh secret list --env <name>`. GitHub will not read a secret
back, so this file is the only record of what is where.

## The three environments

| Environment | Secrets | Branch restriction |
|---|---|---|
| `infra` | `SNOWFLAKE_PRIVATE_KEY_RAW`, `TF_API_TOKEN` | none |
| `pre_prod` | `PRE_PROD_DBT_PRIVATE_KEY` | none |
| `prod` | `PROD_DBT_PRIVATE_KEY` | `main` only |

`SNOWFLAKE_ACCOUNT` is a repo-level secret, not per-environment.

`SNOWFLAKE_PRIVATE_KEY_RAW` is `GITHUB_ACTIONS_SERVICE_USER`'s key — the
Terraform credential. It belongs to `infra`, not `prod`; it was in `prod`
before this change only because `prod` was the sole environment that existed.
Easy to misfile, since the name says nothing about which user it is.

The `main` restriction on `prod` is the real control on the prod dbt key: a
workflow can name `environment: prod` all it likes, but a job running off any
other branch will not be given the secret.

## The CI service user key was rotated

`GITHUB_ACTIONS_SERVICE_USER`'s RSA key pair was replaced on 2026-09-14.
Not a compromise — the secret had to move from `prod` to `infra` and GitHub
cannot read one back, so replacing the pair was the only way to move it.

The private half exists **only** in the `infra` secret; it was generated to
the scratchpad, loaded, and deleted. The public half is committed in
`infra/envs/shared.tfvars` and applied through Terraform — so rotating this
user again means editing that file and applying the shared workspace, never
`ALTER USER ... SET RSA_PUBLIC_KEY`, which the next apply would revert.

Verified after the apply: `snow sql` as `GITHUB_ACTIONS_SERVICE_USER` with
the new private key returns `ACCOUNTADMIN`.

## The HCP token was deliberately not rotated

`TF_API_TOKEN` in `infra` is the same HCP Terraform token used for stages
1–3, copied from `~/.terraform.d/credentials.tfrc.json`. That token was
pasted into a chat transcript and the plan called for replacing it; the user
decided on 2026-09-14 not to. It is a free-tier personal token on org
`osusam28-main` — see [hcp-terraform-backend.md](hcp-terraform-backend.md).
