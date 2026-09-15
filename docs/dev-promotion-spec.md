---
status: approved
class: elevated
---

# Spec: dev-promotion

## Intent

Replace the per-feature "two PRs to ship" branching model with a promotion
model: feature branches merge only into `dev`; `dev` is periodically merged
into `main` as a single reviewed PR, gated by a real `terraform plan`, and
that merge is the only thing that ever updates `main`. This closes the gap
where nothing runs on the PR into `main` today, and retires the now-obsolete
practice of force-pushing `dev` back to `main` to clear drift — under this
model `dev` leads and `main` follows, so that reset no longer makes sense
and is blocked structurally instead of just discouraged.

Today a feature branch is cut from `main`, opens a PR into `dev` (which
builds/tests it), merges to `dev`, then opens a **second** PR from the same
branch straight into `main`, which triggers no workflow at all before the
merge applies to prod. `dev`'s only stated purpose is a disposable preview,
reset to `main` by hand "when it gets noisy." This spec inverts that
relationship.

## Current state

- Feature branches are cut from `main`. Shipping one takes two PRs: into
  `dev`, then into `main`.
- `pr_to_dev.yml` (PR into `dev`, any source branch): a `changes` job
  path-filters on `infra/**`; `terraform-plan` (job name "Terraform plan (all
  three workspaces)") runs `terraform plan` against all three HCP workspaces
  when `infra/**` is touched; `dbt-build` (job name "dbt build into per-PR
  schemas") always runs, building into a per-PR `BRONZE_PR_<n>` schema in
  `PRE_PROD_DB`.
- `dev_merged.yml` (push to `dev`): applies `pre_prod`'s Terraform workspace
  when `infra/**` changed, then builds into the shared `PRE_PROD_DB.BRONZE`.
- `main_merged.yml` (push to `main`): applies `shared` and `prod`'s Terraform
  workspaces when `infra/**` changed, then builds into `PROD_DB.BRONZE`.
  Nothing runs on the PR that precedes this push.
- `pr_closed.yml`: drops a PR's `*_PR_<n>` schemas in `PRE_PROD_DB` when its
  PR into `dev` closes.
- Branch protection: `main` requires 1 approving review, no status checks, no
  force-push, no deletion. `dev` has no protection at all.
- The repo's merge button previously allowed squash merges; this let two
  separate merges (PR #3, PR #4) silently strand a commit each. Squash
  merging was disabled repo-wide ahead of this spec (`gh repo edit
  --enable-squash-merge=false`, 2026-09-15) since it was a plain repo setting
  unrelated to this build — merge commit and rebase remain available.

## Design

### Branching and promotion

```
main (prod)                    dev (pre-prod, now long-lived and leading)
  ▲                               ▲
  │ promotion PR, periodic        │ PR, per feature
  │ (terraform plan required)     │ (existing checks, now required)
  └─────────── dev ────────────┐  │
                                feature/x   cut from main
```

- Feature branches are still cut from `main`. Each opens exactly **one** PR,
  into `dev`. The second, direct-to-`main` PR is retired entirely — a
  feature branch never opens a PR into `main`.
- `main` is updated **only** by merging `dev` into it. There is no schedule
  or automation for this — someone decides `dev` is ready and opens the PR
  by hand, same as any other PR.
- Because `dev_merged.yml` already builds and tests every merge into `dev`
  against `PRE_PROD_DB` as normal traffic, by the time a `dev → main`
  promotion PR is opened its dbt correctness has already been proven,
  repeatedly. The promotion PR does not re-run that build. What it adds is
  the one thing the old model never had: a fresh, accurate preview of the
  Terraform diff about to apply to `shared` and `prod`.

### New workflow: PR to main

A new workflow, triggered on `pull_request` into `main` (mirroring
`pr_to_dev.yml`'s shape, not its dbt job):

- `changes`: path-filter on `infra/**`, same as the other three workflows.
- `terraform-plan`: runs when `infra/**` is touched; plans **`shared` and
  `prod`** only (not `pre_prod` — that workspace has nothing to do with what
  this merge applies). Uses the `infra` environment, same credentials and
  pattern as `pr_to_dev.yml`'s plan job.

No dbt job. dbt correctness is already covered by `dev`'s own build history,
per the reasoning above.

### Branch protection

- **`main`**: keep the existing 1-approving-review requirement, no
  force-push, no deletion. Add the new `terraform-plan` job (from "PR to
  main") as a **required** status check. A PR with no infra changes still
  merges normally — the job is skipped, and GitHub treats a skipped required
  check as satisfied.
- **`dev`** (currently unprotected): add 1 approving review, no force-push,
  no deletion, and make `pr_to_dev.yml`'s existing `dbt-build` and
  `terraform-plan` jobs required status checks. `dbt-build` always runs, so
  it's required unconditionally in practice; `terraform-plan` is
  required-but-skippable, same treatment as above.
- Blocking force-push on `dev` is what actually retires the old manual
  "reset `dev` to `main`" practice — under the new model that reset would
  throw away promotion history and fight the branch protection, not just be
  unnecessary.

### What doesn't change

`pr_to_dev.yml`, `dev_merged.yml`, `main_merged.yml`, and `pr_closed.yml`
keep their existing logic exactly as-is. This spec only adds one new
workflow, adds/changes branch protection, and removes the second per-feature
PR from the process description.

## Prerequisites

None. `dev` and `main` both already exist; no credentials or environments
need to change.

## Out of scope

- Automating *when* a promotion happens (still a manual judgment call — this
  spec only makes the PR that does it safer).
- Any change to what `dev_merged.yml` or `main_merged.yml` build or apply.
- Any change to `pr_to_dev.yml`'s build/test logic — only its two jobs
  becoming required checks is new.
- Silver/gold models, the semantic layer, the app, task scheduling — unrelated
  ongoing work.

## Dependency

Supersedes the "Branching and promotion" section and the "known limitation,
accepted" note in `docs/prod/budget-models-and-envs-spec.md` (a green `dev`
build isn't proof the `main` merge is green) — that limitation was inherent
to the *old* shape, where a feature could reach `main` without `dev` ever
seeing the promotion-time state. It doesn't fully disappear here (dbt
correctness still rides on `dev`'s history rather than being re-proven at
promotion time), but the Terraform half is now closed. That shipped spec is
left as-is per "one live file per slug" — it's the historical record of what
was built, not a document this change edits in place.

## Test plan

1. A feature PR into `dev` still runs `pr_to_dev.yml` as before; merging it
   requires 1 approval and both its checks green (or skipped, for
   `terraform-plan`).
2. A `dev → main` PR with no `infra/**` changes: the new `terraform-plan`
   check reports skipped, and the PR is mergeable once approved.
3. A `dev → main` PR with an `infra/**` change: the new `terraform-plan`
   check runs, plans `shared` and `prod`, and blocks merge until it succeeds
   (deliberately break a `.tfvars` file to prove the block, then fix it).
4. Merging that PR triggers `main_merged.yml` exactly as today — `shared`/
   `prod` apply, `PROD_DB.BRONZE` builds.
5. Attempting to force-push to `dev` is rejected by branch protection.
6. The GitHub merge button on any PR offers only "Create a merge commit" and
   "Rebase and merge" — no squash option.
7. Opening a PR from a feature branch directly into `main` is still
   *possible* (GitHub doesn't structurally prevent it), but process, not
   tooling, is what stops it — noted here rather than papered over.
