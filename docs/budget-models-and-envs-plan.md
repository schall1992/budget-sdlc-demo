---
status: hl_approved
---

# Plan: budget-models-and-envs (high-level)

## The core problem: the flow cannot validate itself into existence

The spec describes a CI flow where infrastructure is applied by workflows on
merge — but those workflows do not exist yet, the `dev` branch they trigger
on does not exist yet, and the credentials they would use belong to roles
that do not exist yet. The first application of the new infrastructure
therefore cannot come from CI.

Three consequences shape the sequencing:

1. **State migration must happen before anything else changes.** Moving the
   live resources into HCP Terraform is the one step that can destroy real
   objects if it goes wrong. It must be provably a no-op — zero-diff plans on
   all three workspaces — before any resource is added or any workflow is
   touched.
2. **Pre-prod's role and user must exist before the workflow that
   authenticates as them.** A workflow referencing
   `PRE_PROD_DBT_PRIVATE_KEY` fails until that user, its key, and the GitHub
   secret all exist.
3. **The model must be proven locally before it is proven in CI.** The local
   context is the only one that can be iterated on quickly, and it exercises
   the same suffix mechanism as the PR context.

So: bootstrap by hand, prove locally, then hand the working system to CI —
rather than landing code and hoping CI converges.

## Decisions taken at high-level approval

- **Execution.** The user supplies an HCP Terraform API token; I run stages
  1–5 directly. The HCP account signup itself remains the user's — a token
  cannot create the account that issues it.
- **Prod is never touched by a local credential.** `PROD_DBT_ROLE` and
  `PROD_DBT_USER` are written into the module in stage 4 but *not* applied;
  the prod workspace's first apply is CI's, in stage 6. This costs the
  negative test — the whole point of the role separation — which cannot run
  until stage 6. Accepted deliberately.
- **The process work ships first.** `doc-drift-cleanup` and
  `sdlc-risk-classes` leave on their own PR before this build starts, so
  this change is one slug and one class again. See stage 0.

## Approach

Seven stages. Each ends in a verifiable state; none begins before the
previous one is verified.

### Stage 0 — Ship the process work

The current branch's diff is entirely process and docs, so it is `governing`
∪ `trivial` in fact, whatever the budget spec declared. Rename it for what
it ships, PR it to `main`, merge. Delete the redundant `doc-drift-cleanup`
remote branch, whose commits it already contains.

This slug's approved spec and plan ride along in `docs/` — they are
`trivial` paths and landing them on `main` early costs nothing.

*Verified by:* `main` contains `sdlc/states.md` and `sdlc/classes.md`; a
fresh branch cut from `main` shows an empty diff.

### Stage 1 — Prerequisites (no code)

HCP Terraform organization with three workspaces (`budget-shared`,
`budget-pre-prod`, `budget-prod`), all in **local execution mode**.
Workspaces are created **by hand, not by Terraform** — a Terraform-managed
backend is a bootstrap paradox. Recorded as a deliberate manual step.

*Verified by:* all three workspaces reachable with the supplied token.

### Stage 2 — Refactor `infra/` to the parameterized module

Single module, boolean-gated resources (`create_shared`, `create_env`,
`env_name`, `grant_create_schema`), three `.tfvars` files. No new Snowflake
resources yet — this stage is pure restructuring of what already exists, so
the plan output is the proof.

*Verified by:* each workspace plans zero changes against the existing
account.

### Stage 3 — Migrate state to HCP

`state push` the committed state into `budget-shared`, then `state mv` the
environment resources into their own workspaces. Delete
`infra/terraform.tfstate*` and gitignore `*.tfstate*`.

*Verified by:* three consecutive zero-diff plans, and no `.tfstate` in
`git ls-files`. **This is the rollback point** — the committed state file is
recoverable from git history until this stage completes, and not afterwards.

### Stage 4 — Identities

Two halves, deliberately asymmetric:

- **Pre-prod, applied now.** `PRE_PROD_DBT_ROLE` and `PRE_PROD_DBT_USER`
  with their grants. Key pair generated, private key to
  `~/.snowflake/keys/pre_prod_dbt_user.p8` (mode `600`) with a
  `budget_pre_prod` entry in `~/.snowflake/connections.toml`. It never
  enters the repo.
- **Prod, written but not applied.** `PROD_DBT_ROLE` and `PROD_DBT_USER` go
  into the module and the prod tfvars; the prod workspace is not applied.
  The key pair is still generated here, because Terraform needs the public
  key committed before CI can create the user — the private key goes
  straight into the GitHub secret and is never written to disk.

No chicken-and-egg: the prod Terraform apply authenticates as the existing
Terraform identity, not as `PROD_DBT_USER`. Only the prod dbt job uses that
user, and it runs after the apply that creates it.

*Verified by:* `snow connection test` succeeds for `budget_pre_prod`; the
prod workspace plans exactly the four expected additions and nothing else.

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

### Stage 7 — The negative test

Once CI has created the prod identities, confirm `PRE_PROD_DBT_ROLE` is
denied when creating an object in `PROD_DB`, and that `PROD_DBT_ROLE` is
denied in `PRE_PROD_DB`.

Its own stage because it is the security property the whole change exists to
establish, and deferring prod to CI moved it to the very end — where it is
easiest to forget.

## Consequences worth accepting deliberately

- **Stages 2–5 apply infrastructure from a laptop**, which is what the
  finished system is meant to prevent. One-time bootstrap, not steady state,
  and now confined to pre-prod and shared.
- **The core security property goes unverified through six stages.** Direct
  cost of keeping prod CI-only.
- **Stage 6 is one large PR.** The workflows, the branch, and the repo
  configuration are mutually dependent; splitting them leaves a broken
  intermediate state. It is also where this slug's `elevated` gates bite:
  the reviewed `terraform plan` and `needs_confirmation` on both
  `BUILD_COMPLETE` and `PR_OPEN → SHIPPED`.
