---
status: breakdown_approved
class: elevated
---

# Plan: dev-promotion

## High-level approach

Sequenced so branch protection is never turned on for a check that hasn't
run yet — a required status check with no history for a PR blocks that PR
forever, so the new workflow has to exist and prove itself before either
branch gets locked down.

1. **Write the new workflow.** Add `.github/workflows/pr_to_main.yml`:
   `pull_request` into `main`, `infra/**` path-filter, `terraform-plan`
   plans `shared` and `prod` (not `pre_prod`) via the `infra` environment —
   same credential pattern as `pr_to_dev.yml`'s plan job, just the two
   workspaces this merge actually applies.
2. **Prove it runs.** Open a throwaway PR into `main` (no real change) and
   confirm the job appears, runs, and reports a real result (skipped when no
   `infra/**` diff, a real plan when there is one) before it becomes a
   branch-protection requirement.
3. **Protect `main`.** Add the "PR to main" `terraform-plan` job as a
   required status check, keeping the existing 1-approving-review
   requirement, no force-push, no deletion.
4. **Protect `dev`** (currently unprotected): 1 approving review, required
   `dbt-build` and `terraform-plan` checks from the existing `pr_to_dev.yml`,
   no force-push, no deletion. These checks already have run history, so no
   throwaway-PR step is needed here.
5. **Verify end to end** against the spec's test plan: a no-infra `dev →
   main` PR merges cleanly with the plan check skipped; an infra-touching
   one blocks until the plan succeeds; merging still triggers
   `main_merged.yml` unchanged; force-push to `dev` is rejected; the merge
   button offers no squash option; a feature PR into `dev` still passes as
   before under `dev`'s new protection.
6. **Fix the `README.md` drift.** Correct the stale description of
   `pr_merged.yml` (superseded by `main_merged.yml`) and its commit-state-back
   behavior (superseded by the HCP remote-state move), and add the new
   `pr_to_main.yml` to the workflow list. Pre-existing drift, unrelated to
   this change's own scope, but `docs/**` is `trivial` and folding it in adds
   no gates beyond what `elevated` already requires.
7. **Ship.** Move this spec and plan to `docs/prod/` per the shipping gate.

## Open questions

None outstanding — discovery settled the design; this plan just sequences
it safely.

## Breakdown

**T1 — Write `pr_to_main.yml`.** `pull_request` into `main`; `changes` job
path-filters `infra/**` (same pattern as the other three workflows);
`terraform-plan` job plans `shared` and `prod` only, via the `infra`
environment, same credential shape as `pr_to_dev.yml`'s plan job.
- Tests: `actionlint` clean; triggers only on `pull_request` → `main`; job
  plans exactly `shared` and `prod` (not `pre_prod`).
- `independent`

**T2 — Prove the workflow on a throwaway PR.** Open a no-op PR into `main`
and confirm the job appears and reports correctly: skipped when the PR
touches no `infra/**` path, a real plan when it does (a second throwaway
touching an `infra/` file, reverted after).
- Tests: check run named per the job's `name:` appears in the PR's checks;
  reports `skipped` on the no-op PR, a real plan result on the infra-touching
  one.
- `depends on: T1`

**T3 — Protect `main`.** Add the "PR to main" `terraform-plan` job as a
required status check via `gh api`/branch protection settings. Keep the
existing 1-approving-review requirement, no force-push, no deletion.
- Tests: `gh api repos/.../branches/main/protection` shows the new required
  check by name, plus the unchanged review/force-push/deletion settings.
- `depends on: T2` (a required check needs run history to be selectable, and
  this shouldn't gate on an unproven job)

**T4 — Protect `dev`.** Add branch protection for the first time: 1
approving review, required `dbt-build` and `terraform-plan` checks from the
existing `pr_to_dev.yml`, no force-push, no deletion.
- Tests: `gh api repos/.../branches/dev/protection` reflects these settings;
  a direct `git push --force` to `dev` is rejected.
- `independent` (these checks already have run history from existing traffic)

**T5 — Verify end to end against the spec's test plan.** With T3 and T4 live:
a `dev → main` PR with no `infra/**` diff merges cleanly (plan check
skipped); one with an `infra/**` diff is blocked until the plan succeeds
(prove the block with a deliberately broken `.tfvars`, then fix it); merging
still triggers `main_merged.yml` unchanged; a feature PR into `dev` still
passes under `dev`'s new protection; the merge button offers no squash
option anywhere in the repo (already repo-wide, but confirmed here too).
- Tests: all of the above, observed directly rather than asserted.
- `depends on: T3, T4`

**T6 — Fix the `README.md` drift.** Replace the stale `pr_merged.yml`
description (superseded by `main_merged.yml`) and its commit-state-back
claim (superseded by the HCP remote-state move) with accurate text, and add
`pr_to_main.yml` to the workflow list.
- Tests: `README.md` no longer names `pr_merged.yml` or describes committing
  state back; `pr_to_main.yml` is listed and described accurately.
- `independent`

**T7 — Ship.** This change itself ships under the *current* (pre-this-spec)
two-PR model, since the new model isn't live until it merges: PR into `dev`,
merge, PR into `main`, merge. Move `docs/dev-promotion-spec.md` and
`docs/dev-promotion-plan.md` to `docs/prod/` per the shipping gate. Note for
the evidence gate: this change touches no `infra/**` path itself, so
`pr_to_main.yml`'s plan job is expected to report skipped on its own
shipping PR — that's the correct outcome, not a gap.
- Tests: PR checks green, both merges complete, spec/plan live in
  `docs/prod/`.
- `depends on: T5, T6`
