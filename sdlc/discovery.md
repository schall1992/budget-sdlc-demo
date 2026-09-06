# Phase: Discovery

**In:** a request. **Out:** a feature branch off `main`, and clear intent.
**Gate:** no open gaps — don't move to spec until the intent of the work is
actually clear.

Work never happens directly on `main`. The first question of every discovery
phase — before anything else — is what to name the feature branch for this
work; create/checkout that branch off `main` before going any further. This
also applies when discovery reopens mid-work: confirm whether to keep working
on the existing branch or cut a new one.

Once the branch is settled, understand what's actually being asked for. Pull
in whatever's needed: ask the person directly, look up the relevant Jira
ticket, search the internet, read the local code/docs already in the repo.

**Reopening discovery.** If, while working a later phase, a requirement turns
out to be unclear or wrong, stop and come back here — don't patch around the
ambiguity in code or in the existing spec. Once discovery resolves it,
replace that slug's spec and plan per "One live file per slug" in the root
`CLAUDE.md`, and plan afresh from the new spec.
