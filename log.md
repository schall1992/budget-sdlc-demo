# SDLC process log

Newest entry first. Records every interaction in the SDLC process (see
`CLAUDE.md` → Log), not just file changes.

## 2026-09-10 — Pull request

- **Prompt:** Open the PR for init-snowflake-objects against main.
- **Response:** Committed all 15 changed files (including new
  `infra/objects.tf`, spec, plan, updated dbt config, setup SQL comments,
  KB observations, terraform state). Added `terraform.tfstate.backup` to
  `.gitignore`. Pushed to `origin/init-snowflake-objects` and opened PR #2
  with a summary of what changed and a test plan. Note on merge: terraform
  apply will fire but should be a no-op since objects already exist.
- **Files touched:** `.gitignore` (edited), `log.md` (edited). PR #2
  opened at https://github.com/schall1992/budget-sdlc-demo/pull/2.

## 2026-09-10 — Build

- **Prompt:** Start Build — execute T1 through T9, including terraform apply.
- **Response:** Executed all 9 tasks. Wrote `infra/objects.tf` (9 resources),
  added `default_warehouse` to `service_user.tf`. Authenticated Terraform
  locally using the same temp-key-on-SHALL approach as the previous build
  (generated temp RSA key pair, set on SHALL, ran plan/apply, unset key,
  deleted key files). Plan showed 9 to add + 1 to change + 0 to destroy;
  apply succeeded. Verified all objects exist via SQL. Updated
  `profiles.yml` (dev→PRE_PROD_DB, prod→PROD_DB, warehouse→analysis_wh),
  `dbt_project.yml` (staging→bronze, marts→gold). Added superseded comments
  to `budget_setup.sql` and `ci_cd_setup.sql`. Updated both KB observations
  and their index. All "done when" criteria from the spec are met.
- **Files touched:** `infra/objects.tf` (created), `infra/service_user.tf`
  (edited), `infra/terraform.tfstate` (updated by apply),
  `dbt/profiles.yml` (edited), `dbt/dbt_project.yml` (edited),
  `dbt/setup/budget_setup.sql` (edited), `dbt/setup/ci_cd_setup.sql`
  (edited), `kb/observations/snowflake-account-baseline.md` (edited),
  `kb/observations/dbt-scaffold-drift.md` (edited),
  `kb/observations/index.md` (edited), `kb/log.md` (edited), `log.md`
  (edited).

## 2026-09-10 — Plan

- **Prompt:** High-level plan approved; write the breakdown.
- **Response:** Wrote `docs/init-snowflake-objects-plan.md` with 9 tasks:
  T1 write `objects.tf`, T2 update `service_user.tf`, T3 plan, T4 apply,
  T5 update `profiles.yml`, T6 update `dbt_project.yml`, T7 superseded
  comments on setup SQL, T8 update account-baseline observation, T9 update
  scaffold-drift observation. Presented for approval.
- **Files touched:** `docs/init-snowflake-objects-plan.md` (created),
  `log.md` (edited).

## 2026-09-10 — Spec

- **Prompt:** Rename warehouse from `BUDGET_DBT_WH` to `ANALYSIS_WH` in the
  spec; no other changes.
- **Response:** Updated all 4 references in
  `docs/init-snowflake-objects-spec.md` (object table, TF resource name,
  default_warehouse section, profiles.yml note). Re-presented for approval.
- **Files touched:** `docs/init-snowflake-objects-spec.md` (edited),
  `log.md` (edited).

## 2026-09-10 — Spec

- **Prompt:** Write and present the spec for `init-snowflake-objects`.
- **Response:** Wrote `docs/init-snowflake-objects-spec.md` covering: TF
  resources for `BUDGET_DBT_WH`, `PRE_PROD_DB` (bronze/silver/gold),
  `PROD_DB` (bronze/silver/gold); `dbt/profiles.yml` and `dbt_project.yml`
  updates to target the new databases/schemas; reconciliation of
  `budget_setup.sql`, `ci_cd_setup.sql`, and two KB observations that
  contradict the new object model. Presented for approval.
- **Files touched:** `docs/init-snowflake-objects-spec.md` (created),
  `log.md` (edited).

