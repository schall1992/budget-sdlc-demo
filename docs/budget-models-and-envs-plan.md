---
status: hl_draft
---

# Plan: budget-models-and-envs (high-level)

## The core problem: the flow cannot validate itself into existence

Every other consideration follows from this. The spec describes a CI flow
where infrastructure is applied by workflows on merge — but those workflows
do not exist yet, the `dev` branch they trigger on does not exist yet, and
the credentials they would use belong to roles that do not exist yet. The
first application of the new infrastructure therefore cannot come from CI.

Three consequences shape the sequencing:

1. **State migration must happen before anything else changes.** Moving nine
   live resources into HCP Terraform is the one step that can destroy real
   objects if it goes wrong. It must be provably a no-op — zero-diff plans on
   all three workspaces — before any resource is added or any workflow is
   touched.
2. **The new roles and users must exist before the workflows that
   authenticate as them.** A workflow referencing `PRE_PROD_DBT_PRIVATE_KEY`
   fails until that user, its key, and the GitHub secret all exist.
3. **The model must be proven locally before it is proven in CI.** The local
   context is the only one that can be iterated on quickly, and it exercises
   the same suffix mechanism as the PR context.

So: bootstrap by hand, prove locally, then hand the working system to CI —
rather than landing code and hoping CI converges.

## Approach

Six stages. Each ends in a verifiable state; none begins before the previous
one is verified.

### Stage 1 — Prerequisites (no code)

Snowflake CLI installed. HCP Terraform organization created with three
workspaces (`budget-shared`, `budget-pre-prod`, `budget-prod`), all in local
execution mode. API token issued.

Workspaces are created **by hand, not by Terraform** — a Terraform-managed
backend is a bootstrap paradox. Recorded as a deliberate manual step.

*Verified by:* `terraform login` succeeds and all three workspaces are
reachable.

### Stage 2 — Refactor `infra/` to the parameterized module

Single module, boolean-gated resources, three `.tfvars` files. No new
Snowflake resources yet — this stage is pure restructuring of what already
exists, so the plan output is the proof.

*Verified by:* each workspace plans zero changes against the existing
account.

### Stage 3 — Migrate state to HCP

`state push` the committed state into `budget-shared`, then `state mv` the
environment resources into their own workspaces. Delete
`infra/terraform.tfstate*`, gitignore `*.tfstate*`.

*Verified by:* three consecutive zero-diff plans, and no `.tfstate` in
`git ls-files`. **This is the rollback point** — the committed state file is
recoverable from git history until this stage is complete, and not
afterwards.

### Stage 4 — Roles, users, grants

Add `PRE_PROD_DBT_ROLE`/`USER` and `PROD_DBT_ROLE`/`USER` with their grants,
applied locally as `ACCOUNTADMIN`. Generate both key pairs; the pre_prod key
goes to `~/.snowflake/keys/` and `connections.toml`, the prod key goes
straight to the GitHub secret and nowhere on disk.

*Verified by:* `snow connection test` for `budget_pre_prod`, plus the
negative test — `PRE_PROD_DBT_ROLE` denied when creating an object in
`PROD_DB`. The negative test is the whole point of the change and should not
be deferred to the end.

### Stage 5 — dbt: suffix mechanism and the model

`generate_schema_name` macro, `env.yml`, `profiles.yml` targets, then
`stg_transactions.sql` and its `schema.yml`. Exercised in the local context
only.

*Verified by:* `PRE_PROD_DB.BRONZE_SHALL.STG_TRANSACTIONS` exists and its
tests pass.

### Stage 6 — Branching, workflows, repo configuration

Create `dev`. Add the four workflows, delete the two they replace, delete
`dbt/setup/`, fix `schedules.sql`. Configure GitHub environments, secrets,
and branch protection.

*Verified by:* the end-to-end sequence — PR into `dev` builds per-PR schemas
with a zero-diff pre_prod plan, merge builds `PRE_PROD_DB`, close drops the
PR schemas, PR into `main` runs nothing, merge builds `PROD_DB`.

## Consequences worth accepting deliberately

- **Stages 1–5 apply infrastructure from a laptop as `ACCOUNTADMIN`**, which
  is exactly what the finished system is meant to prevent. This is a one-time
  bootstrap, not the steady state, but it does mean `PROD_DB`'s role and user
  are created by hand rather than reviewed through a PR plan.
- **The branch already spans three slugs and two risk classes.** Under the
  union rule it owes `governing` and `elevated` gates both, including a
  reviewed `terraform plan` before `BUILD_COMPLETE`. That plan cannot exist
  until Stage 6 puts a workflow in place to post it.
- **Stage 6 is one large PR.** The workflows, the branch, and the repo
  configuration are mutually dependent; splitting them leaves a broken
  intermediate state.

## Open questions

1. **Who performs Stages 1–5?** They involve an HCP signup, a live state
   migration, and applies against a real Snowflake account. I can prepare
   every command and file, but running them touches real infrastructure.
2. **Does `PROD_DB`'s role/user get created by hand in Stage 4, or deferred
   to the first CI apply in Stage 6?** Deferring keeps prod untouched by
   local credentials, at the cost of the negative test not being runnable
   until the very end.
3. **Should `doc-drift-cleanup` and `sdlc-risk-classes` ship first?** Both
   are already built and sitting on this branch. Shipping them separately
   would shrink this change back to one slug and let the process docs land
   before the process is exercised against them.
