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
| `TASK-PEOPLE-01` | Review, stabilize, and prepare People vertical slice for integration | Antigravity | `feature/people-slice` | `lib/domain/entities/person.dart`, `lib/domain/repositories/people_repository.dart`, `lib/application/people_controller.dart`, `lib/infrastructure/cloud/*person*`, `lib/presentation/people/*`, `lib/presentation/events/event_shell.dart`, `supabase/migrations/20260920063325_people_vertical_slice.sql`, `test/*people*`, `tools/db-test/people-checks.mjs` | `ACTIVE` | Supabase schema (`people` table, RLS, RPCs), `Event` shell navigation | Taking ownership. Inspecting implementation against authoritative specs v2.6 & v1.2. |

## Status Values

`PLANNED` · `ACTIVE` · `REVIEW` · `CHANGES_REQUIRED` · `READY_TO_MERGE` · `BLOCKED` · `DONE`

## Ownership Transfer

Before a new agent continues an existing task:

1. Read `STATUS.md`, `MULTI_AGENT_PROTOCOL.md`, this file, and the relevant specifications.
2. Inspect the task branch/worktree, Git status, diff, recent commits, tests, and migrations.
3. Read the previous handoff.
4. Change the Owner field only after the current state is understood.
5. Continue within the existing scope unless a new Task Brief explicitly changes it.
