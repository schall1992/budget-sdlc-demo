# Phase: Build

States `BUILD_IN_PROGRESS`/`BUILD_COMPLETE` — see [states.md](states.md) for
the gates in and out of these states.

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

Passing tests locally is not what closes out the build. `BUILD_COMPLETE`
requires the evidence its class calls for — see "How gates differ by class"
in [classes.md](classes.md) — and that evidence comes from CI, not from the
agent's own account of its work.

If a requirement turns out to be unclear or wrong mid-build, reopen discovery
(see `discovery.md`) rather than patching around it.
