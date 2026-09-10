# budget-demo — repo map

What each top-level file and folder is for. Start here to find your way
around; the detail lives in the files themselves.

| Path | What it is |
|---|---|
| `CLAUDE.md` | The rules of this repo: content discipline, how `kb/` is used as durable memory, the SDLC workflow table, the direct-change exception, and how to log. The spec of authority for working here. |
| `README.md` | Human-facing overview of the dbt project — what the scaffold includes, the Snowflake tutorials it was adapted from, and quick-start steps. |
| `sdlc/` | One file per SDLC phase — [discovery](sdlc/discovery.md), [spec](sdlc/spec.md), [plan](sdlc/plan.md), [build](sdlc/build.md), [pull-request](sdlc/pull-request.md). Each states its input, output, and the gate to exit. |
| `docs/` | Live specs and plans, one of each per feature slug (`<slug>-spec.md`, `<slug>-plan.md`). `docs/prod/` holds the spec and plan of shipped work. Empty of live docs today. |
| `dbt/` | The dbt project itself — `models/staging/` and `models/marts/`, `macros/`, `tests/`, `setup/` (Snowflake environment and CI/CD bootstrap SQL), `schedules.sql` (Snowflake Tasks), plus `dbt_project.yml`, `profiles.yml`, and `packages.yml`. See `README.md`. |
| `.github/` | GitHub Actions workflows: `incoming_pr.yml` builds and tests against dev on every PR, `pr_merged.yml` deploys the dbt project object to prod on merge to `main`. Both authenticate to Snowflake via OIDC. |
| `kb/` | This repo's long-term memory — an OKF bundle of concepts recording what past sessions established, so work isn't repeated. `observations/` holds environment and codebase facts; `kb/log.md` tracks concept changes. See "Durable memory" in `CLAUDE.md`. |
| `log.md` | Append-only record of the SDLC process itself — what was asked and what came back, interaction by interaction. |
| `refs.yaml` | Harness-level registry of key elements for this KB, keyed by slug. Read-only for agents; the user maintains it directly. Currently empty. |
| `index.md` | This file. |

Account-level links that don't belong to any one project go here too — add
them as they come up.
