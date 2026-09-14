# budget-demo — repo map

What each top-level file and folder is for. Start here to find your way
around; the detail lives in the files themselves.

| Path | What it is |
|---|---|
| `CLAUDE.md` | The rules of this repo: content discipline, how `kb/` is used as durable memory, how the SDLC workflow is logged. The spec of authority for working here. |
| `README.md` | Human-facing overview of the dbt project, plus the **onboarding chain** — the ordered list of what a new session reads to come up to speed, and which layer answers what. |
| `sdlc/` | [states.md](sdlc/states.md) is the state machine — states and transitions. [classes.md](sdlc/classes.md) is the risk classification — which states a change visits and which need sign-off, derived from the paths it touches. One file per state's how-to — [discovery](sdlc/discovery.md), [spec](sdlc/spec.md), [plan](sdlc/plan.md), [build](sdlc/build.md), [pull-request](sdlc/pull-request.md). |
| `docs/` | Live specs and plans, one of each per feature slug (`<slug>-spec.md`, `<slug>-plan.md`). `docs/prod/` holds the spec and plan of shipped work. |
| `dbt/` | The dbt project itself — `models/staging/` and `models/marts/` (both empty), `macros/`, `tests/`, `schedules.sql` (Snowflake Tasks, uninvoked), plus `dbt_project.yml`, `profiles.yml`, and `packages.yml`. `setup/` holds leftover tutorial bootstrap SQL that is **unrunnable and must not be run** — see `README.md`. |
| `infra/` | Terraform (Snowflake provider) — the authoritative definition of the warehouse, databases, schemas, and CI service user. State is committed to the repo and written back by CI. Anything touching this path is `elevated` class. |
| `.github/` | GitHub Actions workflows: `incoming_pr.yml` runs `terraform plan` (path-filtered on `infra/**`) plus a dbt build on every PR to `main`; `pr_merged.yml` runs `terraform apply -auto-approve` on merge to `main` and commits updated state back. Terraform jobs use an RSA key pair; dbt jobs use OIDC. |
| `kb/` | This repo's long-term memory — an OKF bundle of concepts recording what past sessions established, so work isn't repeated. `observations/` holds environment and codebase facts; `kb/log.md` tracks concept changes. See "Durable memory" in `CLAUDE.md`. |
| `log.md` | Append-only record of the SDLC process itself — what was asked and what came back, interaction by interaction. |
| `refs.yaml` | Harness-level registry of key elements for this KB, keyed by slug. Read-only for agents; the user maintains it directly. Intentionally empty — this repo has no externally-grounded projects (Salesforce/Drive) to anchor, so an empty file is the expected state, not a gap to fill. |
| `index.md` | This file. |

Account-level links that don't belong to any one project go here too — add
them as they come up.
