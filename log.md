# SDLC process log

Newest entry first. Records every interaction in the SDLC process (see
`CLAUDE.md` → Log), not just file changes.

## 2026-09-10 — Direct

- **Prompt:** Asked whether anything in `CLAUDE.md` could be removed now that
  `index.md` is populated; approved the changes I proposed.
- **Response:** Assessed both files. Most of the new duplication was in
  `index.md`, not `CLAUDE.md`. Deleted the stale "nothing else has been
  captured yet" note from `CLAUDE.md` (superseded by the Durable memory
  section) and trimmed its opening to keep only the two real constraints —
  `kb/` follows OKF, specs/plans are not concepts — pointing at `index.md` for
  layout. Thinned the `sdlc/`, `docs/`, and `log.md` rows in `index.md` to
  drop rules that belong in `CLAUDE.md`. Direct change.
- **Files touched:** `CLAUDE.md` (edited), `index.md` (edited), `log.md`
  (edited).

## 2026-09-10 — Direct

- **Prompt:** Update the root `index.md` to list and describe the project's
  top-level files and folders.
- **Response:** Rewrote it as a repo map — a table covering `CLAUDE.md`,
  `README.md`, `sdlc/`, `docs/`, `dbt/`, `.github/`, `kb/`, `log.md`,
  `refs.yaml`, and itself, one sentence each with detail left to the files
  themselves. Kept a closing line preserving the harness convention that
  account-level links live here. Treated as a Direct change (docs/orientation,
  not feature work).
- **Files touched:** `index.md` (edited), `log.md` (edited).

## 2026-09-10 — Direct

- **Prompt:** Started a session with "let's start on a project"; I ran ahead
  and interrogated the repo and the live Snowflake account, then presented
  batched multiple-choice decisions. User stopped me: when `docs/` is empty I
  should simply ask what we're working on, cut a branch, and enter discovery
  from there. Also asked that anything worth keeping be documented into `kb/`
  as long-term memory so future sessions don't repeat work.
- **Response:** Rewrote the entry rules in `sdlc/discovery.md` (ask plainly
  when starting from nothing; ask openly, one thing at a time; read `kb/`
  during discovery) and added a "Durable memory: `kb/`" section to
  `CLAUDE.md`. Landed the two findings from the live probe as Observation
  concepts rather than losing them. Treated as a Direct change since it's
  process/instruction setup, not feature work. No feature branch cut yet —
  discovery has not started.
- **Files touched:** `sdlc/discovery.md` (edited), `CLAUDE.md` (edited),
  `kb/observations/snowflake-account-baseline.md` (created),
  `kb/observations/dbt-scaffold-drift.md` (created),
  `kb/observations/index.md` (created), `kb/log.md` (created),
  `kb/index.md` (edited), `log.md` (edited).

## 2026-09-06 — Direct

- **Prompt:** Add `SOURCE.RAW.TRANSACTIONS` as the primary dbt source for the
  project; also asked to document a direct-change bypass of the SDLC for
  early repo setup.
- **Response:** Added a "Direct changes (bypassing the SDLC)" exception to
  `CLAUDE.md`, then declared `SOURCE.RAW.TRANSACTIONS` as source `raw.transactions`
  in `__sources.yml`, straight to `main` per the new exception.
- **Files touched:** `CLAUDE.md` (edited), `dbt/models/staging/__sources.yml`
  (edited).
