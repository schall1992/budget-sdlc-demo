---
type: Observation
title: github_actions_service_user created manually, outside Terraform
description: >
  The account's github_actions_service_user was hand-created via Cortex on
  2026-09-10, ahead of the infra/ Terraform code existing, diverging from the
  spec's intended bootstrap flow.
tags: [snowflake, environment, service-user, terraform, bootstrap]
occurred_at: 2026-09-10
timestamp: 2026-09-10
confidence: high
---

# github_actions_service_user created out of band

`docs/init-snowflake-infra-spec.md` calls for `github_actions_service_user`
to be created by the first (bootstrap) `terraform apply`, run locally as the
human `SHALL` identity, once `infra/` exists. Instead, at the user's explicit
request, the account (`sam_test`, `epgqqsk-kn46620`) already needed it before
any Terraform code was written, so it was created by hand via Cortex on
2026-09-10.

## What was created

A single `TYPE = SERVICE` user, `GITHUB_ACTIONS_SERVICE_USER`, `DEFAULT_ROLE
= ACCOUNTADMIN`, with two auth methods attached (per the merged-user design
in the spec):

- **OIDC workload identity** — issuer `https://token.actions.githubusercontent.com`,
  subject `repo:schall1992/budget-sdlc-demo:environment:prod`. For the
  existing dbt GitHub Actions workflows via the Snowflake CLI.
- **RSA key pair** — public key fingerprint
  `SHA256:Sjh+g1PSZXjaWsQBDKup7yKYjFADgynt+RbF7VKIL4E=`. Private key is
  stored as the `SNOWFLAKE_PRIVATE_KEY_RAW` secret in the `prod` GitHub
  environment on `schall1992/budget-sdlc-demo` (set via `gh secret set`
  2026-09-10); not retained anywhere in this repo. The `prod` environment
  didn't exist yet and was created as part of this — it's a prerequisite
  for the OIDC subject `repo:schall1992/budget-sdlc-demo:environment:prod`
  to resolve, too.

No other spec'd objects (warehouse, database, network policy, API
integration) were created — see
[snowflake-account-baseline.md](snowflake-account-baseline.md) for what's
still missing.

## Consequence for Build

When `infra/` Terraform code is written, it must **`terraform import`** this
existing user (`terraform import snowflake_service_user.github_actions
GITHUB_ACTIONS_SERVICE_USER`) rather than creating it fresh — otherwise the
first apply will fail on a name collision. The Terraform resource
definition must match the live configuration above (both auth methods,
`DEFAULT_ROLE = ACCOUNTADMIN`) or the apply will attempt to change it.
