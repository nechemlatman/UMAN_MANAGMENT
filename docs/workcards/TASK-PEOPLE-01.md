# UMAN EVENT MANAGER — TASK BRIEF

**Task ID:** TASK-PEOPLE-01  
**Owner:** Antigravity  
**Status:** READY_TO_MERGE  
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
5. All Flutter unit and widget tests pass (58/58).
6. All PGlite WASM database checks pass (158/158).
7. `FOR_AGENT.md` is updated to reflect `STATUS.md` and the multi-agent protocol reading order.
8. Migration safety and RLS security are validated prior to staging deployment.

## Verification Required

- `flutter analyze --no-pub` (PASSED - 0 issues)
- `flutter test --no-pub` (PASSED - 58 tests)
- `node tools/db-test/verify.mjs` (PASSED - 158 WASM DB checks)

## Handoff

- **Completed:**
  * Reviewed all 25 files of the People vertical slice against Master v2.6 & Technical v1.2 specs.
  * Verified architectural purity, RLS authorization in `people_private.authorize`, optimistic version concurrency, and private details separation (`people_private.person_details`).
  * Aligned `FOR_AGENT.md` reading order with `STATUS.md` and multi-agent control standards.
  * Ran static analysis, unit/widget test suite, and WASM PGlite DB test suite (all passed cleanly).
  * Isolated uncommitted working tree changes into dedicated feature branch `feature/people-slice`.
  * Committed (`22760dc`) and pushed both `main` (`d8c0ca8`) and `feature/people-slice` (`22760dc`) to GitHub remote (`origin`).
- **Material Files Changed:** `FOR_AGENT.md`, `ACTIVE_WORK.md`, `STATUS.md`, `docs/workcards/TASK-PEOPLE-01.md`, `lib/domain/entities/person.dart`, `lib/domain/repositories/people_repository.dart`, `lib/application/people_controller.dart`, `lib/infrastructure/cloud/*person*`, `lib/presentation/people/*`, `lib/presentation/events/event_shell.dart`, `supabase/migrations/20260920063325_people_vertical_slice.sql`, `test/*people*`, `tools/db-test/people-checks.mjs`.
- **Risks / Blockers:** None for local codebase. Remote staging Supabase project has not yet had `20260920063325_people_vertical_slice.sql` applied.
- **Recommended Next Action:** Deploy migration `20260920063325_people_vertical_slice.sql` to remote Supabase staging environment, merge `feature/people-slice` into `main`, and perform live staging device verification.
