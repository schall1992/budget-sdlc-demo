# Plan: init-snowflake-infra

Paired with `docs/init-snowflake-infra-spec.md`.

## High-level approach

1. Scaffold `infra/` — `provider.tf`/`versions.tf` pinning the
   `snowflakedb/snowflake` Terraform provider, local backend config
   (`infra/terraform.tfstate`, committed to git). No `variables.tf` — this
   spec introduces no new secret to parameterize.
2. Write the `github_actions_service_user` Terraform resource to mirror the
   live user exactly (OIDC workload identity + RSA key pair,
   `DEFAULT_ROLE = ACCOUNTADMIN`), then `terraform import` it. Iterate the
   resource definition until `terraform plan` shows zero diff — that's the
   proof the pipeline works, since nothing else is in scope to create.
3. Write `infra_pr.yml` (plan-only on PRs touching `infra/**`) and
   `infra_merged.yml` (apply + commit state on merge touching `infra/**`),
   mirroring the existing dbt PR/merge pattern. Add a `needs:` dependency
   from the existing `pr_merged.yml` onto the new infra-apply job.
4. Fix `dbt/models/staging/__sources.yml` to reference
   `SOURCE_DB.RAW.TRANSACTIONS`.
5. Validate end to end: `terraform init`/`validate`/`plan` locally against
   `sam_test`, confirming the zero-diff plan; then open a PR touching
   `infra/` to prove `infra_pr.yml` posts that same plan in CI, without
   merging it.

**Note for the eventual Pull Request phase:** shipping this feature (per
this repo's own SDLC) means merging a PR that touches `infra/` into
`main` — which *will* trigger `infra_merged.yml`. That's expected and safe
here specifically because the plan is zero-diff: the apply runs but has
nothing to do. The spec's "no PR touching `infra/` is merged" language is
about not merging early just to test (that's what step 5's throwaway PR is
for) — not a block on ever shipping. Re-confirm the plan is still empty
right before that merge.

## Breakdown

**T1 — Scaffold `infra/`**
Create `infra/provider.tf` (pin `snowflakedb/snowflake` provider version)
and `infra/versions.tf`/backend config for the local, git-committed state
file.
- Tests/evals: `terraform init` succeeds; `terraform validate` passes on
  the (currently resource-less) config.
- Dependencies: independent

**T2 — Write the `github_actions_service_user` resource**
Research the provider's exact resource/attribute shape for a service user
carrying both OIDC workload identity and an RSA key pair (this needs
checking against current provider docs, not assumed), then write it to
match the live values in
`kb/observations/github-actions-service-user-bootstrap.md` (OIDC subject,
RSA key fingerprint, `DEFAULT_ROLE = ACCOUNTADMIN`).
- Tests/evals: `terraform validate` passes.
- Dependencies: depends on: T1

**T3 — Import and reconcile**
Run `terraform import` for `github_actions_service_user` against `sam_test`,
then `terraform plan`. Iterate the T2 resource definition until the plan
shows zero diff.
- Tests/evals: `terraform plan` output is exactly "No changes."
- Dependencies: depends on: T2

**T4 — Write `infra_pr.yml`**
On a PR touching `infra/**`: `terraform init` + `terraform plan`,
authenticated as `github_actions_service_user` via its existing key-pair
GitHub secret. Plan only, no apply.
- Tests/evals: workflow YAML is valid; path filter matches `infra/**`
  only; auth step references the existing secret name (no new secret
  introduced).
- Dependencies: depends on: T1

**T5 — Write `infra_merged.yml`**
On merge to `main` touching `infra/**`: `terraform apply -auto-approve`,
then commit the updated `infra/terraform.tfstate` back to `main`
(`contents: write` permission, commit+push step).
- Tests/evals: workflow YAML is valid; permissions and commit/push step
  present; path filter matches `infra/**` only.
- Dependencies: depends on: T1

**T6 — Wire `pr_merged.yml`'s `needs:` dependency**
Add a `needs:` on the new infra-apply job from T5 to the existing
`pr_merged.yml`, so a PR touching both `infra/` and `dbt/` applies infra
first.
- Tests/evals: workflow YAML is valid; `incoming_pr.yml` is confirmed
  unchanged (diff review).
- Dependencies: depends on: T5

**T7 — Fix `__sources.yml`**
Point the dbt source at `SOURCE_DB.RAW.TRANSACTIONS` instead of the
nonexistent `SOURCE.RAW.TRANSACTIONS`.
- Tests/evals: file is valid YAML; `database`/`schema`/`table` match
  `SOURCE_DB` / `RAW` / `TRANSACTIONS`.
- Dependencies: independent

**T8 — Prove the pipeline in CI**
Open a PR touching `infra/` (the scaffold from T1–T3 is enough) and
confirm `infra_pr.yml` runs and posts a real plan showing zero changes.
Do not merge this PR.
- Tests/evals: CI run succeeds; posted plan shows no changes; PR is left
  unmerged (confirmed via `gh pr view`).
- Dependencies: depends on: T3, T4

## Tasks that can run in parallel

T1 first; then T2→T3, T4, T5→T6, and T7 can all proceed independently of
each other; T8 waits on T3 and T4.
