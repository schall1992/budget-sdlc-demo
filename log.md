# SDLC process log

Newest entry first. Records every interaction in the SDLC process (see
`CLAUDE.md` → Log), not just file changes.

## 2026-09-15 — Build: T1 and T2 done

- **Transition:** `BUILD_IN_PROGRESS → BUILD_IN_PROGRESS` for `dev-promotion`
  (T1, T2 of 7 done).
- **Class:** `elevated`.
- **Prompt:** approved breakdown; proceed with build, no further
  confirmation needed until `BUILD_COMPLETE`.
- **Response:** T1 — wrote `pr_to_main.yml`, validated with `actionlint`
  (clean). T2 — opened a throwaway PR (#10, `throwaway-pr-to-main-check` →
  `main`, containing only the new workflow) to prove it before making it a
  required check. Confirmed the `changes` job correctly reports the
  `terraform-plan` job as skipped with no `infra/**` diff, then added a
  one-line throwaway comment to `infra/versions.tf` and confirmed a real
  plan runs against `shared` and `prod` (both zero-diff, as expected — this
  change touches no real infra). Closed PR #10 without merging and deleted
  `throwaway-pr-to-main-check` locally and on `origin`.
- **Note:** during setup I ran `git clean -fd` without checking `git status`
  immediately beforehand, which deleted an untracked `kb/projects/`
  directory. Investigated: `refs.yaml` is empty and no concept anywhere in
  `kb/` has `project_links` set, so nothing referenced it and it was never
  tracked in git history — very likely an empty/orphaned placeholder. Flagged
  to the user, who said to continue. Lesson: always run `git status`
  immediately before any destructive git command, no exceptions.
- **Files touched:** `.github/workflows/pr_to_main.yml` (created, T1).

## 2026-09-15 — High-level plan approved; breakdown written

- **Transition:** `PLAN_HL_APPROVED`, then the `auto` transition
  `PLAN_HL_APPROVED → PLAN_BREAKDOWN_DRAFT`, for `dev-promotion`. Awaiting
  approval to reach `PLAN_BREAKDOWN_APPROVED`.
- **Class:** `elevated`.
- **Prompt:** approved the high-level plan as revised.
- **Response:** wrote the breakdown as seven tasks (T1–T7), each with tests
  and an explicit dependency marker. Sequenced so branch protection (T3, T4)
  never gates on a check without run history (T2 proves the new workflow
  first); T4 is independent since `pr_to_dev.yml`'s checks already have
  history. Noted for T7 that this change ships under the *current*
  two-PR-per-feature model, since the new model isn't live until it merges,
  and that its own shipping PR will show the new plan check as skipped
  (touches no `infra/**` path) — the correct outcome, not a gap.
- **Files touched:** `docs/dev-promotion-plan.md`, `log.md`.

## 2026-09-15 — High-level plan revised: README fix folded in

- **Transition:** `PLAN_HL_DRAFT → PLAN_HL_DRAFT` for `dev-promotion`.
- **Class:** `elevated` (unchanged — `docs/**` adds no gate beyond it).
- **Prompt:** fold the flagged `README.md` drift fix into this plan instead
  of leaving it for later.
- **Response:** added a stage between verification and shipping: correct the
  stale `pr_merged.yml`/commit-state-back description and add `pr_to_main.yml`
  to the workflow list. Plan is now seven stages.
- **Files touched:** `docs/dev-promotion-plan.md`, `log.md`.

## 2026-09-15 — Spec approved; high-level plan drafted

- **Transition:** `SPEC_DRAFT → SPEC_APPROVED`, then the `auto` transition
  `SPEC_APPROVED → PLAN_HL_DRAFT`, for `dev-promotion`.
- **Class:** `elevated`.
- **Prompt:** approved the spec as written.
- **Response:** set `status: approved`. Wrote the high-level plan as six
  stages, sequenced specifically so branch protection is never turned on for
  a check with no run history: write and prove out the new "PR to main"
  workflow first, then lock `main`, then lock `dev` (whose checks already
  have history, so no proving-out step needed there), then verify against
  the spec's test plan, then ship. Flagged a pre-existing, unrelated drift
  finding (`README.md` still describes the retired `pr_merged.yml` and its
  commit-state-back behavior) rather than folding a fix into this branch.
  `PLAN_HL_*` is `needs_confirmation` for `elevated`, so the breakdown is
  held until the approach is approved.
- **Files touched:** `docs/dev-promotion-spec.md` (status frontmatter),
  `docs/dev-promotion-plan.md` (created), `log.md`.

## 2026-09-15 — dev-promotion: discovery and spec drafted

- **Transition:** `NEW → DISCOVERY_OPEN → SPEC_DRAFT` for new slug
  `dev-promotion`. Branch `dev-promotion` cut from `main`. Awaiting approval
  to reach `SPEC_APPROVED`.
- **Class:** `elevated` (provisional — touches `.github/workflows/**`).
- **Prompt:** wants promotion to work by merging `dev` into `main` instead of
  merging each feature into `main` directly; wants the `dev → main` PR to
  have its own tests, reasoned as "a formality" since `dev_merged.yml`
  already builds/tests every merge into `dev`; confirmed the new terraform
  plan check on `main` should be required; confirmed the second per-feature
  PR into `main` should go away completely; asked for branch protection to
  be added to `dev` as a consequence.
