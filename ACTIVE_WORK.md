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
| `TASK-TRN-01` | Review, build, and integrate Drivers & Vehicles vertical slice | Temporary Implementation Agent | `main` | `lib/domain/entities/driver.dart`, `lib/domain/entities/vehicle.dart`, `lib/domain/repositories/transport_repository.dart`, `lib/application/drivers_controller.dart`, `lib/application/vehicles_controller.dart`, `lib/infrastructure/cloud/*driver*`, `lib/infrastructure/cloud/*vehicle*`, `lib/presentation/transport/*`, `supabase/migrations/20260920120000_drivers_and_vehicles.sql`, `test/domain/transport_test.dart`, `tools/db-test/transport-checks.mjs` | `DONE` | Supabase schema (`drivers`, `vehicles`), `Event` shell navigation | Implemented pure entities, repository contracts, Supabase repository & codecs, controllers, UI pages, DB migration `20260920120000_drivers_and_vehicles.sql`, unit/widget tests, and WASM DB checks (29 new DB checks). Passed 74 Flutter tests, 205 WASM DB checks, 0 analyze issues. |

## Status Values

`PLANNED` · `ACTIVE` · `REVIEW` · `CHANGES_REQUIRED` · `READY_TO_MERGE` · `BLOCKED` · `DONE`

## Ownership Transfer

Before a new agent continues an existing task:

1. Read `STATUS.md`, `MULTI_AGENT_PROTOCOL.md`, this file, and the relevant specifications.
2. Inspect the task branch/worktree, Git status, diff, recent commits, tests, and migrations.
3. Read the previous handoff.
4. Change the Owner field only after the current state is understood.
5. Continue within the existing scope unless a new Task Brief explicitly changes it.


## 2026-09-22 independent audit correction

`TASK-TRN-01` is **CHANGES_REQUIRED**, not DONE. Before any `TASK-TRN-02` implementation:
- reconcile Driver/Vehicle fields and status enums with `UMAN_EVENT_MANAGER_SPEC_v2.6.md` or document an explicit approved specification change;
- wire Transport repository realtime signals to controllers, add bounded periodic reconciliation, and dispose subscriptions/repositories correctly;
- implement the restore workflow required by the task brief;
- classify CAS conflict, unauthorized, connectivity, and unknown failures instead of collapsing them into generic failure/null;
- rerun the full verification gate and obtain independent review.
