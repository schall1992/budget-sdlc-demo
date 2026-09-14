---
status: breakdown_approved
---

# Plan: budget-models-and-envs

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

### Stages 2+3 — Parameterized module, on HCP state

Merged into one stage. They cannot be verified separately: switching to
`count`/`for_each` changes resource *addresses*, so the zero-diff plan that
would prove stage 2 is only reachable after stage 3 has re-addressed the
resources in state. Attempting stage 2 alone would produce a plan proposing
to destroy and recreate everything — indistinguishable from a real defect.

Single module, boolean-gated resources, three `.tfvars` files, no new
Snowflake resources. Then `state push` into `budget-shared`, `state mv` the
environment resources into their own workspaces, `state rm` each
workspace's non-owned resources, delete the committed state file and
gitignore `infra/*.tfstate*`.

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
prod workspace plans exactly the expected additions and nothing else.

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
- **A second local Terraform credential exists.** The provider supports
  neither authenticator in `connections.toml`, so `SHALL` was given an RSA
  key pair to run stages 2–5. It grants no privilege `SHALL` did not already
  hold, and is not Terraform-managed — it is the credential Terraform
  authenticates with, so managing it would be circular. See
  `kb/observations/snowflake-account-baseline.md`.

---

# Breakdown

Tasks carry `depends on:` or `independent` — Build reads nothing else to
decide what may run in parallel. Stages 0–3 ran ahead of this breakdown
(they were environment setup rather than code) and are recorded here as
done so the slug's state stays derivable from this file.

## Stage 0–3 (complete)

**T0 — Ship `doc-drift-cleanup` + `sdlc-risk-classes`.** `independent`.
*Status:* done. Merged to `main`; one CI check waived per the rule added to
`sdlc/classes.md`.

**T1 — Stand up the HCP organization and three workspaces.**
depends on: T0. *Status:* done. `osusam28-main`, all three in local
execution mode, tagged `budget`.

**T2 — Parameterize `infra/` and migrate state to HCP.** depends on: T1.
*Status:* done, commit `224d401`. Three zero-diff plans; no tfstate tracked.

## Stage 4 — Identities

**T3 — Write the role, user, and grant resources.** depends on: T2.

Add to the module, all gated on `create_env`: a `snowflake_account_role`, a
`snowflake_service_user` with `rsa_public_key`, and the grants from the
spec's Grants section — warehouse usage, database usage, schema ownership,
`SOURCE_DB` read, and `CREATE SCHEMA` gated on a new `grant_create_schema`
variable. Also grant each role to `SYSADMIN`. New variables:
`grant_create_schema` (bool), `dbt_role_name`, `dbt_user_name`,
`dbt_user_rsa_public_key`, `source_database`.

Note a deviation from the spec: it names an `env_name` variable, but
`env_database` already carries that information, so role/user names come
from their own variables rather than being derived from a separate
`env_name`. Flag at review rather than silently adding a third spelling of
the same fact.

*Tests:* `terraform validate`; `plan` on `budget-shared` still zero-diff
(proving the new resources are correctly gated off there).

*Status:* done, commit `224d401`. Merged with T2 — the two cannot be verified separately.

**T4 — Generate the pre-prod key pair.** depends on: T3.

Private key to `~/.snowflake/keys/pre_prod_dbt_user.p8` at mode `600`,
public half into `infra/envs/pre_prod.tfvars`.

*Tests:* the private key is mode `600`; `git status` shows no key file.

*Status:* done, commit `d295165`. Key at `~/.snowflake/keys/pre_prod_dbt_user.p8`, mode 600.

**T5 — Apply the pre-prod workspace.** depends on: T4.

*Tests:* apply succeeds; a second `plan` reports zero changes; `SHOW GRANTS
TO ROLE PRE_PROD_DBT_ROLE` matches the spec's list exactly — no more, no
less.

*Status:* done, commit `d295165`.

**T6 — Add the `budget_pre_prod` connection.** depends on: T5.

Entry in `~/.snowflake/connections.toml`. Note that the file's existing
top-level `default_connection_name` key is what makes the Terraform
provider unable to read it — do not "fix" that by removing the key, which
would break the CLI.

*Tests:* `snow connection test -c budget_pre_prod` succeeds and reports
role `PRE_PROD_DBT_ROLE`.

*Status:* done, commit `d295165`.

**T7 — Generate the prod key pair; write prod config without applying.**
depends on: T3.

Public half into `infra/envs/prod.tfvars`; private half piped straight into
the `PROD_DBT_PRIVATE_KEY` secret in the `prod` GitHub environment, never
written to disk.

*Tests:* `plan` on `budget-prod` shows exactly the expected additions and
zero changes to existing resources — and is **not** applied. `gh secret
list --env prod` shows the secret.

## Stage 5 — dbt

*Status:* done, commit `d295165`. Prod key is CI-only and was never stored locally.

**T8 — Suffix mechanism.** depends on: T6.

`macros/generate_schema_name.sql` reading
`env_var('DBT_DEV_SCHEMA_SUFFIX', '')`, an `env.yml` declaring the default
empty value, and `dev`/`prod` targets in `profiles.yml`.

*Tests:* `snow dbt deploy` compiles with no suffix set — this is the
load-bearing case, since deploy-time compilation cannot see environment
variables and fails without the macro default.

