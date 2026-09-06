# budget-demo

Demo of AI SDLC practices, built around budget data: a budget data model, a
semantic layer, and an app on top of it.

This KB root is also a working code repo — application/model/semantic-layer
code lives alongside the standard `kb/`/`refs.yaml`/`index.md` OKF scaffold
rather than in a separate location. `kb/` still follows the standard OKF
format described in the harness root `CLAUDE.md` — only the code sits beside
it, not inside it. Specs and plans are **not** OKF concepts: they live in
`docs/` at this repo's root, outside the bundle.

Nothing else client/engagement-specific has been captured yet — fill in as
it comes up (data sources, stakeholders, project scope).

## Content discipline

- **Ask, don't guess.** Whenever something isn't understood or is ambiguous
  — a term, a requirement, how a new instruction relates to what's already
  written — stop and ask the user directly rather than assuming, then write
  the answer down. This holds in every phase below; the phases don't restate
  it.
- Be hesitant to expand on things. Don't store everything discussed — only
  what's load-bearing.
- Store each piece of information once, in exactly one place. No duplicate
  copies of the same fact across concepts or files.
- Writing should be short, concise, and in simple clear language. No
  unnecessary elaboration.
- If new information is contrary to what's already stored, stop and raise it
  with the user immediately rather than silently overwriting or reconciling
  it unilaterally.
- When instructions extend or build on existing information, confirm how the
  new part relates to the original before writing, so the result stays one
  succinct statement instead of sprawl.

## SDLC workflow

All work — a feature, a fix, a change to the data model or app — moves
through these phases in order. Read the phase's file in `sdlc/` before
working it; the table is orientation, the file is the rule.

| Phase | Input | Output | Gate to exit |
|---|---|---|---|
| [Discovery](sdlc/discovery.md) | a request | feature branch off `main`; clear intent | no open gaps |
| [Spec](sdlc/spec.md) | discovery | `docs/<slug>-spec.md` | user approves the spec |
| [Plan](sdlc/plan.md) | approved spec | `docs/<slug>-plan.md` | user approves high-level, then breakdown |
| [Build](sdlc/build.md) | approved plan | code + tests on the branch | every task done, tests pass |
| [Pull request](sdlc/pull-request.md) | completed build | PR against `main` | shipped → spec+plan move to `docs/prod/` |

**Direct changes (bypassing the SDLC).** When the user explicitly asks for a
direct/quick change with no process — using a phrase like "direct change",
"skip the SDLC", or "quick fix, no process" — skip discovery/spec/plan/PR
entirely and commit straight to `main`, no feature branch. This is for early
repo setup and low-stakes fixes, not a substitute for real feature work; only
use it when the user says so explicitly, never inferred from the type of
change. Still log it in `log.md` as its own phase ("Direct"), recording the
prompt and outcome per the usual log entry fields below.

**One live file per slug.** A slug (from the Jira ticket or feature name) has
at most one spec and one plan in `docs/` at any time. Revising either means
**deleting the old file and writing a new one in its place** — never editing
in place to patch a misunderstanding, never keeping both versions. A plan is
built on a specific spec, so deleting a spec deletes its plan too; planning
restarts once the new spec is approved.

**Log.** Keep `log.md` at this repo's root, append only, recording every
interaction in this SDLC process. Log the conversation, not the code: what
was asked/said and what came back, never file contents or diffs — a spec/plan
being written or replaced still gets logged (with why — e.g. "requirement
unclear, reverted to discovery"), just not its body text, since the file
itself is the durable copy until it's deleted and replaced. This is the
durable record for reviewing later how the process actually ran, so log it
even when the doc it's about no longer exists. Distinct from `kb/log.md` (the
OKF bundle's own log of concept additions/changes, per root `CLAUDE.md`).

Each entry is one interaction (one user prompt and the response to it) and
records:

- **Phase** — the SDLC phase active during this interaction (Discovery,
  Spec, Plan, Build, Pull request).
- **Prompt** — a short paraphrase of what the user asked, not verbatim.
- **Response** — a short paraphrase of the high-level answer/outcome, not the
  full response text.
- **Files touched** — whether a file was created or edited during this
  interaction, and which one(s) (path only, no contents/diff).

Same exemption from the 50–300 line guideline, and same rotation approach, as
any other `log.md`.

Do not load `log.md` into context unless I explicitly say so
