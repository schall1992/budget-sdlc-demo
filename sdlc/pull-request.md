# Phase: Pull request

States `PR_OPEN`/`SHIPPED` — see [states.md](states.md) for the gates in and
out of these states.

After every task for the plan is complete, push the feature branch created
back in discovery to GitHub and open a PR against `main`. The PR description
should give a high-level overview of the code changes — what was built and
why, not a line-by-line diff recap.

**Shipping to production.** A merge to `main`, a release tag, or a CI/CD
deploy pipeline run for this change all count as the shipped signal (see
states.md for when that's auto vs. needs confirmation). Once shipped, move
both that slug's spec *and* plan from `docs/` to `docs/prod/` together, as
the paired record of what shipped — this is what protects shipped docs from
being overwritten by a later discovery/spec/plan cycle on the same slug.
