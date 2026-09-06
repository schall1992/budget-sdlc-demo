# Phase: Spec

**In:** completed discovery. **Out:** `docs/<feature-slug>-spec.md`.
**Gate:** the user approves the spec.

Write a spec describing the intent of the work — what it is, why, and enough
detail to build it — as a single file in `docs/`, named
`<feature-slug>-spec.md` (slug from the Jira ticket or feature name).

Specs are **self-contained**: never write a spec that says "see previous
spec" or builds on an older one — every spec stands alone as if it were the
first.

**Don't move from spec to plan without the user's approval.** Present the
spec and get explicit consent before planning starts; an unapproved spec is
still in progress.

Revising a spec means deleting it and writing a new one — see "One live file
per slug" in the root `CLAUDE.md`.
