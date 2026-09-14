---
type: Observation
title: HCP Terraform backend — organization and workspaces
description: >
  The remote state backend for infra/: HCP Terraform organization
  osusam28-main on the free tier, with three local-execution workspaces
  tagged `budget`. Created 2026-09-14 via the HCP API as stage 1 of
  budget-models-and-envs.
tags: [terraform, state, hcp, backend, environments]
occurred_at: 2026-09-14
timestamp: 2026-09-14
confidence: high
---

# HCP Terraform backend

Replaces the committed `infra/terraform.tfstate` described in
[repo-and-cicd-baseline.md](repo-and-cicd-baseline.md). Chosen because a
single committed state file cannot support three environments on divergent
branches without merge conflicts on every apply.

## Organization

`osusam28-main` — free tier (`free_standard`), account `osusam28@gmail.com`,
created 2026-09-14. Organization default execution mode is `remote`, which
is **not** what this project wants; each workspace overrides it.

## Workspaces

| Workspace | ID | Execution | Tags |
|---|---|---|---|
| `budget-shared` | `ws-71UsVnbJLoyT6DTs` | `local` | `budget` |
| `budget-pre-prod` | `ws-91xNdUVd3ie9zheh` | `local` | `budget` |
| `budget-prod` | `ws-KKSfFbMXdEaEyaR5` | `local` | `budget` |

**All three are `local` execution mode**, meaning HCP stores state but plans
and applies run on the local machine or the GitHub runner. This is what
keeps the Snowflake provider's credentials in the executing environment
rather than requiring them to be uploaded to HCP as workspace variables.

**Tagged `budget`** so `infra/`'s `cloud` block can select by tag rather
than by name, with `TF_WORKSPACE` choosing which one a given invocation
targets. The tag had to be applied through
`POST /api/v2/workspaces/{id}/relationships/tags` — passing `tag-names` in
the workspace-creation call is silently ignored.

## Credentials

The API token lives in `~/.terraform.d/credentials.tfrc.json` and is **not**
in the repo. CI will carry the same value as a `TF_API_TOKEN` secret in the
`infra` GitHub environment, consumed by
`hashicorp/setup-terraform`'s `cli_config_credentials_token`.

## How this was learned

Created and verified directly against the HCP API on 2026-09-14:
`GET /api/v2/organizations`, `POST .../workspaces`, and a readback of
`GET .../workspaces` confirming execution mode and tags on all three.
