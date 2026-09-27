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
| `TASK-TRN-02` | Ground Transport: Trip + TripPassenger vertical slice | Codex Lead Builder | `codex/trn-02-vertical-slice` | `lib/domain/entities/trip*.dart`, `lib/domain/repositories/trips_repository.dart`, `lib/application/trips_controller.dart`, `lib/infrastructure/cloud/*trip*`, `lib/presentation/transport/trip*`, new Supabase migration, `test/*trip*`, `tools/db-test/trip-checks.mjs` | `REVIEW` | `TASK-TRN-01` repair completion, `TASK-FLT-01` flights schema, `TASK-PEOPLE-01` people schema | Implemented and locally/hosted verified on this branch; staging has ten migrations. Awaiting review/CI and integration, not a new planning cycle. |
| `TASK-ACC-01` | Accommodation Foundation: Apartment, Room, Bed, Assignment vertical slice | Unassigned (PLANNED) | TBD | `lib/domain/entities/accommodation*.dart`, `lib/domain/repositories/accommodation_repository.dart`, `lib/application/accommodation_controller.dart`, `lib/infrastructure/cloud/*accommodation*`, `lib/presentation/accommodation/*`, new Supabase migration, `test/*accommodation*`, `tools/db-test/accommodation-checks.mjs` | `PLANNED` | `TASK-PEOPLE-01` people schema, event isolation | Task brief prepared in `docs/workcards/TASK-ACC-01.md`. Dependency-safe slice ready for planning/pre-construction. |

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
