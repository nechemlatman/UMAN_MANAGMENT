# UMAN EVENT MANAGER — TASK BRIEF

**Task ID:** TASK-PEOPLE-01  
**Owner:** Antigravity  
**Status:** ACTIVE  
**Branch / Worktree:** `feature/people-slice`  

## Objective

Review, stabilize, verify, and prepare the inherited People vertical slice implementation for clean integration. Confirm compliance with authoritative product (v2.6) and technical (v1.2) specifications, enforce architecture boundaries, ensure Supabase RLS and audit safety, and record verification evidence.

## Scope

- Domain: `lib/domain/entities/person.dart`, `lib/domain/repositories/people_repository.dart`
- Application: `lib/application/people_controller.dart`
- Infrastructure: `lib/infrastructure/cloud/person_codec.dart`, `lib/infrastructure/cloud/supabase_people_repository.dart`
- Presentation: `lib/presentation/events/event_shell.dart`, `lib/presentation/people/*`
- Database: `supabase/migrations/20260920063325_people_vertical_slice.sql`, `supabase/tests/remote_people.sql`
- Tests: `test/people_*_test.dart`, `tools/db-test/people-checks.mjs`, `tools/db-test/verify.mjs`
- Documentation: `docs/workcards/PEOPLE.md`, `FOR_AGENT.md`, `ACTIVE_WORK.md`, `STATUS.md`

## Out of Scope

- Accommodations, Transport, Meals, Equipment, or Finance domains.
- Automatic balance calculation, passport data collection/upload workflows, or background sync queues.
- Schema/migration changes to non-People tables.
- Modifying authoritative specifications.

## Relevant Specifications

- `UMAN_EVENT_MANAGER_SPEC_v2.6.md` (Master Product Spec - Section 4: Entity Definitions - Person)
- `UMAN_EVENT_MANAGER_TECH_SPEC_v1.2.md` (Technical Architecture - Section 3: Data Architecture & Persistence)
- `ADR-001-CLOUD-FIRST-REALTIME-MULTIUSER.md`
- `CROSS_PLATFORM_DELIVERY.md`
- `MULTI_AGENT_PROTOCOL.md` v1.1

## Dependencies / Shared Resources

- Supabase PostgreSQL schema (`people` table, RLS policies, `create_person` and `update_person_cas` RPCs).
- Event membership validation (`event_members` table and claims).
- `EventShell` tabbed navigation inside Flutter UI.

## Acceptance Criteria

1. `Person` domain entity strictly enforces required fields, nullability rules (e.g. nullable passport expiration date), and expected-version optimistic concurrency.
2. Domain and presentation layers have zero dependencies on Supabase SDK or database packages.
3. Database migration enforces event membership RLS, CAS update checks, and immutable server-side audit logging.
4. Static analysis (`flutter analyze`) produces 0 issues.
5. All Flutter unit and widget tests pass.
6. All PGlite WASM database checks pass.
7. `FOR_AGENT.md` is updated to reflect `STATUS.md` and the multi-agent protocol reading order.
8. Migration safety and RLS security are validated prior to staging deployment.

## Verification Required

- `flutter analyze --no-pub`
- `flutter test --no-pub`
- `node tools/db-test/verify.mjs`

## Handoff

*To be completed upon task stabilization and commit.*
