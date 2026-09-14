---
status: approved
class: trivial
---

# Spec: doc-drift-cleanup

## Intent

A new session picking up this repo had no accurate account of its current
state. `README.md` instructed running setup scripts that are known-unrunnable
and superseded by Terraform; `index.md` omitted `infra/` entirely and
described workflows that had since changed. Nothing recorded the repo's own
shape durably — that description existed only inside live specs, which are
archived to `docs/prod/` on ship and take it with them.

Fix the drift, and give the repo a stated onboarding path.

## Changes

- **`README.md`** — replace the Quick Start's "run `dbt/setup/budget_setup.sql`"
  with the real path (infrastructure exists and is Terraform-managed). Mark
  `dbt/setup/` do-not-run, linking the drift observation. Correct the CI
  description: Terraform jobs authenticate by RSA key pair, only the dbt jobs
  use OIDC — previously documented as both OIDC. Add the **onboarding chain**
  table: the ordered layers a new session reads, what each covers, how each is
  loaded, plus the two rules worth knowing up front (state is derived, class
  is derived from paths).
- **`index.md`** — add the missing `infra/` row, flagged `elevated`. Correct
  the `docs/`, `dbt/`, and `.github/` rows. Say that `refs.yaml` being empty
  is the expected state, not a gap.
- **`kb/observations/repo-and-cicd-baseline.md`** (new) — the repo's own
  current shape: single Terraform root with committed state, `main`-only
  branching, both workflows and their two different auth mechanisms, the
  dbt-on-Snowflake execution path. Companion to `snowflake-account-baseline.md`,
  which covers Snowflake rather than the repo.
- **`kb/observations/index.md`**, **`kb/log.md`** — list and log the above.

## Paths touched

`README.md`, `index.md`, `kb/**`

All fall in the `trivial` row of [classes.md](../sdlc/classes.md). No
runtime effect; nothing downstream reads these.

`log.md` is also written, as it is for every change. It is an append-only
process record and does not participate in class derivation.
