# SDLC states and transitions

Work is tracked per slug (branch/feature name), not globally — several slugs
can sit in different states at once. This file is the authority on what
state a slug is in and what can happen next. The phase files
(`discovery.md`, `spec.md`, `plan.md`, `build.md`, `pull-request.md`)
describe *how* to do the work once you're in a given state — they don't
govern ordering; this file does.

Which states a slug visits, and which of them need the user's go-ahead,
depend on its **risk class** — see [classes.md](classes.md), the authority
on classification and on every gate that varies by class.

**Resolving current state:** check, in order, whether `docs/<slug>-spec.md`
and `docs/<slug>-plan.md` exist, each file's `status:` frontmatter, per-task
status inside the plan's breakdown, and git/GitHub state (branch, PR,
merge). No state ever needs to be asked about — it's always derivable from
these. Class is likewise derived, from the paths the change touches.

## States

| State | Meaning | Recorded as |
|---|---|---|
| `NEW` | request received, nothing started | no branch/docs yet |
| `DISCOVERY_OPEN` | branch cut, intent being clarified | branch exists, no spec file |
| `SPEC_DRAFT` | spec written, not approved | spec file, `status: draft` |
| `SPEC_APPROVED` | spec approved | spec file, `status: approved` |
| `PLAN_HL_DRAFT` | high-level plan written, not approved | plan file, `status: hl_draft` |
| `PLAN_HL_APPROVED` | high-level approach approved | plan file, `status: hl_approved` |
| `PLAN_BREAKDOWN_DRAFT` | breakdown written, not approved | plan file, `status: breakdown_draft` |
| `PLAN_BREAKDOWN_APPROVED` | full plan approved, ready to build | plan file, `status: breakdown_approved` |
| `BUILD_IN_PROGRESS` | some breakdown tasks done | per-task status in the plan file |
| `BUILD_COMPLETE` | all tasks done, tests pass | all tasks marked done |
| `PR_OPEN` | PR open against `main` | GitHub state |
| `SHIPPED` | merged/tagged/deployed | GitHub state; echoed locally by spec+plan moving to `docs/prod/` |

## Transitions

| From → To | Trigger condition | Autonomy |
|---|---|---|
| `NEW → DISCOVERY_OPEN` | new request, no live spec/plan for this slug | auto |
| `DISCOVERY_OPEN → BUILD_IN_PROGRESS` | class is `trivial` | auto — no spec, no plan |
| `DISCOVERY_OPEN → SPEC_DRAFT` | no open gaps remain | auto |
| `SPEC_DRAFT → SPEC_DRAFT` | user gives feedback | auto (old draft deleted, new one written) |
| `SPEC_DRAFT → SPEC_APPROVED` | user approves | needs_confirmation |
| `SPEC_APPROVED → PLAN_HL_DRAFT` | approved spec exists, class is `elevated`/`governing` | auto |
| `SPEC_APPROVED → PLAN_BREAKDOWN_DRAFT` | approved spec exists, class is `standard` | auto — `PLAN_HL_*` skipped |
| `PLAN_HL_DRAFT → PLAN_HL_DRAFT` | user gives feedback | auto |
| `PLAN_HL_DRAFT → PLAN_HL_APPROVED` | user approves high-level plan | needs_confirmation |
| `PLAN_HL_APPROVED → PLAN_BREAKDOWN_DRAFT` | high-level approved | auto |
| `PLAN_BREAKDOWN_DRAFT → PLAN_BREAKDOWN_DRAFT` | user gives feedback | auto |
| `PLAN_BREAKDOWN_DRAFT → PLAN_BREAKDOWN_APPROVED` | user approves breakdown | needs_confirmation |
| `PLAN_BREAKDOWN_APPROVED → BUILD_IN_PROGRESS` | plan fully approved | auto |
| `BUILD_IN_PROGRESS → BUILD_IN_PROGRESS` | a task completes, more remain (respecting `depends on`/`independent`) | auto |
| `BUILD_IN_PROGRESS → BUILD_COMPLETE` | the class's evidence is in hand (see [classes.md](classes.md)) | auto for `trivial`/`standard`/`governing`; needs_confirmation for `elevated`, whose `terraform plan` must be reviewed |
| `BUILD_COMPLETE → PR_OPEN` | effective class matches provisional class | auto |
| `BUILD_COMPLETE → earliest unsatisfied state of the higher class` | effective class is higher than provisional (see "When class is determined" in [classes.md](classes.md)) | needs_confirmation — the change is bumped and re-walks the gates it skipped |
| `PR_OPEN → SHIPPED` | unambiguous merge/tag/deploy signal for this slug | auto for `trivial`/`standard`; needs_confirmation for `elevated`/`governing`, or whenever the signal is ambiguous |
| any `SPEC_*` / `PLAN_*` / `BUILD_*` → `DISCOVERY_OPEN` | a requirement turns out unclear or wrong | needs_confirmation — deletes the current spec+plan (see "One live file per slug" in root `CLAUDE.md`) |

`needs_confirmation` means: present the result and get explicit sign-off
before treating the transition as having happened. `auto` means: proceed and
just log it.

There is no request-driven shortcut through these states. A change takes a
shorter path only by being classified into one — see [classes.md](classes.md).
