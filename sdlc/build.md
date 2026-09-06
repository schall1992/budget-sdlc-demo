# Phase: Build

**In:** an approved plan (high-level + breakdown). **Out:** code and tests on
the feature branch. **Gate:** every breakdown task complete, tests passing.

Developer agents pick up the breakdown's tasks and implement them. Default to
completing one task fully — including that task's tests — before starting the
next; only work tasks in parallel when the breakdown marks them
`independent`, never when one `depends on` another. Use whatever agent shape
fits (same agent working the list in sequence, or a subagent per task) as
long as this ordering rule holds.

Tests written per task should verify the spec's important functionality only
— minimal but impactful, not exhaustive coverage. Scope comes from what the
plan's breakdown already specified for that task, not decided ad hoc while
building.

If a requirement turns out to be unclear or wrong mid-build, stop and reopen
discovery (see `discovery.md`) rather than patching around it.