*Status:* done, commit `c4511b7`. `--env-vars` and `--use-shell-env-vars` exist but are hidden from `--help`; both were verified empirically.

**T9 — The staging model.** depends on: T8.

`models/staging/stg_transactions.sql` as a view, plus `schema.yml` with the
not-null tests and `test_is_positive_amount`.

*Tests:* compiles; the currency-to-number cast is checked against real
values, not just non-null — a cast that silently yields `NULL` for
`$1,234.56` would pass a not-null test on the source column while producing
a useless model.

*Status:* done, commit `c4511b7`. `test_is_positive_amount` replaced with `is_non_negative` — the spec's choice would have failed on correct data, since 1,606 rows have `inflow = 0`.

**T10 — Prove the local context end to end.** depends on: T9.

`CREATE SCHEMA IF NOT EXISTS PRE_PROD_DB.BRONZE_SHALL`, deploy, then
`build --target dev` with `DBT_DEV_SCHEMA_SUFFIX=shall`.

*Tests:* spec test-plan item 4 — `PRE_PROD_DB.BRONZE_SHALL.STG_TRANSACTIONS`
exists, row count matches the 1,738 source rows, and all tests pass.

## Stage 6 — Branching, workflows, repo configuration

*Status:* done, commit `c4511b7`. `PRE_PROD_DB.BRONZE_SHALL`, 1,738 rows.

**T11 — Create the `dev` branch.** depends on: T2.

*Status:* done, commit `fd9c9f2`.

**T12 — GitHub environments and secrets.** depends on: T7.

Create `infra` (holding `SNOWFLAKE_PRIVATE_KEY_RAW` and `TF_API_TOKEN`) and
`pre_prod` (holding `PRE_PROD_DBT_PRIVATE_KEY`); add the `main` deployment
branch rule to `prod`. Rotate the HCP token as part of this — the one used
for stages 1–3 was pasted into a chat transcript.

*Tests:* `gh api` shows three environments with the expected secret names
and the `prod` branch policy; the rotated token still authenticates.

*Status:* done, commit `fd9c9f2`. The HCP token was **not** rotated — the user decided against it. `GITHUB_ACTIONS_SERVICE_USER`'s key pair was rotated instead, to move it from the `prod` environment to `infra`, since GitHub cannot read a secret back.

**T13 — Write the four workflows and delete what they replace.**
depends on: T10, T12.

`pr_to_dev.yml`, `dev_merged.yml`, `main_merged.yml`, `pr_closed.yml`;
delete `incoming_pr.yml`, `pr_merged.yml`, and `dbt/setup/`; fix
`schedules.sql`. No job commits to the repo.

This also retires the broken OIDC dbt job — the one the stage-0 waiver was
granted against. The waiver was per-PR, so this task is what stops the next
PR being red for the same reason.

*Tests:* spec test-plan item 2 — `grep` finds no `git push`/`git commit` in
any workflow. Each workflow parses (`actionlint` or `gh workflow view`).

*Status:* done, commit `7229258`. `schedules.sql`'s two-task DAG collapsed to one: with a single model a "subset" task selects what the full build does.

**T14 — Branch protection on `main`.** depends on: T11.

Require one review approval, no status checks.

*Tests:* a direct push to `main` is rejected.

*Status:* done, commit `fd9c9f2`.

**T15 — Prove the CI flow end to end.** depends on: T13, T14.

Spec test-plan items 6–10, in order: PR into `dev` builds `BRONZE_PR_<n>`
with a zero-diff pre_prod plan; merge builds `PRE_PROD_DB.BRONZE`; closing
the PR drops the `PR_<n>` schemas and the dbt project object inside them; a
PR into `main` triggers no workflow; merging it applies shared then prod and
builds `PROD_DB.BRONZE`.

The zero-diff pre_prod plan on a branch cut from `main` is the specific
proof that state is no longer branch-dependent — the problem committed
state could not solve. It is the one item here that must not be waved
through as "CI went green."

## Stage 7 — The negative test

*Status:* done. All five items pass, each verified in Snowflake rather than by CI colour. PR #4 → `dev`, PR #6 → `main`; prod applied 13 resources, matching the plan previewed on #4.

**T16 — Prove the roles cannot cross.** depends on: T15.

As `PRE_PROD_DBT_ROLE`, attempt `CREATE TABLE` in `PROD_DB.BRONZE`; as
`PROD_DBT_ROLE`, attempt the same in `PRE_PROD_DB.BRONZE`.

*Tests:* both are denied. A test that can only fail by *not* erroring needs
the error text checked — an authorization denial, not a "database does not
exist" or a connection failure, either of which would pass a naive
"it threw" assertion while proving nothing.

*Status:* done, by enumeration rather than by the literal attempt in both directions, with the user's agreement.

The pre_prod→prod direction was tested literally and denied. The prod→pre_prod direction cannot be tested from a laptop — `PROD_DBT_USER`'s key is CI-only by design, which is the property being relied on. Grants were enumerated instead, and that is the better evidence anyway: this task demanded the error text be checked, and the error turned out to be `does not exist or not authorized`, byte-identical to what a typo produces.

`PROD_DBT_ROLE` holds nothing on `PRE_PROD_DB`; `PRE_PROD_DBT_ROLE` nothing on `PROD_DB`; `PUBLIC` nothing on either; neither role inherits any role. The last two close the back doors an "it threw" assertion would miss.
