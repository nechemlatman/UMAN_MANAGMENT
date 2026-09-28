# UMAN EVENT MANAGER — ACTIVE WORK

This file is the live coordination ledger for concurrent agent work.

**Rules**
- Every implementation task must be registered here before editing begins.
- Exactly one implementation owner per active task.
- Update ownership before a takeover.
- Do not delete completed history immediately; keep recent completed entries until they are safely reflected in `STATUS.md`.
- If overlap with another active task is possible, stop and coordinate before editing.

## Active Tasks

| Task ID | Objective | Owner | Branch / Worktree | Scope | Status | Shared Resources / Dependencies | Last Handoff / Note |
|---|---|---|---|---|---|---|---|
| `TASK-PEOPLE-01` | Review, stabilize, deploy, and integrate People vertical slice | Antigravity | `main` | `lib/domain/entities/person.dart`, `lib/domain/repositories/people_repository.dart`, `lib/application/people_controller.dart`, `lib/infrastructure/cloud/*person*`, `lib/presentation/people/*`, `lib/presentation/events/event_shell.dart`, `supabase/migrations/20260920063325_people_vertical_slice.sql`, `test/*people*`, `tools/db-test/people-checks.mjs` | `DONE` | Supabase schema (`people` table, RLS, RPCs), `Event` shell navigation | Reviewed, stabilized, verified (58 Flutter tests & 158 WASM checks pass), verified on remote Supabase staging (`remote_people.sql` passed 17 checks), merged into `main` (`78625ec`). |
| `TASK-FLT-01` | Review, repair, and integrate Flights vertical slice | Antigravity | `main` | `lib/domain/entities/flight.dart`, `lib/infrastructure/cloud/supabase_flights_repository.dart`, `lib/application/flights_controller.dart`, `lib/presentation/flights/*`, `supabase/migrations/20260920090000_flights.sql`, `supabase/migrations/20260920110000_flights_integrity_repair.sql` | `DONE` | Supabase schema (`flights`, `flight_passengers`), `Event` shell navigation, `Person` entity | Repaired schema integrity, added composite FKs & RPC search, aligned fake repository override & codec fallbacks. Passed 64 Flutter tests, 176 WASM DB checks, 0 analyze errors. Pushed to `main` (`e7ec730`). |
| `TASK-TRN-01` | Repair and verify Drivers & Vehicles foundation | Codex Lead Builder | `codex/trn-02-vertical-slice` | Transport foundation closure corrections, forward migration, regression tests and documentation | `DONE` | Transport schema/RPC/RLS/realtime; EventShell lifecycle | Closure d253695: analyzer clean, 88 tests, 304 DB checks, 21 Transport files format clean. Staging synchronized; hosted rollback security/CAS/restore/audit checks passed. Grant repair raises DB gate to 306. |
| `TASK-TRN-02` | Ground Transport: Trip + TripPassenger vertical slice | Codex Lead Builder | `codex/trn-02-vertical-slice` | `lib/domain/entities/trip*.dart`, `lib/domain/repositories/trips_repository.dart`, `lib/application/trips_controller.dart`, `lib/infrastructure/cloud/*trip*`, `lib/presentation/transport/trip*`, new Supabase migration, `test/*trip*`, `tools/db-test/trip-checks.mjs` | `DONE` | `TASK-TRN-01` repair completion, `TASK-FLT-01` flights schema, `TASK-PEOPLE-01` people schema | PR #2 independently approved and merged as ace677f; main verified: 111 Flutter tests, 370 DB checks, clean analyzer, CI 36306112850 passed. |
| `TASK-ACC-01` | Accommodation Foundation: Apartment, Room, SleepingPlace, Assignment vertical slice | Codex Lead Builder | `main` | `lib/domain/entities/accommodation*.dart`, `lib/domain/repositories/accommodation_repository.dart`, `lib/application/accommodation_controller.dart`, `lib/infrastructure/cloud/*accommodation*`, `lib/presentation/accommodation/*`, new Supabase migration, `test/*accommodation*`, `tools/db-test/accommodation-checks.mjs` | `DONE` | `TASK-PEOPLE-01` people schema, event isolation | PR #3 independently APPROVED; merged efeac130; approved head unchanged. Main: 150 Flutter tests, 599 DB checks, formatter/analyzer/diff clean, Android APK and CI 36486898094 passed. Twelve staging migrations aligned; no remote changes. |

## Status Values

`PLANNED` · `ACTIVE` · `REVIEW` · `CHANGES_REQUIRED` · `READY_TO_MERGE` · `BLOCKED` · `DONE`

## Ownership Transfer

Before a new agent continues an existing task:

1. Read `STATUS.md`, `MULTI_AGENT_PROTOCOL.md`, this file, and the relevant specifications.
2. Inspect the task branch/worktree, Git status, diff, recent commits, tests, and migrations.
3. Read the previous handoff.
4. Change the Owner field only after the current state is understood.
5. Continue within the existing scope unless a new Task Brief explicitly changes it.


## Historical TASK-TRN-01 checkpoint — 2026-09-24 (superseded below)

The 2026-09-22 CHANGES_REQUIRED findings led to the repair in `52be6b3`.
The owner reconfirmed Codex Lead Builder as sole implementation owner after a
concurrent commit/checkout change. Actual checkout is now `main`; prior
`codex/transport-foundation-repair` references are historical.

