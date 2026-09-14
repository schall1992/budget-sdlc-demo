# Phase: Spec

States `SPEC_DRAFT`/`SPEC_APPROVED` — see [states.md](states.md) for the
gates in and out of these states.

Write a spec describing the intent of the work — what it is, why, and enough
detail to build it — as a single file in `docs/`, named
`<feature-slug>-spec.md` (slug from the Jira ticket or feature name), with a
`status: draft` (or `approved`) frontmatter line.

Specs are **self-contained**: never write a spec that says "see previous
spec" or builds on an older one — every spec stands alone as if it were the
first.

Revising a spec means deleting it and writing a new one — see "One live file
per slug" in the root `CLAUDE.md`.

## Every change gets one

No class is exempt, `trivial` included — a change worth making is worth
stating the intent of. What varies is the gate and the depth:

- **`trivial`** — `SPEC_*` is `auto` (see
  [classes.md](classes.md)): write it straight to `status: approved` and
  carry on into build without pausing. Keep it **trimmed** — intent, what
  changes, and the paths touched. That's it. No current-state survey, no
  test plan, no out-of-scope section. Usually well under a page. The paths
  section matters most: it's what justifies the class, and what the
  effective class is later checked against.
- **every other class** — the full shape, and `status: draft` until the
  user approves it.
