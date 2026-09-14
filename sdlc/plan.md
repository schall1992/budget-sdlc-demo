# Phase: Plan

States `PLAN_HL_DRAFT`/`PLAN_HL_APPROVED`/`PLAN_BREAKDOWN_DRAFT`/
`PLAN_BREAKDOWN_APPROVED` — see [states.md](states.md) for the gates between
these. Output is `docs/<feature-slug>-plan.md`, paired one-to-one with that
slug's spec, carrying a `status:` frontmatter line matching the current
state.

Design an implementation from the spec: inspect it, work out an approach, and
surface every ambiguity to the user as a question — this phase is as
collaborative as discovery.

A plan has two parts: a **high-level plan** (the overall approach) and a
**breakdown** (the concrete steps/tasks to execute it). Don't produce the
breakdown until the high-level approach is approved.

Every task in the breakdown carries two things:

- **Tests/evals** — what that task needs to verify. Test scope is decided
  here, during planning, not improvised during build (see `build.md` for the
  bar those tests have to meet).
- **Dependencies** — an explicit `depends on: <task ids>`, or `independent`
  if it has none. This marker is the only thing Build reads to decide what
  may run in parallel, so every task needs one.

Plans are open to iteration — expect to revise them as the user gives
feedback. Each revision follows "One live file per slug" in the root
`CLAUDE.md`, as does the deletion of a plan whose spec was replaced.
