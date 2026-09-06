# Phase: Pull request

**In:** a completed build. **Out:** a PR against `main`. **Gate:** the change
ships — at which point that slug's spec and plan move to `docs/prod/`.

After every task for the plan is complete, push the feature branch created
back in discovery to GitHub and open a PR against `main`. The PR description
should give a high-level overview of the code changes — what was built and
why, not a line-by-line diff recap.

**Shipping to production.** When a change tied to a spec lands in production
— inferred from repo signals (a merge to `main`, a release tag, a CI/CD
deploy pipeline run for that change), not from being told — move both that
slug's spec *and* plan from `docs/` to `docs/prod/` together, as the paired
record of what shipped. This is what protects shipped docs from being
overwritten by a later discovery/spec/plan cycle on the same slug — if you're
unsure whether a given signal really means production, ask rather than moving
it prematurely.
