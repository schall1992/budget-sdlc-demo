# budget-demo

Demo of AI SDLC practices, built around budget data: a budget data model, a
semantic layer, and an app on top of it.

This KB root is also a working code repo. `kb/` follows the standard OKF
format described in the harness root `CLAUDE.md`; the code sits beside it,
not inside it. Specs and plans are **not** OKF concepts — they live in
`docs/`, outside the bundle. See `index.md` for the repo layout.

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

## Durable memory: `kb/`

`kb/` is this repo's long-term memory across sessions. Anything learned that
took real effort to find out, and that a future session would otherwise have
to rediscover, gets written there as an OKF concept (format per the harness
root `CLAUDE.md`). Write it when you learn it, not at the end of the session.

What goes where:

- **Live environment facts** — what actually exists in Snowflake, which
  connection works, the real shape of a source table → `kb/observations/`
- **Why something is the way it is** — a choice the user made, and the
  reasoning behind it → `kb/decisions/`
- **A raw artifact worth keeping verbatim** → `kb/sources/`
- **People** → `kb/stakeholders/`

Notes:

- `derived_from` is optional for facts learned by inspecting the environment
  directly rather than from a document — say in the body how it was learned
  and when.
- Content discipline above applies here too: one fact in one place, short and
  plain. Never mirror into `kb/` something the code, a spec, or a plan
  already states — link to it instead.
- A contradiction between the KB and what you observe is not yours to
  reconcile. Record that the two disagree and raise it, per content
  discipline.
- Update the `index.md` of any folder touched, and prepend to `kb/log.md` —
  the bundle's own log of concept changes, distinct from the SDLC `log.md`.

## SDLC workflow

Work moves through the states and transitions defined in
[sdlc/states.md](sdlc/states.md) — that file is the authority on ordering.
Which of those states a change visits, and which need the user's sign-off,
depend on its risk class, derived from the paths it touches:
[sdlc/classes.md](sdlc/classes.md) is the authority on that. Each
`sdlc/<phase>.md` file describes how to do the work for its state; read the
relevant one before acting, but look to those two for what's allowed to
happen next.

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

- **Transition** — the state change this interaction caused (or attempted),
  per `sdlc/states.md` (e.g. `SPEC_DRAFT → SPEC_APPROVED`), or "none" if it
  didn't move the slug's state.
- **Class** — the slug's risk class per `sdlc/classes.md`, which says which
  states it skips and which gates applied. Write it as `provisional →
  effective` when a change was bumped at `PR_OPEN`.
- **Prompt** — a short paraphrase of what the user asked, not verbatim.
- **Response** — a short paraphrase of the high-level answer/outcome, not the
  full response text.
- **Files touched** — whether a file was created or edited during this
  interaction, and which one(s) (path only, no contents/diff).

Same exemption from the 50–300 line guideline, and same rotation approach, as
any other `log.md`.

Do not load `log.md` into context unless I explicitly say so