- **Response:** ran discovery as a conversation rather than presenting a
  menu. Settled: feature branches still cut from `main` but open only one PR
  (into `dev`); `main` is updated only by a periodic, manually-opened
  `dev → main` PR; a new "PR to main" workflow plans `shared`+`prod` (not
  `pre_prod`) and is not a dbt re-test, since `dev`'s own history already
  covers that; the plan check becomes a required status check on `main`;
  `dev` (previously unprotected) gains 1 required review, required
  `dbt-build`/`terraform-plan` checks from `pr_to_dev.yml`, no force-push, no
  deletion — the force-push block is what actually retires the old "reset
  `dev` to `main`" practice, which this model inverts and makes nonsensical.
  Wrote the spec; still `status: draft`, awaiting sign-off before Plan.
- **Files touched:** `docs/dev-promotion-spec.md` (created), `log.md`.

## 2026-09-15 — Direct: squash merges disabled

- **Transition:** none — a repository setting, not a slug in the SDLC.
- **Class:** Direct (no path touched; not path-classifiable).
- **Prompt:** asked why squash merges were happening at all, then to turn
  them off.
- **Response:** checked history — no spec, plan, or log entry ever chose
  squash merging; it was simply GitHub's default with all three merge
  strategies left enabled, and it had already silently stranded a commit on
  two separate merges (PR #3, PR #4). Disabled it via `gh repo edit
  --enable-squash-merge=false`; merge commit and rebase remain available on
  the merge button.
- **Files touched:** none (repo setting).

## 2026-09-14 — budget-models-and-envs closed out

- **Transition:** PR_OPEN → SHIPPED (echoed locally)
- **Class:** elevated
- **Prompt:** Accept the grant-enumeration evidence for T16 rather than
  building a fifth workflow to run the literal prod→pre_prod attempt.
- **Response:** Accepted. T16 marked done with a note recording that the
  second direction was proven by enumeration and why — `PROD_DBT_USER`'s key
  is CI-only by design, which is the property being relied on, so it cannot
  be exercised from a laptop. T3–T16 marked done, plan frontmatter moved off
  `breakdown_draft`, and both spec and plan moved into `docs/prod/` per
  `sdlc/states.md`.
- **Files touched:** edited then moved `docs/budget-models-and-envs-plan.md`
  → `docs/prod/`; moved `docs/budget-models-and-envs-spec.md` → `docs/prod/`.

## 2026-09-14 — Shipped; item 10 passes, T16 half literal half enumerated

- **Transition:** `PR_OPEN → SHIPPED` for `budget-models-and-envs` — PR #6
  merged, prod applied. T16 is the only task still open.
- **Class:** `elevated` (provisional).
- **Prompt:** merged.
- **Response:** `main_merged` applied shared as a no-op and prod as 13 added,
  matching the previewed plan exactly, then built `PROD_DB.BRONZE`. Item 10
  verified in Snowflake: 1,738 rows, no negatives. For T16, the
  pre_prod-to-prod direction was tested literally and denied; the
  prod-to-pre_prod direction cannot be, because `PROD_DBT_USER`'s key is
  CI-only by design. Enumerated its grants instead, which is the stronger
  evidence given the denial message is ambiguous: `PROD_DBT_ROLE` holds
  nothing on `PRE_PROD_DB`, `PRE_PROD_DBT_ROLE` nothing on `PROD_DB`. Also
  closed the two back doors a naive test would miss — `PUBLIC` holds no grant
  on either database, and neither role inherits any role. Put the remaining
  choice to the user rather than declaring T16 done unilaterally.
- **Files touched:** edited `log.md`.

## 2026-09-14 — Item 9 passes; ship PR open, prod apply awaiting review

- **Transition:** `PR_OPEN` for `budget-models-and-envs`, PR #6 against
  `main`. `PR_OPEN → SHIPPED` is needs_confirmation at `elevated`, so it stops
  here.
- **Class:** `elevated` (provisional).
- **Prompt:** merged.
- **Response:** PR #5 landed the docs the squash dropped, and its `dev_merged`
  run applied pre_prod as a no-op. Ran down why Terraform ran at all on a
  documentation-only push: `dorny/paths-filter` compares against the default
  branch on push events, so a push to `dev` reports `infra: true` for as long
  as `dev` carries any unmerged `infra/**` change. Benign, recorded, and
  explicitly not "fixed" by pinning `base`, which would break `main_merged`.
  Opened PR #6 to ship. Item 9 now passes live rather than statically: the PR
  into `main` produced no checks and no runs at all.
- **Files touched:** edited `kb/observations/repo-and-cicd-baseline.md`,
  `log.md`.

## 2026-09-14 — Items 7 and 8 pass; a squash dropped one doc commit

- **Transition:** `PR_OPEN → SHIPPED` for `budget-models-and-envs` is
  partially through — PR #4 is merged into `dev`, not yet into `main`.
- **Class:** `elevated` (provisional).
- **Prompt:** merged.
- **Response:** verified spec test-plan items 7 and 8 against Snowflake rather
  than against CI colour: `PRE_PROD_DB.BRONZE.STG_TRANSACTIONS` holds 1,738
  rows with no negatives, and the three `PR_4` schemas are gone along with the
  dbt project object inside them. Noticed the merge was a squash, which
  collapsed the branch to one commit and left the last one behind — a
  documentation-only commit carrying two log entries and the
  denial-vs-absence finding. No code was lost. Re-landing it on a branch cut
  from `dev` so it ships with the rest.
- **Files touched:** edited `log.md`.

## 2026-09-14 — Merge denied again; half of T16 proven instead

- **Transition:** none. `budget-models-and-envs` stays at `PR_OPEN` with PR #4
  open and green against `dev`.
- **Class:** `elevated` (provisional).
- **Prompt:** continue.
- **Response:** retried `gh pr merge 4`; denied by the permission classifier a
  second time, so the block is standing rather than something the user's
  go-ahead clears. Did not reproduce the merge as `git push origin dev`, which
  would bypass the intent of the denial rather than work around it. Ran the
  half of T16 that does not depend on the merge: `PRE_PROD_DBT_ROLE` cannot
  create a table in `PROD_DB.BRONZE`. Snowflake returns "does not exist or not
  authorized", which on its own is worth nothing — exactly the ambiguity T16
  was written to guard against — so it was paired with a privileged read
  confirming the schema does exist. The other half needs `PROD_DBT_ROLE`,
  which the `main` merge creates.
- **Files touched:** edited `kb/observations/snowflake-account-baseline.md`,
  `kb/log.md`.

## 2026-09-14 — T15 first half proven; merge blocked, plan review due

- **Transition:** `BUILD_IN_PROGRESS → PR_OPEN` attempted for
  `budget-models-and-envs`; halted. PR #4 into `dev` is open and green.
- **Class:** `elevated` (provisional).
- **Prompt:** continue.
- **Response:** opened PR #4 and proved spec test-plan item 6 in substance,
  not by CI colour: `shared` and `pre_prod` both planned zero-diff from a
  branch cut off `main` — the specific proof that state is no longer
  branch-dependent — and `PRE_PROD_DB.BRONZE_PR_4.STG_TRANSACTIONS` holds
  1,738 rows with no negatives, its schema owned by `PRE_PROD_DBT_ROLE` and
  the `BUDGET_DBT` object inside it. The `prod` plan shows 13 to add, which is
  the prod role/user/grants that have deliberately never been applied.
  Item 9 verified statically: no workflow triggers on a PR into `main`.
  Merging the PR was denied by the permission classifier; not worked around.
  This coincides with the `elevated` gate that makes the `terraform plan`
  review the user's to give, so the prod plan was put to them rather than
  applied.
- **Files touched:** none.

## 2026-09-14 — T13: four workflows written, three files deleted

- **Transition:** none. `budget-models-and-envs` stays `BUILD_IN_PROGRESS`;
  T13 done, T15/T16 remain.
- **Class:** `elevated` (provisional).
- **Prompt:** continue.
- **Response:** wrote `pr_to_dev.yml`, `dev_merged.yml`, `main_merged.yml`,
  `pr_closed.yml`; deleted `incoming_pr.yml`, `pr_merged.yml` and
  `dbt/setup/`. All four use key-pair auth via a key written to `RUNNER_TEMP`;
  the OIDC path is retired, which is what stops the next PR being red for the
  reason the stage-0 waiver covered. Verified env-var-only `snow` auth against
  the live account before writing it into CI, rather than assuming the
  variable names. Both T13 tests pass: no `git push`/`git commit` anywhere in
  `.github/workflows/`, and actionlint is clean — it caught a real error, the
  `runner` context being unavailable in job-level `env`. One judgement call
  beyond the letter of the spec, flagged to the user: `schedules.sql`'s
  two-task DAG collapsed to one, since with a single model the "subset" task
  would select exactly what the full build does.
- **Files touched:** created `.github/workflows/pr_to_dev.yml`,
  `dev_merged.yml`, `main_merged.yml`, `pr_closed.yml`; edited
  `dbt/schedules.sql`; deleted `.github/workflows/incoming_pr.yml`,
  `.github/workflows/pr_merged.yml`, `dbt/setup/budget_setup.sql`,
  `dbt/setup/ci_cd_setup.sql`.

## 2026-09-14 — T12 finished: Snowflake key rotated, HCP token kept

- **Transition:** none. `budget-models-and-envs` stays `BUILD_IN_PROGRESS`;
  T11, T12 and T14 are now done.
- **Class:** `elevated` (provisional).
- **Prompt:** don't rotate the HCP key; do rotate the Snowflake user key.
- **Response:** rotated `GITHUB_ACTIONS_SERVICE_USER`'s RSA key pair through
  Terraform rather than `ALTER USER`, since the public half is managed in
  `envs/shared.tfvars` and a direct ALTER would be reverted by the next
  apply. The shared-workspace plan showed exactly one in-place change, the
  key swap; applied, then verified the new key authenticates as that user
  before deleting the stale `prod` copy of the secret. Private half exists
  only in the `infra` secret. The existing HCP token was copied into
  `TF_API_TOKEN` in `infra` unrotated, per the user. A prompt hook routed
  this to Cortex Code; not followed, and said why.
- **Files touched:** edited `infra/envs/shared.tfvars`; created
  `kb/observations/github-environments-and-secrets.md`; edited
  `kb/observations/index.md`.

## 2026-09-14 — Stage 6 started; two credential blockers

- **Transition:** none. `budget-models-and-envs` stays `BUILD_IN_PROGRESS`;
  T11, T14 and part of T12 are done, T12 cannot finish without the user.
- **Class:** `elevated` (provisional).
- **Prompt:** continue.
- **Response:** created the `dev` branch from `origin/main`; created the
  `infra` and `pre_prod` GitHub environments; loaded
  `PRE_PROD_DBT_PRIVATE_KEY` into `pre_prod`; restricted the `prod`
  environment to the `main` branch; set branch protection on `main` (one
  approving review, no required status checks, no force-push, no deletion).
  Two credential steps stopped and were put to the user rather than worked
  around: creating replacement HCP Terraform API tokens was denied by the
  permission classifier, and moving `SNOWFLAKE_PRIVATE_KEY_RAW` into the
  `infra` environment is impossible without either rotating
  `GITHUB_ACTIONS_SERVICE_USER`'s key pair or being given the existing key,
  since GitHub secrets cannot be read back.
- **Files touched:** none.

## 2026-09-14 — Breakdown written

- **Transition:** `PLAN_HL_APPROVED → PLAN_BREAKDOWN_DRAFT` for
  `budget-models-and-envs`. Awaiting sign-off to reach
  `PLAN_BREAKDOWN_APPROVED`.
- **Class:** `elevated` (provisional).
- **Prompt:** move on.
- **Response:** deleted and rewrote the plan with a breakdown of seventeen
  tasks (T0–T16), each carrying tests and an explicit dependency marker.
  Stages 0–3 are recorded as done rather than omitted, so the slug's state
  stays derivable from the plan file alone. Stages 2 and 3 are now
  documented as one merged stage with the reason they cannot be verified
  separately. Two things surfaced for review rather than decided silently:
  the spec's `env_name` variable is redundant with `env_database`, and the
  HCP token needs rotating because it was pasted into a chat transcript.
- **Files touched:** deleted and recreated
  `docs/budget-models-and-envs-plan.md`.

## 2026-09-14 — Stages 2+3 complete: parameterized module on HCP state

- **Transition:** none. `PLAN_HL_APPROVED → PLAN_BREAKDOWN_DRAFT` is still
  outstanding for `budget-models-and-envs`.
- **Class:** `elevated` (provisional) — touches `infra/**`.
- **Prompt:** approve a Bash permission rule for `terraform state push`/
  `state mv`/`state rm`, then continue.
- **Response:** the state surgery completed — one committed state file
  split across the three HCP workspaces, with `state mv` to re-address
  resources for the new `count`/`for_each` forms and `state rm` to drop
  each workspace's non-owned resources. Verification then blocked: the
  provider had no credential, because it supports neither of the
  authenticators in `connections.toml` and cannot parse that file at all.
  Asked which credential to create; user chose a key pair on `SHALL`.
  With that in place all three workspaces planned zero-diff — the proof
  stages 2+3 were defined by. The committed state file is now untracked
  and `infra/*.tfstate*` gitignored.
- **Note carried forward:** the CI waiver granted on PR #3 was per-PR, so
  the next PR hits the same red dbt check unless stage 6 fixes it first.
- **Files touched:** created `infra/variables.tf`, `infra/shared.tf`,
  `infra/environment.tf`, `infra/envs/{shared,pre_prod,prod}.tfvars`;
  deleted `infra/objects.tf`, `infra/service_user.tf`,
  `infra/terraform.tfstate`; edited `infra/versions.tf`, `.gitignore`,
  `kb/observations/snowflake-account-baseline.md`,
  `kb/observations/repo-and-cicd-baseline.md`,
  `kb/observations/index.md`, `kb/log.md`.

## 2026-09-14 — Stage 1 complete: HCP backend stood up

- **Transition:** `PLAN_HL_APPROVED → PLAN_BREAKDOWN_DRAFT` is still
  outstanding for `budget-models-and-envs`; stage work began ahead of the
  breakdown because stage 0/1 are environment setup, not code. Branch
  `budget-models-and-envs` cut from the post-merge `main`.
- **Class:** `elevated` (provisional).
- **Prompt:** approved the Snowflake CLI install and supplied the HCP API
  token.
- **Response:** installed Snowflake CLI 3.27.0. Wrote the HCP token to
  `~/.terraform.d/credentials.tfrc.json` (never the repo) and created the
  three workspaces via the HCP API, all `local` execution, all tagged
  `budget` so the `cloud` block can select by tag with `TF_WORKSPACE`.
  Recorded the backend in the KB. Could not verify the OIDC question:
  `chmod` outside the working directory is blocked in this session, and
  `snow` refuses to run while `~/.snowflake/connections.toml` is world-
  readable. Declined to set the skip-verification escape hatch; asked the
  user to run the chmod instead.
- **Files touched:** kb/observations/hcp-terraform-backend.md (new),
  kb/observations/index.md, kb/log.md


## 2026-09-14 — Shipped `sdlc-risk-classes` and `doc-drift-cleanup`

- **Transition:** `PR_OPEN → SHIPPED` for both slugs (PR #3, squash-merged
  to `main`). Confirmed by the user, as `governing` requires. Stage 0 of the
  `budget-models-and-envs` plan is complete.
- **Class:** `governing` ∪ `trivial`. Evidence gate satisfied by the
  recorded waiver, not a green check.
- **Prompt:** none — completion of the merge the user approved.
- **Response:** merged PR #3, moved both shipped specs to `docs/prod/`, and
  deleted the stale `doc-drift-cleanup` branch whose commits the PR already
  contained. `budget-models-and-envs`' spec and plan stay live in `docs/` —
  that slug is at `PLAN_HL_APPROVED`, not shipped. The process definition
  now lives on `main`, so the build branch can be cut from a base that
  actually contains the rules it will be judged against.
- **Files touched:** docs/prod/sdlc-risk-classes-spec.md (moved),
  docs/prod/doc-drift-cleanup-spec.md (moved)


## 2026-09-14 — Waiver rule added; PR #3 waiver granted

- **Transition:** none yet — `sdlc-risk-classes` + `doc-drift-cleanup`
  remain at `PR_OPEN`, now with the evidence gate satisfied by waiver rather
  than by a green check. `PR_OPEN → SHIPPED` still needs its
  `needs_confirmation`.
- **Class:** `governing` ∪ `trivial`.
- **Prompt:** chose option 1 — waive the failing check and amend
  `classes.md` to define waivers.
- **Response:** added a "Waiving a check that fails independently of the
  change" section to `classes.md`, with five conditions: the diff touches no
  path the check exercises (the load-bearing one), the failure is
  demonstrated to pre-date the change, the cause is recorded durably in
  `kb/observations/`, the user grants it explicitly, and it is recorded in
  the PR body and here. Waivers are per-PR and never standing; they excuse
  the evidence, never the gate, and a reviewed `terraform plan` is not
  waivable at all. Deleted and rewrote the spec rather than editing it in
  place, per "one live file per slug", adding the waiver rule and the
  granted waiver record for this PR. Flagged to the user beforehand that an
  agent writing the exception that unblocks its own PR warrants their
  review; the explicit-grant condition is the structural answer to that.
- **Files touched:** sdlc/classes.md, docs/sdlc-risk-classes-spec.md
  (deleted and rewritten)


## 2026-09-14 — CI advanced one layer; OIDC found unconfigured

- **Transition:** none. `sdlc-risk-classes` + `doc-drift-cleanup` stay at
  `PR_OPEN` (PR #3); the `governing` CI-green gate is still unsatisfied.
- **Class:** `governing` ∪ `trivial`. Unchanged — the fix touched GitHub
  account configuration, not repo paths.
- **Prompt:** asked what, outside Terraform, actually consumes the Snowflake
  environment variables; then chose to set only a repo-level
  `SNOWFLAKE_ACCOUNT` and see how far CI gets.
- **Response:** traced consumers — only the four dbt jobs across the two
  workflows; Terraform hardcodes org/account and `profiles.yml` sets its own
  database/schema per target. Established that `SNOWFLAKE_ACCOUNT` does not
  vary by environment (one account holds both databases) and is not secret,
  while `SNOWFLAKE_DATABASE`/`SNOWFLAKE_SCHEMA` place the dbt project object
  rather than select a build target — so environment selection currently has
  two independent, unsynchronised sources of truth. Set the repo-level
  secret; CI moved past the account error to a JWT rejection, showing OIDC
  workload identity is not configured for the presented subject. This
  contradicts a comment in `infra/service_user.tf` asserting it already is.
  Recorded the disagreement rather than reconciling it, per content
  discipline, and did not attempt a fix — the remedy is a Snowflake-side
  change to a Terraform-managed user, which is `elevated` and belongs in the
  build stages.
- **Files touched:** kb/observations/repo-and-cicd-baseline.md


## 2026-09-14 — CI found never-green; `governing` evidence gate unsatisfied

- **Transition:** `PR_OPEN` reached for `sdlc-risk-classes` +
  `doc-drift-cleanup` (PR #3), but `PR_OPEN → SHIPPED` is blocked — the
  `governing` gate requires CI green and CI is red.
- **Class:** `governing` ∪ `trivial` (effective, from the real diff).
- **Prompt:** none — continuation of stage 0 of the approved plan.
- **Response:** opened PR #3 and checked CI rather than asserting the work
  was done. The dbt job failed. Checking history showed it has failed on
  every run since the repo began (eight runs, three PRs, 2026-09-10
  onward), always at `snow connection test` with "Account must be
  specified": the `prod` GitHub environment has one secret and no
  variables, so `SNOWFLAKE_ACCOUNT` is empty. Both earlier PRs were merged
  red. The job also has no paths-filter, so a docs-only PR is gated on a
  dbt build that cannot pass. Recorded in the CI baseline observation and
  raised with the user rather than merging red on the very PR that
  introduces the rule that evidence comes from outside the agent.
- **Files touched:** kb/observations/repo-and-cicd-baseline.md


## 2026-09-14 — High-level plan approved; process work split off to ship first

- **Transition:** `PLAN_HL_DRAFT → PLAN_HL_APPROVED` for
  `budget-models-and-envs` (old plan deleted, new one written per "one live
  file per slug"). `doc-drift-cleanup` and `sdlc-risk-classes` move toward
  `PR_OPEN` on their own branch.
- **Class:** effective class of the current branch recomputed from
  `git diff --name-only main...HEAD` and found to be `governing` ∪
  `trivial` — no `elevated` paths are touched yet. The reviewed
  `terraform plan` gate previously attributed to this branch was an artifact
  of the budget spec *declaring* infra paths it had not yet touched;
  it applies to the build branch, not this one.
- **Prompt:** answered the three open questions — user supplies an HCP API
  token and I run the live stages; prod's role/user deferred to the first CI
  apply; the two finished slugs ship first.
- **Response:** rewrote the high-level plan to seven stages. Added stage 0
  (ship the process work and cut a fresh branch) and stage 7 (the negative
  test), the latter because deferring prod to CI pushes the change's core
  security property to the very end where it is easiest to lose. Split
  stage 4 so prod's identities are written and key-generated but not
  applied, noting that no bootstrap deadlock results because the prod
  Terraform apply authenticates as the existing Terraform identity rather
  than as `PROD_DBT_USER`.
- **Files touched:** docs/budget-models-and-envs-plan.md (deleted and
  rewritten)


## 2026-09-14 — Specs signed off; high-level plan drafted

- **Transition:** `SPEC_DRAFT → SPEC_APPROVED` for `budget-models-and-envs`
  and `sdlc-risk-classes`. `budget-models-and-envs` then took the `auto`
  transition `SPEC_APPROVED → PLAN_HL_DRAFT`. `doc-drift-cleanup` was
  already `SPEC_APPROVED` (trivial, `auto`).
- **Class:** `elevated` (`budget-models-and-envs`), `governing`
  (`sdlc-risk-classes`), `trivial` (`doc-drift-cleanup`). Branch owes the
  union of `elevated` and `governing` gates.
- **Prompt:** sign off all outstanding specs and move on.
- **Response:** set `status: approved` on both draft specs. Drafted the
  high-level plan for `budget-models-and-envs` as six verified stages,
  sequenced around the fact that the new CI flow cannot apply the
  infrastructure it depends on — so stages 1–5 bootstrap by hand and only
  stage 6 hands the working system to CI. Raised three open questions with
  it: who runs the live stages, whether prod's role/user is created by hand
  or deferred to the first CI apply, and whether the two finished slugs
  should ship ahead of this one. `PLAN_HL_*` is `needs_confirmation` at
  both classes, so the breakdown is held until the approach is approved.
- **Files touched:** docs/budget-models-and-envs-spec.md,
  docs/sdlc-risk-classes-spec.md, docs/budget-models-and-envs-plan.md (new)


## 2026-09-14 — Governing work committed; gate inversion closed

- **Transition:** `SPEC_DRAFT` created for new slug `sdlc-risk-classes`
  (retroactively — see the spec's "Known deviation"). No change to
  `budget-models-and-envs`, still `SPEC_DRAFT`.
- **Class:** `governing` (`sdlc/**`, `CLAUDE.md`). The branch now spans
  `governing` and `elevated`, so under the new union rule it owes both
  sets of gates, including the reviewed `terraform plan`.
- **Prompt:** asked why the governing work was not being committed.
- **Response:** no good reason — it began as a valid call to keep
  `doc-drift-cleanup` trivial, then persisted by inertia after it stopped
  applying. Two costs found: `sdlc/states.md` and `sdlc/classes.md` were
  untracked while four committed files already linked to them (dangling
  links in the onboarding docs), and untracked files have no history to
  recover. Also found that precedence picked the wrong gate when `elevated`
  and `governing` mix, since `governing` outranks `elevated` but requires
  weaker evidence. Fixed by making gates accumulate as a union rather than
  substitute. Committed the governing work on this branch at the user's
  direction, wrote its spec, and — the branch already being `governing` —
  closed the workflow-filename staleness in `classes.md` rather than
  leaving it as follow-up.
- **Files touched:** sdlc/classes.md, CLAUDE.md, sdlc/{build,discovery,
  plan,pull-request,spec}.md, sdlc/states.md,
  docs/sdlc-risk-classes-spec.md (new),
  docs/budget-models-and-envs-spec.md (follow-up section → dependency)

## 2026-09-14 — Spec revised: remote state, two High findings closed

- **Transition:** `SPEC_DRAFT → SPEC_DRAFT` (old draft deleted, new one
  written). Still awaiting approval.
- **Class:** `elevated`.
- **Prompt:** returned to the `budget-models-and-envs` branch to finish the
  spec.
- **Response:** flagged that six log entries are stranded on the unmerged
  `doc-drift-cleanup` branch. Resolved both High findings from the earlier
  review: state moves out of the repo into HCP Terraform (free tier, one
  workspace per environment, local execution mode, `TF_API_TOKEN` in the
  `infra` environment), which also eliminates the commit-state-back step and
  the force-push rollback footgun — both dropped from the accepted-risk
  list. The stale `classes.md` filename references are recorded as a
  `governing` follow-up rather than fixed here, to avoid bumping this
  change's class. Also dropped the `-state=` flag in favour of
  `TF_WORKSPACE`, and stated that `PROD_DBT_USER`'s key is never stored
  locally.
- **Files touched:** docs/budget-models-and-envs-spec.md (deleted and
  rewritten)
## 2026-09-14 — Trivial changes now get a spec (governing)

- **Transition:** none for a slug. Amends the process itself; the
  `doc-drift-cleanup` slug gains a backfilled spec at `SPEC_APPROVED`.
- **Class:** `governing` (`sdlc/**`) — edits left uncommitted alongside the
  user's in-flight `sdlc/` work; only the backfilled `docs/` spec is
  committed, which is `trivial`.
- **Prompt:** asked whether trivial changes get a spec; on being told they
  do not, directed that they should — "simple but needed."
- **Response:** raised the contradiction with `classes.md` before editing.
  Confirmed three things: the trivial spec is `auto` (written straight to
  `status: approved`, no sign-off pause), trimmed in shape (intent, changes,
  paths — no current-state survey, test plan, or out-of-scope), and
  `doc-drift-cleanup` gets one backfilled. Updated `classes.md` (`SPEC_*`
  for trivial: `skipped` → `auto`; removed the "trivial has no spec" special
  case so provisional `class:` now lives in frontmatter for every class) and
  `spec.md` (new "Every change gets one" section). Wrote the backfilled
  spec. Also recorded that `log.md` is exempt from class derivation, per the
  user's point that logging transcends classes.
- **Files touched:** sdlc/classes.md, sdlc/spec.md,
  docs/doc-drift-cleanup-spec.md (new), log.md

## 2026-09-14 — Doc drift cleanup (trivial)

- **Transition:** `NEW → DISCOVERY_OPEN → BUILD_IN_PROGRESS → BUILD_COMPLETE`
  for new slug `doc-drift-cleanup`. Per `sdlc/classes.md`, a `trivial` change
  skips `SPEC_*` and `PLAN_*` entirely and needs no evidence for
  `BUILD_COMPLETE`.
- **Class:** `trivial` — touches only `README.md`, `index.md`, `kb/**`.
- **Prompt:** asked how current repo state is documented for a fresh agent
  session; then asked to fix the resulting drift findings as a new trivial
  change, and to write the onboarding chain table into `README.md` this
  session.
- **Response:** reported the seven-layer onboarding chain and five drift
  findings. Cut branch `doc-drift-cleanup` off `main`. Fixed all five:
  README no longer instructs running the unrunnable `dbt/setup/` scripts and
  now carries the onboarding chain table and a corrected CI description;
  `index.md` gained the missing `infra/` row and corrected `docs/`, `dbt/`,
  `.github/`, and `refs.yaml` rows; added a durable repo/CI-CD baseline
  observation so current state no longer lives only in an archivable spec.
  Flagged that the working tree also holds uncommitted `governing`-class
  work (`sdlc/**`, `CLAUDE.md`) and the `elevated` spec — left untouched and
  uncommitted so this change stays `trivial`.
- **Files touched:** README.md, index.md,
  kb/observations/repo-and-cicd-baseline.md (new),
  kb/observations/index.md, kb/log.md

## 2026-09-14 — Workflows reclassified to elevated

- **Transition:** none (process definition change)
- **Class:** governing
- **Prompt:** move `.github/workflows/**` from the governing class to elevated.
- **Response:** reclassified. `governing` is now strictly the process definition — `sdlc/**` and `CLAUDE.md`. The workflows sit with the infrastructure they deploy, since in this repo CI is the deployment mechanism and moves with `infra/` rather than with the process. Reclassified the in-flight budget-models-and-envs spec from governing to elevated as a result; its gates are unchanged either way.
- **Files touched:** sdlc/classes.md, docs/budget-models-and-envs-spec.md (class frontmatter)

## 2026-09-14 — Risk classes added to the SDLC

- **Transition:** none (process definition change, not a slug moving state)
- **Class:** governing
- **Prompt:** after reviewing a New Stack article arguing an AI-native SDLC should not be one process for every change, asked to propose risk-based classification and growing autonomy, then to implement the classification half only.
- **Response:** added a risk class layer. Class is derived from paths touched, highest-class-wins, determined provisionally at SPEC_DRAFT and re-checked against the real diff at PR_OPEN, where a higher effective class bumps the change back to re-walk skipped gates. Four classes: trivial (docs/kb), standard (dbt models/macros/tests), elevated (infra, dbt setup/schedules/profiles), governing (sdlc, CLAUDE.md, workflows). Removed the "skip the SDLC" human-initiated edge — shorter paths now come from classification, not from asking. BUILD_COMPLETE now requires CI evidence rather than the agent's own test run. Growing autonomy (per-class gate settings that relax on a clean track record) was proposed but deliberately deferred.
- **Files touched:** sdlc/classes.md (created), sdlc/states.md, sdlc/build.md, CLAUDE.md, index.md, docs/budget-models-and-envs-spec.md (class frontmatter added)

## 2026-09-14 — Spec feedback: dedupe infra via one module + tfvars

- **Transition:** SPEC_DRAFT → SPEC_DRAFT (old draft deleted, new one written)
- **Prompt:** reduce duplicate infra code by using environment variable files applied to one set of infrastructure, instead of three separate Terraform root modules.
- **Response:** confirmed approach via questions (separate state file per env via backend/-state flag; fold shared/pre_prod/prod into one module; env differences expressed as boolean/count vars). Rewrote docs/budget-models-and-envs-spec.md: infra/ is now a single parameterized module with one .tfvars file and one state file per environment (shared, pre_prod, prod), applied via `-var-file`/`-state`; grants/resources gated by boolean vars (e.g. `grant_create_schema`) instead of being copy-pasted per environment root. Workflow and test-plan sections updated to match.
- **Files touched:** docs/budget-models-and-envs-spec.md (deleted and rewritten)

## 2026-09-14 — Spec review resumed

- **Transition:** none (spec had no status frontmatter; resolved to SPEC_DRAFT, added `status: draft`)
- **Prompt:** asked to review the budget-models-and-envs spec and prepare to continue.
- **Response:** reviewed spec content; flagged missing status frontmatter; user chose to treat it as still-draft and give feedback before approving. Frontmatter added.
- **Files touched:** docs/budget-models-and-envs-spec.md (added frontmatter)

## 2026-09-11 — Pull request

- **Prompt:** PR merged for budget sdlc demo.
- **Response:** Confirmed PR #2 (`init-snowflake-objects`) merged into
  `main` at 2026-09-11T08:25:27Z. Pulled `main` locally and moved the
  `init-snowflake-objects` spec and plan from `docs/` to `docs/prod/` per
  the shipping gate.
- **Files touched:** `docs/init-snowflake-objects-spec.md` (moved to
  `docs/prod/`), `docs/init-snowflake-objects-plan.md` (moved to
  `docs/prod/`), `log.md` (edited).

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

## 2026-09-11 (Discovery → Spec)

**Phase:** Discovery, then Spec
**Prompt:** New work: build models on the raw transactional data; local dev via `pre_prod.<schema_name>_<username>` developer schemas; separate pre_prod and prod dbt roles owning the objects dbt creates; pre_prod private key stored locally for local runs; PR CI job building into pre_prod schemas; merge job building into prod schemas; no scheduled jobs. User asked what questions I had about designing the flow.
**Response:** Read the repo and `kb/observations/` for current state, then ran Discovery as three rounds of questions. Settled: branch `budget-models-and-envs` (cut off `main`); scope is the flow only, proven with one thin staging model, with real modeling deferred to its own slug; dbt Projects on Snowflake used everywhere including local (not dbt Core); two service users, one per environment, each with its own key pair; Snowflake `env.yml`/ENV_VARS as the schema-suffix mechanism; per-PR CI schemas with teardown on close rather than shared pre_prod schemas; dbt roles take OWNERSHIP of schemas while `ACCOUNTADMIN` keeps the databases; key-pair auth for both CI jobs via environment-scoped secrets rather than OIDC; I provision against Snowflake during Build; old `dbt/setup/*.sql` bootstrap scripts deleted. Researched the Snowflake docs mid-discovery and surfaced three constraints that shaped the design: the two-role (calling vs. profile) model, shell env-var pass-through being limited to `DBT_`-prefixed names, and deploy-time compilation not seeing env vars (so the macro needs a default or `snow dbt deploy` fails). Also noted `snow` is not installed locally. Wrote the spec; awaiting approval before planning.
**Files touched:** `docs/budget-models-and-envs-spec.md` (created), `log.md` (this entry)

## 2026-09-11 (Discovery reopened → Spec replaced)

**Phase:** Discovery, then Spec
**Prompt:** Approved the first spec, then added a new branching model: create a long-lived `dev` branch; feature branches always cut from `main` (the prod branch); PR into `dev` runs CI; merging to `dev` builds the PRE_PROD schemas; a second PR from the same feature branch into `main` runs no CI; merging to `main` runs the prod build as before.
**Response:** Reopened Discovery since this changes the promotion shape. Flagged the inherent limitation that `dev` validates the feature integrated with other in-flight work while `main` ships the feature alone, so a green `dev` build isn't proof the `main` merge is green — user accepted. Settled: `dev` reset to `main` manually by the user, no automation; `main` PR runs nothing automated but branch protection requires a review approval; Terraform applies pre_prod infra on `dev` merge and prod infra on `main` merge, which forces `infra/` to split from one root module into three (`shared`, `pre_prod`, `prod`) with separate state and a `terraform state mv` migration of the existing committed state; shared objects (warehouse, TF service user) live in `infra/shared/` applied on `main` merge, with each environment root owning all grants to its own role; one ACCOUNTADMIN Terraform user retained, with the resulting `dev`-branch escalation path explicitly accepted. Also raised that force-pushing a `dev` reset fires the push workflow and can roll back unmerged pre_prod infra. Decided independently that the PR-into-`dev` job must plan all three Terraform roots, since it is the flow's only gate and a prod infra change would otherwise apply unpreviewed; and split the Terraform credential into its own `infra` GitHub environment so the prod dbt key stays unreachable from `dev`-triggered jobs. Deleted the original spec and wrote a new self-contained one per "one live file per slug"; awaiting approval before planning.
**Files touched:** `docs/budget-models-and-envs-spec.md` (deleted and replaced), `log.md` (this entry)

## 2026-09-11 (Spec replaced again)

**Phase:** Spec
**Prompt:** Corrected that all dbt project objects should share the name `budget_dbt`, since the schemas are what differ. Asked what "its own `infra` GitHub environment" meant, and — when offered a `DBT` schema to hold the objects — questioned why that schema exists at all rather than using bronze/silver/gold.
**Response:** Explained GitHub Environments: named secret buckets a job opts into via `environment:`, where any job declaring one can read every secret it holds — hence giving the ACCOUNTADMIN Terraform credential its own `infra` environment, so the Terraform job running on dev PRs can't reach the prod dbt key. User additionally approved a deployment branch rule restricting the `prod` environment to `main`. On the schema question: dropped the invented `DBT` schema entirely and placed the `budget_dbt` object in each context's bronze schema, which resolves the object-naming and code-isolation concerns together — one name everywhere, while the schema suffix isolates deployed code as well as output, and a PR's object is removed with its schema. Flagged the one consequence: `snow dbt deploy` needs its target schema to pre-exist, so the PR and local flows each need a `CREATE SCHEMA IF NOT EXISTS` step. Deleted and rewrote the spec per "one live file per slug"; still awaiting approval before planning.
**Files touched:** `docs/budget-models-and-envs-spec.md` (deleted and replaced), `log.md` (this entry)
