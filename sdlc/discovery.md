# Phase: Discovery

**In:** a request. **Out:** a feature branch off `main`, and clear intent.
**Gate:** no open gaps — don't move to spec until the intent of the work is
actually clear.

**Starting from nothing.** When `docs/` holds no spec or plan for live work,
there is nothing to infer from — so just ask, in plain language, what we're
working on. Don't scan the repo for unfinished-looking things and present
them as candidate features, and don't guess a scope. One open question, then
work from the answer.

Work never happens directly on `main`. Once the request is known, settle the
branch name — ask what to call it — and create/checkout that branch off
`main` before going any further. This also applies when discovery reopens
mid-work: confirm whether to keep working on the existing branch or cut a new
one.

Once the branch is settled, understand what's actually being asked for. Pull
in whatever's needed: read `kb/` for what past sessions already established,
ask the person directly, look up the relevant Jira ticket, search the
internet, read the local code/docs already in the repo.

**Ask openly, one thing at a time.** Discovery is a conversation, not a
questionnaire. Prefer a plain open question over a menu of pre-baked options,
and don't batch a pile of decisions into one turn — the answer to the first
usually changes the rest.

**Reopening discovery.** If, while working a later phase, a requirement turns
out to be unclear or wrong, stop and come back here — don't patch around the
ambiguity in code or in the existing spec. Once discovery resolves it,
replace that slug's spec and plan per "One live file per slug" in the root
`CLAUDE.md`, and plan afresh from the new spec.