## 2026-09-10 — Discovery

- **Prompt:** Start building environment config and Snowflake objects infra.
  Branch: `init-snowflake-objects`. Scope: warehouse + database/schemas as
  Terraform resources. User directed a medallion architecture replacing the
  old `budget_dbt_db` design: `PRE_PROD_DB` and `PROD_DB`, each with
  `bronze`, `silver`, `gold` schemas.
- **Response:** Created branch `init-snowflake-objects` off `main`. Verified
  live account state (no `budget_dbt_wh`, no `budget_dbt_db`). Researched
  TF provider docs for `snowflake_warehouse`, `snowflake_database`,
  `snowflake_schema` — all stable in ~2.20. Flagged contradictions with
  `budget_setup.sql`, `ci_cd_setup.sql`, `profiles.yml`,
  `dbt-scaffold-drift.md`, and `snowflake-account-baseline.md`. Resolved
  the `budget_dbt_db.raw` vs `SOURCE_DB` question (no raw schema in new
  model). User included `profiles.yml`/`dbt_project.yml` updates in scope.
  Discovery closed.
- **Files touched:** `log.md` (edited).

## 2026-09-10 — Spec

- **Prompt:** Insisted the service user be created right now via Cortex,
  reasoning Terraform can't run without it.
- **Response:** Corrected the premise: the spec's bootstrap `terraform
  apply` is designed to create the user itself (run locally as the human
  identity), not to require it beforehand — nothing was actually blocked.
  User chose to hand-create it anyway, accepting that Terraform will later
  need to `import` rather than create this user. Created
  `github_actions_service_user` via Cortex (`sam_test` account):
  `DEFAULT_ROLE = ACCOUNTADMIN`, OIDC workload identity for
  `repo:schall1992/budget-sdlc-demo:environment:prod`, and an RSA key pair
  (private key handed to the user for a GitHub Actions secret, not
  retained). Logged as a new Observation in `kb/`, per this repo's
  live-environment-facts convention; the spec itself is unchanged (still
  pending approval) since the object created matches what it already
  describes.
- **Files touched:**
  `kb/observations/github-actions-service-user-bootstrap.md` (created),
  `kb/observations/snowflake-account-baseline.md` (edited),
  `kb/observations/index.md` (edited), `kb/log.md` (edited), `log.md`
  (edited).

## 2026-09-10 — Spec

- **Prompt:** Asked me to save the private key as a GitHub Actions secret.
- **Response:** `gh` CLI wasn't installed; installed it via Homebrew and
  walked the user through the browser device-auth flow. Discovered the
  `prod` GitHub environment (which the spec assumes exists for both this
  secret and the OIDC subject) didn't exist yet, so created it, then set
  `SNOWFLAKE_PRIVATE_KEY_RAW` on it via `gh secret set` and deleted the
  local scratch copy of the key. Updated the KB observation to record where
  the key now lives instead of just that it was handed off.
- **Files touched:**
  `kb/observations/github-actions-service-user-bootstrap.md` (edited),
  `kb/log.md` (edited), `log.md` (edited).

## 2026-09-10 — Spec

- **Prompt:** Asked me to create the Snowflake service account for CI/CD
  manually via Cortex, outside Terraform, as a one-time setup, with a single
  account used for both GitHub Actions and Terraform CI, at ACCOUNTADMIN.
- **Response:** Flagged that this conflicted with the approved-pending spec
  (two separate service users, both created by the Terraform bootstrap
  apply — not hand-created). User asked why the split existed; the real
  reason was auth method (Terraform provider lacks OIDC support), not
  permissions — so a single user with two auth methods (OIDC + key pair)
  works. User chose that option. Rewrote
  `docs/init-snowflake-infra-spec.md` (deleted and replaced, per "one live
  file per slug") to merge `github_actions_service_user` and
  `terraform_service_user` into one user with both auth methods attached;
  updated the bootstrap, CI/CD lifecycle, and GitHub repo config sections
  to match. Re-presented for approval; the one-time manual
  Cortex-outside-Terraform creation was not done, since it still conflicts
  with the spec's Terraform-managed bootstrap approach.
- **Files touched:** `docs/init-snowflake-infra-spec.md` (deleted and
  recreated), `log.md` (edited).

## 2026-09-10 — Spec

- **Prompt:** Wanted new Snowflake infra managed via Terraform in an
  `infra/` folder, with GitHub workflows running its plan/apply lifecycle,
  instead of the hand-run SQL scripts the prior spec assumed.
- **Response:** Reopened spec before approval (not a full discovery
  reopen). Researched two real constraints: Terraform has no native
  Snowflake state backend, and the Snowflake Terraform provider doesn't yet
  support OIDC auth. Resolved via questions: provider is
  `snowflakedb/snowflake`; state is local and committed to git (no
  locking); a new key-pair-authenticated `terraform_service_user` runs
  Terraform in CI (separate from the OIDC `github_actions_service_user`
  used by dbt workflows); `budget_setup.sql`/`ci_cd_setup.sql` are fully
  replaced and deleted. Rewrote
  `docs/init-snowflake-infra-spec.md` (deleted and replaced, per "one live
  file per slug") to describe the Terraform-managed infra, the bootstrap
  problem, and the new `infra_pr.yml`/`infra_merged.yml` workflows;
  presented for approval.
- **Files touched:** `docs/init-snowflake-infra-spec.md` (deleted and
  recreated), `log.md` (edited).

## 2026-09-10 — Spec

- **Prompt:** Requested a feature to configure CI/CD and init the Snowflake
  infra for this repo.
- **Response:** Branch `init-snowflake-infra` created off `main`. Resolved
  open gaps from `kb/observations/`: target account is `sam_test`; raw data
  source is `SOURCE_DB.RAW.TRANSACTIONS` directly (no project-owned copy);
  CI/CD keeps `ACCOUNTADMIN`; network policy allows only the GitHub Actions
  global rule. Wrote `docs/init-snowflake-infra-spec.md` covering setup
  script fixes, source config fix, GitHub repo env/secrets, and running the
  setup scripts; presented for approval.
- **Files touched:** `docs/init-snowflake-infra-spec.md` (created), `log.md`
  (edited).

## 2026-09-10 — Direct

- **Prompt:** Asked whether anything in `CLAUDE.md` could be removed now that
  `index.md` is populated; approved the changes I proposed.
- **Response:** Assessed both files. Most of the new duplication was in
  `index.md`, not `CLAUDE.md`. Deleted the stale "nothing else has been
  captured yet" note from `CLAUDE.md` (superseded by the Durable memory
  section) and trimmed its opening to keep only the two real constraints —
  `kb/` follows OKF, specs/plans are not concepts — pointing at `index.md` for
  layout. Thinned the `sdlc/`, `docs/`, and `log.md` rows in `index.md` to
  drop rules that belong in `CLAUDE.md`. Direct change.
- **Files touched:** `CLAUDE.md` (edited), `index.md` (edited), `log.md`
  (edited).

## 2026-09-10 — Direct

- **Prompt:** Update the root `index.md` to list and describe the project's
  top-level files and folders.
- **Response:** Rewrote it as a repo map — a table covering `CLAUDE.md`,
  `README.md`, `sdlc/`, `docs/`, `dbt/`, `.github/`, `kb/`, `log.md`,
  `refs.yaml`, and itself, one sentence each with detail left to the files
  themselves. Kept a closing line preserving the harness convention that
  account-level links live here. Treated as a Direct change (docs/orientation,
  not feature work).
- **Files touched:** `index.md` (edited), `log.md` (edited).

## 2026-09-10 — Direct

- **Prompt:** Started a session with "let's start on a project"; I ran ahead
  and interrogated the repo and the live Snowflake account, then presented
  batched multiple-choice decisions. User stopped me: when `docs/` is empty I
  should simply ask what we're working on, cut a branch, and enter discovery
  from there. Also asked that anything worth keeping be documented into `kb/`
  as long-term memory so future sessions don't repeat work.
- **Response:** Rewrote the entry rules in `sdlc/discovery.md` (ask plainly
  when starting from nothing; ask openly, one thing at a time; read `kb/`
  during discovery) and added a "Durable memory: `kb/`" section to
  `CLAUDE.md`. Landed the two findings from the live probe as Observation
  concepts rather than losing them. Treated as a Direct change since it's
  process/instruction setup, not feature work. No feature branch cut yet —
  discovery has not started.
- **Files touched:** `sdlc/discovery.md` (edited), `CLAUDE.md` (edited),
  `kb/observations/snowflake-account-baseline.md` (created),
  `kb/observations/dbt-scaffold-drift.md` (created),
  `kb/observations/index.md` (created), `kb/log.md` (created),
  `kb/index.md` (edited), `log.md` (edited).

## 2026-09-06 — Direct

- **Prompt:** Add `SOURCE.RAW.TRANSACTIONS` as the primary dbt source for the
  project; also asked to document a direct-change bypass of the SDLC for
  early repo setup.
- **Response:** Added a "Direct changes (bypassing the SDLC)" exception to
  `CLAUDE.md`, then declared `SOURCE.RAW.TRANSACTIONS` as source `raw.transactions`
  in `__sources.yml`, straight to `main` per the new exception.
- **Files touched:** `CLAUDE.md` (edited), `dbt/models/staging/__sources.yml`
  (edited).

## 2026-09-10 — Spec

- **Prompt:** After reviewing the `init-snowflake-infra` spec, said they
  don't want any Snowflake objects created yet with this spec — just set up
  the ability to do that. Clarified, when asked how far "ability" should go,
  that the service user is already bootstrapped by hand, so no bootstrap
  apply is needed either.
- **Response:** Deleted and rewrote `docs/init-snowflake-infra-spec.md`:
  scope is now writing the Terraform code and CI/CD workflows only —
  `terraform import` for the existing service user, no `terraform apply`
  against the account, and no merge of any PR touching `infra/`. Added an
  explicit "Done when" line confirming the account gains no new objects.
  Awaiting the user's approval of the revised spec before moving to Plan.
- **Files touched:** `docs/init-snowflake-infra-spec.md` (deleted and
  recreated), `log.md` (edited).

## 2026-09-10 — Spec

- **Prompt:** Asked whether `terraform apply` would be a no-op given
  nothing exists yet — clarified that apply is never a no-op for resources
  that don't exist, only `plan`/`import` are safe. Then asked whether the
  network policy needs to be hand-applied first so the GitHub service user
  can access Snowflake, and said not to create a warehouse or database yet
  for this spec either. When asked whether warehouse/database should still
  get Terraform code written (just unapplied) or be dropped from this
  spec's code entirely, chose to drop them entirely.
- **Response:** Explained network policies are an allow-list, not an access
  prerequisite — the existing dbt workflows already authenticate via OIDC
  without one, so it's not blocking. Deleted and rewrote
  `docs/init-snowflake-infra-spec.md` again: warehouse/database removed
  from scope entirely (code and apply both deferred to a future spec);
  this spec's Terraform code is now just the GitHub API integration,
  network policy, and the imported service user, still with no apply and
  no PR merge. Also un-scoped deleting the old setup SQL scripts, since
  they reference the warehouse/database this spec no longer touches.
  Awaiting the user's approval of the revised spec before moving to Plan.
- **Files touched:** `docs/init-snowflake-infra-spec.md` (deleted and
  recreated), `log.md` (edited).

## 2026-09-10 — Spec

- **Prompt:** Asked why the API integration / network policy are needed
  given GitHub Actions already works with Snowflake. Confirmed they do
  want the Snowsight git-workspace feature (the API integration), but don't
  need the network policy.
- **Response:** Explained the API integration and the existing OIDC auth
  serve opposite directions (Snowsight-to-GitHub vs. GitHub-to-Snowflake)
  and are unrelated. Deleted and rewrote `docs/init-snowflake-infra-spec.md`
  again: network policy dropped from scope entirely (not deferred — just
  not planned), API integration kept as the one new capability this spec
  delivers. Scope is now just the GitHub API integration (unapplied) plus
  the imported service user. Awaiting the user's approval of the revised
  spec before moving to Plan.
- **Files touched:** `docs/init-snowflake-infra-spec.md` (deleted and
  recreated), `log.md` (edited).

## 2026-09-10 — Spec/Plan

- **Prompt:** During Plan, said they were skeptical the Snowsight git
  connection was actually needed and asked for research before breaking
  the plan into tasks. After research showed the git-flavored API
  integration is a preview/unstable resource in the Terraform provider,
  chose to drop the whole Snowsight git-workspace feature.
- **Response:** Researched the Terraform resources a Snowsight git
  connection actually needs (secret + git-specific API integration +
  git_repository object) via the provider's GitHub docs — found the API
  integration piece is preview-only and explicitly unstable. Presented
  that tradeoff; user dropped it. Deleted and rewrote
  `docs/init-snowflake-infra-spec.md` once more: this spec now introduces
  zero new Snowflake objects — its only content is importing the existing
  service user and standing up the Terraform/CI pipeline, expected to show
  a clean/empty `terraform plan`. Reverted to Spec phase for re-approval
  before resuming Plan's breakdown step.
- **Files touched:** `docs/init-snowflake-infra-spec.md` (deleted and
  recreated), `log.md` (edited).

## 2026-09-10 — Plan

- **Prompt:** Approved the simplified high-level plan and said to move
  forward with planning (i.e., produce the breakdown).
- **Response:** Wrote `docs/init-snowflake-infra-plan.md` with the
  high-level approach and an 8-task breakdown (scaffold infra/, write and
  import the service user resource, the two new CI workflows plus the
  needs: wiring, the __sources.yml fix, and a throwaway PR to prove
  infra_pr.yml posts a zero-diff plan). Flagged for later: shipping this
  feature's own PR will touch infra/ and trigger infra_merged.yml on
  merge, which is fine since the plan is zero-diff, but worth
  re-confirming right before that merge. Awaiting approval of the
  breakdown before Build starts.
- **Files touched:** `docs/init-snowflake-infra-plan.md` (created),
  `log.md` (edited).

## 2026-09-10 — Build

- **Prompt:** Continue Build for init-snowflake-infra: scaffold infra/, write the github_actions_service_user resource, import it, and reconcile to a zero-diff plan (T1-T3).
- **Response:** Installed Terraform CLI (not previously present) via Homebrew. Retrieved the live RSA public key via read-only SQL (DESC USER) through the cortex CLI. Wrote infra/versions.tf, provider.tf, service_user.tf; terraform init/validate passed. Discovered the working sam_test CLI session (OAuth authorization-code) can't be reused by the Terraform provider, and the service user's own private key isn't retrievable (GitHub secrets are write-only) — resolved by generating a temporary RSA key pair, setting it on SHALL via ALTER USER (live write to an existing object, user-approved), running the import/plan through it, then unsetting the key and deleting the local key files immediately after. Iterated the resource config (explicit disabled/display_name/login_name/default_secondary_roles_option, plus lifecycle ignore_changes on default_workload_identity/mins_to_unlock/days_to_expiry/show_output) until terraform plan showed "No changes."
- **Files touched:** infra/versions.tf (created), infra/provider.tf (created), infra/service_user.tf (created), infra/terraform.tfstate and .terraform.lock.hcl (created by init/import).

## 2026-09-10 — Build

- **Prompt:** Continue Build for init-snowflake-infra: T4-T7 (CI plan/apply workflows, needs: wiring, __sources.yml fix).
- **Response:** Discovered the plan's T6 (needs: from a standalone infra_merged.yml onto pr_merged.yml) is impossible — GitHub Actions needs: can't cross workflow files. Flagged it; user directed deleting the standalone infra_pr.yml/infra_merged.yml and instead folding terraform plan/apply as new jobs directly into the existing incoming_pr.yml and pr_merged.yml, gated by a dorny/paths-filter changes job so they only run when infra/ is touched. Added terraform-plan job to incoming_pr.yml (independent of the dbt job) and terraform-apply job to pr_merged.yml, with the existing dbt job now needs: [changes, terraform-apply] and an if guard allowing it to proceed whether terraform-apply ran or was skipped. Both files validated as parseable YAML. Fixed dbt/models/staging/__sources.yml to point at SOURCE_DB instead of the nonexistent SOURCE database.
- **Files touched:** .github/workflows/incoming_pr.yml (edited), .github/workflows/pr_merged.yml (edited), dbt/models/staging/__sources.yml (edited). infra_pr.yml/infra_merged.yml created then deleted.

## 2026-09-10 (Build, continued)

**Phase:** Build (T8)
**Prompt:** Continue T8 — diagnose why terraform-plan failed in CI with "asn1: syntax error: data truncated" against the SNOWFLAKE_PRIVATE_KEY_RAW secret, given the user confirmed the value should be raw PEM text as-is.
**Response:** Added a non-content-revealing debug step (byte length/line count/marker counts) to isolate the cause without exposing secret content. Diagnostic (1508 bytes) compared against a freshly-generated reference PKCS8 key (1704 bytes) confirmed the stored secret was genuinely truncated, not a formatting mismatch. With user approval, regenerated the GITHUB_ACTIONS_SERVICE_USER key pair: set the new public key on the live user via ALTER USER (read/write via cortex-router), re-set SNOWFLAKE_PRIVATE_KEY_RAW via gh secret set, updated infra/service_user.tf's rsa_public_key to match, and removed the debug step. Re-ran CI: key parsing succeeded but surfaced a second, unrelated pre-existing gap — ACCOUNTADMIN was never actually granted to the service user despite being its default_role. With user approval, granted ACCOUNTADMIN to GITHUB_ACTIONS_SERVICE_USER via a live SQL GRANT. Re-ran CI again: terraform-plan succeeded with "No changes. Your infrastructure matches the configuration." — a genuine zero-diff plan on PR #1. Confirmed the unrelated `Run on Incoming PR` dbt job failure (empty SNOWFLAKE_ACCOUNT secret) is pre-existing and out of scope for this feature. Build phase (T1-T8) is complete; PR #1 remains open and unmerged per spec.
**Files touched:** `infra/service_user.tf` (edited — new rsa_public_key), `.github/workflows/incoming_pr.yml` (edited — added then removed debug step), `log.md` (this entry)

## 2026-09-10 (Pull request)

**Phase:** Pull request
**Prompt:** Answered two clarifying questions about the shipped workflow design (why pr_merged.yml deploys a Snowflake dbt project object; whether Terraform should manage that) — concluded no, dbt deploy is content-push CI/CD, not Terraform's job. User then asked to split incoming_pr.yml/pr_merged.yml back into separate per-purpose files; raised that this reintroduces the cross-file `needs:` ordering problem and offered two resolutions (workflow_run chaining vs. dropping ordering) — user declined to decide now and said to proceed to the next phase instead.
**Response:** Moved to the Pull Request phase. PR #1 (already open from Build) was already the branch's PR against `main`; updated its description to check off the now-completed test-plan items (local zero-diff plan, CI zero-diff plan) and added a summary line about the key regeneration/ACCOUNTADMIN grant. PR remains open and unmerged per the spec — merging (shipping) and the resulting docs/ → docs/prod/ move are still pending, deferred to the user's call. The workflow-file-splitting question remains open/unresolved.
**Files touched:** none (repo files) — PR #1 description updated on GitHub; `log.md` (this entry)

## 2026-09-10 (Pull request, shipped)

**Phase:** Pull request
**Prompt:** "merge it!" — user directed merging PR #1 despite the spec's original intent not to merge as part of proving the pipeline (their explicit call to make).
**Response:** Attempted to merge via `gh pr merge`; blocked by the environment's own permission classifier as too high-impact to automate, so surfaced this to the user and asked them to merge manually. User merged PR #1 (commit `47b327f`) themselves and confirmed. Verified the resulting `pr_merged.yml` CI run: `terraform-apply` succeeded with "0 added, 0 changed, 0 destroyed" (a genuine no-op, as expected since the resource was already fully imported); the `Run on Accepted PR` dbt job failed on the same pre-existing, out-of-scope `SNOWFLAKE_ACCOUNT` secret issue noted during Build. Per the shipping gate in `sdlc/pull-request.md`, moved `docs/init-snowflake-infra-spec.md` and `docs/init-snowflake-infra-plan.md` to `docs/prod/` directly on `main`.
**Files touched:** `docs/prod/init-snowflake-infra-spec.md` (moved), `docs/prod/init-snowflake-infra-plan.md` (moved), `log.md` (this entry)
