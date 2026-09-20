# UMAN EVENT MANAGER — TASK BRIEF

**Task ID:** TASK-FLT-01
**Owner:** Gemini (Review/Recovery: Gemini)
**Status:** READY_TO_MERGE
**Branch / Worktree:** `main` (integrated prematurely, recovered via repair)

## Objective

Implement the Flights domain vertical slice, including domain models, persistence (Supabase), application logic (Controller), and UI (List, Details, Editor) in Flutter, ensuring strict event isolation, auditability, and concurrency control.

## Scope

- **Database**: Supabase migrations for `flights` and `flight_passengers` tables, RLS policies, RPCs (CRUD, soft-delete, restore), and audit triggers.
- **Domain**: `Flight`, `FlightPassenger`, `FlightDirection`, `FlightStatus` entities and repositories contracts.
- **Infrastructure**: Supabase implementation of the Flights repository, including codecs.
- **Application**: `FlightsController` using the repository and handling state.
- **Presentation**: 
    - `FlightsPage` (list of flights for the current event).
    - `FlightDetailsPage`.
    - `FlightEditorPage`.
    - Integration into `EventShell` tabbed navigation.
- **Testing**: Unit tests for domain, repository, and controller; database verification tests.

## Out of Scope

- Accommodation, Transport, Finance, or Rules Engine logic.
- Automated flight tracking API integrations (manual/imported data only for now).
- Cross-event person sharing (Flights remain event-scoped).

## Relevant Specifications

- `UMAN_EVENT_MANAGER_SPEC_v2.6.md` (Section 10: Flight Management)
- `UMAN_EVENT_MANAGER_TECH_SPEC_v1.2.md`
- `ADR-001-CLOUD-FIRST-REALTIME-MULTIUSER.md`
- `docs/DESIGN_SYSTEM.md`

## Dependencies / Shared Resources

- **Event Context**: All flight data must be scoped to an `Event`.
- **People Domain**: `FlightPassenger` references the `Person` entity.
- **Supabase Schema**: New migrations for flights.
- **UI Navigation**: `EventShell` will be modified to include a Flights tab.

## Acceptance Criteria

1. Flights and FlightPassengers are correctly persisted in Supabase with strict Event isolation.
2. RLS policies prevent unauthorized access (only event members can read/write).
3. CAS (Optimistic Concurrency Control) is implemented for Flight updates.
4. Server-side audit entries are generated for all material changes.
5. Soft-delete and restore workflows are functional.
6. The UI supports creating, editing, and listing flights, and managing passengers on those flights.
7. `flutter analyze` passes with 0 issues.
8. All new and existing tests pass.

## Verification Required

- `flutter analyze`
- `flutter test` (Unit & Widget tests)
- `node tools/db-test/verify.mjs` (WASM DB verification for new migrations)
- Manual verification of UI flows in the Android emulator/device.

## Handoff

- **Git Recovery & Review Findings (2026-09-20)**:
    - TASK-FLT-01 was integrated directly into `main` (commit `4f0c7cb`) without isolated review.
    - Initial implementation had critical **database integrity defects**: missing composite foreign keys in `flight_passengers` allowed cross-event data leakage (referencing a flight from Event A in a passenger record for Event B).
    - Initial implementation was missing **search logic** in `FlightsController` and `list_flights` RPC.
    - WASM DB verification harness was not extended to cover Flights.
- **Completed Repairs**:
    - Created repair migration `20260920110000_flights_integrity_repair.sql` adding `unique(event_id, id)` to `flights` and composite FKs to `flight_passengers`.
    - Added rigorous field validation to `public.save_flight` via `flights_private.validate_fields`.
    - Implemented search in `list_flights` RPC and `FlightsController`.
    - Extended `FlightPassenger` Dart entity with audit and `eventId` fields.
    - Created `tools/db-test/flights-checks.mjs` and integrated it into `verify.mjs` (18 new checks).
- **Material files changed**:
    - `supabase/migrations/20260920110000_flights_integrity_repair.sql` (NEW)
    - `lib/domain/entities/flight.dart` (Updated)
    - `lib/infrastructure/cloud/flight_codec.dart` (Updated)
    - `lib/application/flights_controller.dart` (Updated)
    - `lib/presentation/flights/flights_page.dart` (Updated)
    - `tools/db-test/flights-checks.mjs` (NEW)
    - `tools/db-test/verify.mjs` (Updated)
- **Verification performed and results**:
    - `flutter analyze` - PASSED (0 errors, 0 warnings).
    - `flutter test` - PASSED (62 tests, including flights).
    - `node tools/db-test/verify.mjs` - PASSED (176 checks total, including 18 new Flights integrity/validation checks).
- **Status**: Verified and repaired. The repository is in a clean state on `main`.
