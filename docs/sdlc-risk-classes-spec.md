---
status: draft
class: governing
---

# Spec: sdlc-risk-classes

## Intent

The SDLC process was five phase files, each declaring its own **In / Out /
Gate** header. Ordering was therefore defined in five places at once, with
no single authority, and every change — a README typo or a `terraform apply`
against prod — travelled the identical path. A doc fix should not need an
approved high-level plan; an infrastructure change should not be able to
reach production on the strength of an agent saying its tests passed.

Split the process into two authorities — ordering, and how strict the gates
are — and derive strictness from what a change touches rather than from
anyone's judgment about it.

## Changes

### New: `sdlc/states.md` — the ordering authority

The state machine: eleven states from `NEW` to `SHIPPED`, and the
transitions between them, each marked `auto`, `needs_confirmation`, or
`human-initiated`. Phase files no longer define ordering; they describe how
to do the work once in a state.

**State is derived, never asked about** — resolved from whether the slug's
spec and plan exist, their `status:` frontmatter, per-task status inside the
plan, and git/GitHub state.

### New: `sdlc/classes.md` — the strictness authority

Four risk classes — `trivial`, `standard`, `elevated`, `governing` — keyed
to the paths a change touches, with a table of how each state's gate differs
per class.

- **Class is derived from paths, never chosen by the requester.** There is no
  "skip the process" request; a change earns a shorter path by what it
  touches. This replaces the old "direct change" escape hatch, which was
  triggered by the user saying a phrase.
- **Determined twice** — provisionally at `SPEC_DRAFT` from the spec's
  declared paths, and effectively at `PR_OPEN` from
  `git diff --name-only main...HEAD`. A change whose real diff outranks its
  declared scope is **bumped** and must satisfy the higher gates before
  shipping. This is what stops a change described as a doc fix from quietly
  editing `infra/`.
- **Evidence comes from outside the agent.** `CI green` means the PR's checks
  reported success, not the agent's own account of its work. `elevated`
  additionally requires a reviewed `terraform plan`, because the merge *is*
  the apply.
- **Gates accumulate; they never substitute.** The classes are ordered for
  naming but are not totally ordered by strictness — `governing` outranks
  `elevated` while requiring weaker evidence. A multi-class change therefore
  takes the union of every touched class's requirements, satisfying the
  strictest gate on each axis independently. Without this, adding a process
  file to an infrastructure change would silently drop its `terraform plan`
  review.
- **Gates are described by mechanism, not by CI filename.** Naming workflow
  files makes the rules go stale silently the next time the files are
  renamed — which the in-flight `budget-models-and-envs` change does.

### Changed: every phase file

`discovery.md`, `spec.md`, `plan.md`, `build.md`, `pull-request.md` drop
their **In / Out / Gate** headers and instead name the states they cover,
pointing at `states.md` for ordering and `classes.md` for strictness.
`build.md` gains the rule that local tests do not close out a build.

### Changed: `sdlc/spec.md` — every class writes a spec

No class is exempt, `trivial` included. What varies is the gate and the
depth: `trivial` specs are `auto` (written straight to `status: approved`,
no sign-off pause) and trimmed to intent, changes, and paths touched.
This removes the special case where `trivial` had no spec and its class was
recorded only in the log — provisional `class:` now lives in spec
frontmatter uniformly.

### Changed: `CLAUDE.md`

Points at the two new authorities, and requires `Class` alongside
`Transition` in every log entry, written as `provisional → effective` when a
change was bumped.

### Unchanged by design: `log.md`

Logging transcends classes. `log.md` is an append-only process record, not a
change surface, and does not participate in class derivation — every change
writes to it regardless of class, and its presence in a diff never affects
what class that diff is.

## Paths touched

`sdlc/**`, `CLAUDE.md`, `docs/**`

`sdlc/**` and `CLAUDE.md` put this in the `governing` row of
[classes.md](../sdlc/classes.md): the process definition itself, where
loosening a gate is reviewed like an infrastructure change rather than
edited like config.

## Known deviation

This spec was written **after** the work it describes, and the work was
committed before the spec was approved — `governing` requires
`needs_confirmation` at `SPEC_*`. The edits accumulated in the working tree
across several sessions before the "every class writes a spec" rule existed
to require one. Recorded here rather than presented as a clean run.

The deviation is also its own evidence for the rule: four committed files
(`README.md`, `index.md`, and both live specs) came to reference
`sdlc/states.md` and `sdlc/classes.md` while those two files were still
untracked, leaving dangling links in exactly the docs meant to onboard a new
session.
