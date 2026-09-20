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
| `TASK-FLT-01` | Implement Flights domain vertical slice | Gemini | `task/flt-01-flights-slice` | `lib/domain/entities/flight.dart`, `lib/infrastructure/cloud/supabase_flights_repository.dart`, `lib/application/flights_controller.dart`, `lib/presentation/flights/*`, `supabase/migrations/*_flights.sql` | `REVIEW` | Supabase schema (`flights`, `flight_passengers`), `Event` shell navigation, `Person` entity | Implementation complete. 62 Flutter tests pass. Migration `20260920090000_flights.sql` created. Ready for review. |

## Status Values

`PLANNED` · `ACTIVE` · `REVIEW` · `CHANGES_REQUIRED` · `READY_TO_MERGE` · `BLOCKED` · `DONE`

## Ownership Transfer

Before a new agent continues an existing task:

1. Read `STATUS.md`, `MULTI_AGENT_PROTOCOL.md`, this file, and the relevant specifications.
2. Inspect the task branch/worktree, Git status, diff, recent commits, tests, and migrations.
3. Read the previous handoff.
4. Change the Owner field only after the current state is understood.
5. Continue within the existing scope unless a new Task Brief explicitly changes it.
