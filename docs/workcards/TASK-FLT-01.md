# UMAN EVENT MANAGER — TASK BRIEF

**Task ID:** TASK-FLT-01
**Owner:** Gemini
**Status:** ACTIVE
**Branch / Worktree:** `task/flt-01-flights-slice`

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

- **Completed**:
    - Database migration `20260920090000_flights.sql` with `flights` and `flight_passengers` tables, RLS, RPCs, and Audit triggers.
    - Domain models `Flight` and `FlightPassenger`.
    - `SupabaseFlightsRepository` with realtime support.
    - `FlightsController` for state management and CRUD operations.
    - UI pages: `FlightsPage`, `FlightDetailsPage`, `FlightEditorPage`, and `PassengerEditor`.
    - Integrated Flights into `EventShell` tabbed navigation.
    - Unit tests for domain and controller.
- **Material files/components changed**:
    - `lib/domain/entities/flight.dart` (NEW)
    - `lib/domain/repositories/flights_repository.dart` (NEW)
    - `lib/infrastructure/cloud/flight_codec.dart` (NEW)
    - `lib/infrastructure/cloud/supabase_flights_repository.dart` (NEW)
    - `lib/application/flights_controller.dart` (NEW)
    - `lib/presentation/flights/*` (NEW UI)
    - `lib/presentation/events/event_shell.dart`
    - `lib/presentation/cloud_app.dart`
    - `lib/main.dart`
    - `supabase/migrations/20260920090000_flights.sql` (NEW)
    - `test/flights_*_test.dart` (NEW)
    - `test/support/flights_fakes.dart` (NEW)
- **Verification performed and results**:
    - `flutter test` - 62 tests passed (including all flights tests).
    - `flutter analyze` - 0 errors, 0 warnings (excluding deprecation info).
- **What remains incomplete/unverified**:
    - Remote staging deployment and verification.
    - WASM DB checks (requires `node tools/db-test/verify.mjs` setup for flights).
- **Risks/blockers**: None.
- **Recommended next action**: Review implementation and then deploy to staging.