The independent inspector accepted the core repair and requested operator audit
attribution and documentation corrections. These are addressed; current state is
**REVIEW**, never DONE pending final review and Core Verification on the closure
commit. See `docs/workcards/TASK-TRN-01.md` for verification and migration policy.
Antigravity may prepare future briefs; active Transport code/schema remains owned
by Codex. TASK-TRN-02 and TASK-ACC-01 remain PLANNED.


## 2026-09-26 current handoff (supersedes historical gates)
TRN-01 closure locally verified against d253695 and hosted schema synchronized. Lead Builder owns TRN-02. User explicitly authorized implementation after these checks. CI on d253695 and independent-client realtime acceptance are not claimed. Manager explicitly changes Trip status; nullable pickup location receives no inferred default.


## 2026-09-27 verified implementation handoff
TRN-02 implementation committed as b2191f1; hosted migration and rollback smoke passed. Two tables, strict same-event FKs, ten restricted RPCs, RLS and publication verified. 370 DB checks; Android build passed. Final form guard regression added before handoff. No shared work was overwritten and no stale historical review branch was merged. Review/main integration and independent-client/device acceptance remain separate gates.

Core Verification run 36300924938 passed for 37a9e8b. PR #2 contains the completed implementation. Final staging CLI dry-run reported upToDate=true with no pending migrations. Latest documentation changes only record this evidence.


## 2026-09-27 Accommodation review handoff
TRN-02 independently approved and merged unchanged as ace677f; main Core Verification passed locally and on GitHub run 36306112850. TASK-TRN-02 is DONE. Codex Lead Builder is sole TASK-ACC-01 implementation owner. New migration 20260927082740_accommodation_vertical_slice applied to staging after dry-run; eleven local/remote migrations match. Source, tests and review details are in TASK-ACC-01. Do not merge Accommodation without independent review.

Review PR: [#3](https://github.com/nechemlatman/UMAN_MANAGMENT/pull/3). Core Verification run [36343758254](https://github.com/nechemlatman/UMAN_MANAGMENT/actions/runs/36343758254) passed on implementation commit 8c6749d4815b9fbb8c30b31ccd0fac615e3eced4. Final staging dry-run: upToDate=true, no pending migrations. Subsequent handoff edits are documentation only; independent review remains required.

## 2026-09-28 owner policy follow-up
Codex Lead Builder remains sole owner of TASK-ACC-01 on codex/acc-01-vertical-slice / PR #3. ACTIVE: implement owner's draft-friendly forms, shared localized date pickers, save/action validation boundaries, forward-only schema changes, and targeted legacy-form inventory. Earlier REVIEW verification describes the previous revision until this follow-up passes its gates.

## 2026-09-28 review handoff
Owner policy revision is IMPLEMENTED / VERIFIED / READY FOR INDEPENDENT REVIEW.
Verified current main 17ebbffa95efd41cc628017e33bb01ac4a017542 is included in the
ACC branch; PR #2 remains merged/DONE. 150 Flutter tests, 599 DB checks (including
legacy Accommodation upgrade preservation), clean analyzer/format/diff, configured
Android APK. Forward 20260928073059 applied to rrgzalzaaprdsmwihqxa; twelve migrations
match and final dry-run is up to date. Both hosted rollback suites/catalog passed;
anonymous table/read RPC probes returned 401. Shared localized calendar controls
and nullable draft contracts are documented in the authoritative specs. Legacy
screen conversions are inventoried, not silently claimed complete. PR #3 remains
unmerged. No claude/ui-design-system branch work was touched or merged.

## TASK-ACC-01 final integration — 2026-09-29

The owner supplied independent inspector verdict APPROVE with no findings,
security vulnerabilities or scope violations. Immediately before merge, PR #3
was open/mergeable at exactly `c6c6a50a920e07a6454bfe5de1df14f533821a61`;
main remained at reviewed base `17ebbffa95efd41cc628017e33bb01ac4a017542`, with a
clean working tree. GitHub merged using the established merge-commit method as
`efeac1304453515bb4306add78c468d9b67f16da`. Approved head is an ancestor; the
merged tree is byte-for-byte identical to the approved tree. No unrelated branch
was merged, including `claude/ui-design-system`.

Post-merge checks on actual main: formatter checked 18 relevant Dart files with
zero changes; analyzer no issues; full Flutter suite **150 passed**; PostgreSQL/
PGlite **599 passed**; `git diff --check` clean; configured Android debug APK built.
[Main Core Verification 36486898094](https://github.com/nechemlatman/UMAN_MANAGMENT/actions/runs/36486898094)
passed on the merge commit. No implementation repairs were required.

Staging `rrgzalzaaprdsmwihqxa`: twelve local/remote versions match, including
`20260927082740_accommodation_vertical_slice.sql` and
`20260928073059_accommodation_draft_forms.sql`. An initial connection timeout
resolved on retry; migration list and read-only history comparison succeeded.
Final dry-run: `upToDate=true`, no pending migrations. No remote mutations,
reapplications, resets, history edits or smoke data were necessary.

**Draft-Friendly / Progressive Completion remains a project-wide principle**:
permissive Save is separate from operational/action validation; retain nullable
drafts, minimal natural identity, calendar/date-picker UX, and no invented dates
or relationships. Master spec Section 5 and Technical v1.2 remain authoritative.
The bounded legacy-form conversion inventory in TASK-ACC-01 remains outstanding;
no claim is made that every older screen is converted. External acceptance gates in STATUS.md remain open. ACC-01 is DONE as an integrated software slice.
