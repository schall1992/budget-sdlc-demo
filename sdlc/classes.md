# Risk classes

Not every change deserves the same process. A doc fix and a Terraform change
that applies to production on merge should not travel the same path. This
file is the authority on **what class a change is** and **how its gates
differ**; [states.md](states.md) remains the authority on state ordering.

Class is **derived from the paths a change touches, never chosen by the
requester.** There is no "skip the process" request — a change that deserves
a shorter path gets one because of what it touches, not because someone said
so.

## The classes

| Class | Paths | Why |
|---|---|---|
| `trivial` | `docs/**`, `kb/**`, `README.md`, `index.md` | No runtime effect; nothing downstream reads these. |
| `standard` | `dbt/models/**`, `dbt/macros/**`, `dbt/tests/**` | Changes data products. The PR workflow builds and tests them against pre-production before merge. |
| `elevated` | `infra/**`, `dbt/setup/**`, `dbt/schedules.sql`, `dbt/profiles.yml`, `.github/workflows/**` | Snowflake objects, grants, identities, orchestration, and the CI that deploys them. The merge workflow runs `terraform apply -auto-approve` against prod — there is no review step after the merge. The workflows belong here rather than in `governing` because in this repo CI *is* the deployment mechanism: it moves with the infrastructure it applies, not with the process definition. |
| `governing` | `sdlc/**`, `CLAUDE.md` | The process definition itself. Loosening a gate here is reviewed like an infrastructure change, not edited like config. |

**Precedence: the highest class among all touched paths wins.** A change
touching `docs/` and `infra/` is `elevated`. A path matching no rule above is
`standard`.

**Gates accumulate; they never substitute.** The classes are ordered
`trivial` → `standard` → `elevated` → `governing` for *naming* a change, but
they are not totally ordered by strictness — `governing` outranks `elevated`
while requiring weaker evidence. So a multi-class change takes the **union**
of every touched class's requirements, not just the named class's row: it
satisfies the strictest gate on each axis independently. A change touching
both `infra/` and `sdlc/**` is named `governing` *and* must produce a
reviewed `terraform plan`, because `elevated` demands one and naming does
not excuse it. Precedence decides what a change is called; it never
subtracts a requirement the change would otherwise have had.

## When class is determined

Twice, because a change's declared scope and its actual diff can disagree.

1. **Provisional** — at `SPEC_DRAFT`, from the paths the spec says it will
   touch. Recorded as `class:` in the spec's frontmatter, beside `status:`.
   Every class writes a spec, so this field is always present.
2. **Effective** — at `BUILD_COMPLETE → PR_OPEN`, recomputed from the real
   diff (`git diff --name-only main...HEAD`).

Class is always derivable from paths; the frontmatter field is a cached
reference, not the source of truth. If the two disagree, the paths are right.

**If the effective class is higher than the provisional one, the change is
bumped** and must satisfy the higher class's gates before it can reach
`PR_OPEN` — including gates it already passed at the lower class. This is
what stops a change described as a doc fix from quietly editing `infra/`.
See the bump transition in [states.md](states.md).

## How gates differ by class

`auto`, `needs_confirmation`, and `skipped` per state. Transitions not listed
here do not vary by class — [states.md](states.md) governs them.

| | `trivial` | `standard` | `elevated` | `governing` |
|---|---|---|---|---|
| `SPEC_*` | **auto** | needs_confirmation | needs_confirmation | needs_confirmation |
| `PLAN_HL_*` | skipped | skipped | needs_confirmation | needs_confirmation |
| `PLAN_BREAKDOWN_*` | skipped | needs_confirmation | needs_confirmation | needs_confirmation |
| evidence for `BUILD_COMPLETE` | none | CI green | CI green + reviewed `terraform plan` | CI green |
| `PR_OPEN → SHIPPED` | auto | auto | needs_confirmation | needs_confirmation |

Read this table **by column per touched class, then take the strictest
value on each row** — see "Gates accumulate" above. A change spanning
`elevated` and `governing` owes the reviewed `terraform plan` from the
`elevated` column even though it is named `governing`.

`skipped` means the state is not entered at all: a `trivial` change goes
`SPEC_APPROVED → BUILD_IN_PROGRESS` with no plan, and a `standard` change
goes `SPEC_APPROVED → PLAN_BREAKDOWN_DRAFT` without a high-level plan round.

**Every class writes a spec — including `trivial`.** What differs is the
gate, not the existence of the document. For `trivial`, `SPEC_*` is `auto`:
the spec is written straight to `status: approved` and build proceeds
without pausing for sign-off. It exists as the record of intent and as the
home of the provisional `class:`, not as a checkpoint. Its shape is trimmed
— see [spec.md](spec.md).

**Evidence comes from outside the agent.** "CI green" means the PR's checks
reported success (`gh pr checks`) — not that the agent ran tests locally and
was satisfied. For `elevated`, the `terraform plan` posted by the PR
workflow must be read and confirmed with the user before `BUILD_COMPLETE`,
because the merge itself is the apply.

Described by mechanism rather than by workflow filename on purpose: CI file
names change, and a gate that names them goes stale silently the next time
they do.
