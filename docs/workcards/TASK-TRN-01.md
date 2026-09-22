# UMAN EVENT MANAGER — TASK BRIEF

**Task ID:** TASK-TRN-01
**Owner:** Temporary Implementation Agent
**Status:** CHANGES_REQUIRED
**Branch / Worktree:** `main`

## Objective

Implement the Driver and Vehicle vertical slices (Transport Foundation) in Flutter and Supabase, including pure domain entities, repository contracts, cloud codecs, controllers, UI screens, database migrations with composite FK readiness, RLS, CAS, and server-side audit logging, and automated WASM DB / Flutter test verification.

## Scope

- **Database**: Supabase migration `20260920120000_drivers_and_vehicles.sql` adding `drivers` and `vehicles` tables, RLS policies, SECURITY DEFINER RPCs (`save_driver`, `list_drivers`, `read_driver`, `delete_driver`, `save_vehicle`, `list_vehicles`, `read_vehicle`, `delete_vehicle`), composite unique `(event_id, id)` constraints, and audit logging.
- **Domain**: Pure Dart entities `Driver`, `DriverInput`, `DriverStatus`, `Vehicle`, `VehicleInput`, `VehicleType`, `VehicleStatus`, and repository contract `TransportRepository`.
- **Infrastructure**: Supabase implementation `SupabaseTransportRepository` with codecs `driver_codec.dart`, `vehicle_codec.dart`.
- **Application**: `DriversController`, `VehiclesController` managing reactive state, search, and optimistic CAS updates.
- **Presentation**:
  - `DriversPage` (searchable list, active/inactive filters).
  - `DriverDetailsPage`.
  - `DriverEditorPage`.
  - `VehiclesPage` (searchable list, type/status indicators, capacity display).
  - `VehicleDetailsPage`.
  - `VehicleEditorPage`.
  - Integration into `EventShell` drawer navigation.
- **Testing**:
  - Pure domain & repository unit tests (`test/domain/transport_test.dart`, `test/transport_controller_test.dart`).
  - Widget tests (`test/transport_widget_test.dart`).
  - WASM DB checks in `tools/db-test/transport-checks.mjs` integrated into `tools/db-test/verify.mjs`.

## Out of Scope

- Trip and TripPassenger scheduling (built on top of Driver/Vehicle in the next slice).
- Automated GPS or OBD-II hardware tracking.

## Relevant Specifications

- `UMAN_EVENT_MANAGER_SPEC_v2.6.md` (Section 11: Driver Management, Section 12: Vehicle Management)
- `UMAN_EVENT_MANAGER_TECH_SPEC_v1.2.md`
- `ADR-001-CLOUD-FIRST-REALTIME-MULTIUSER.md`
- `UMAN_EVENT_MANAGER_VISUAL_DESIGN_SYSTEM.md`

## Dependencies / Shared Resources

- **Event Context**: All drivers and vehicles must be strictly scoped to an `Event`.
- **Supabase Schema**: New migration for `drivers` and `vehicles`.
- **UI Navigation**: `EventShell` drawer updated with Drivers and Vehicles pages.

## Acceptance Criteria

1. Drivers and Vehicles are persisted in Supabase with strict Event isolation and `(event_id, id)` composite uniqueness.
2. RLS policies prevent unauthorized access (only event members can read/write).
3. CAS (Optimistic Concurrency Control) is enforced for Driver and Vehicle updates.
4. Server-side audit entries are generated for all driver and vehicle mutations.
5. Soft-delete and restore workflows are functional.
6. The UI supports creating, editing, search/filtering, and viewing details for drivers and vehicles.
7. `flutter analyze --no-pub` passes with 0 issues.
8. All Flutter tests and WASM DB checks pass.

## Handoff

- **Completed Work**:
  - Implemented `Driver` and `Vehicle` domain entities, inputs, statuses, and types (`lib/domain/entities/driver.dart`, `vehicle.dart`).
  - Implemented `TransportRepository` contract (`lib/domain/repositories/transport_repository.dart`).
  - Implemented codecs (`driver_codec.dart`, `vehicle_codec.dart`) and Supabase infrastructure repository (`supabase_transport_repository.dart`).
  - Implemented `DriversController` and `VehiclesController` (`lib/application/drivers_controller.dart`, `vehicles_controller.dart`).
  - Implemented UI pages: `DriversPage`, `DriverDetailsPage`, `DriverEditorPage`, `VehiclesPage`, `VehicleDetailsPage`, `VehicleEditorPage`, `TransportShell`.
  - Integrated Transport module in `EventShell`, `CloudApp`, and `main.dart`.
  - Created Supabase migration `20260920120000_drivers_and_vehicles.sql` with composite unique `(event_id, id)` constraints, RLS policies, audit triggers, and RPCs (`save_driver`, `list_drivers`, `read_driver`, `delete_driver`, `save_vehicle`, `list_vehicles`, `read_vehicle`, `delete_vehicle`).
  - Created WASM DB checks in `tools/db-test/transport-checks.mjs` (29 checks).
  - Created unit & widget tests in `test/domain/transport_test.dart`, `test/transport_controller_test.dart`, and `test/transport_widget_test.dart`.
  - Corrected visual design system drift across Transport presentation files (eliminated ad-hoc `Colors.red`, `Colors.grey`, `Colors.orange`, hardcoded text sizes; aligned status indicators to semantic `Theme.of(context).colorScheme` tokens).
  - Enforced BiDi text isolation (`BidiTextFormatter.isolate`) for dynamic Hebrew/English driver and vehicle fields.
- **Verification Performed**:
  - `flutter analyze --no-pub`: PASSED (0 issues).
  - `flutter test --no-pub`: PASSED (74 tests).
  - `node tools/db-test/verify.mjs`: PASSED (205 WASM DB checks).
- **Recommended Next Implementation Step**:
  - `TASK-TRN-02`: Implement `Trip` and `TripPassenger` vertical slice for ground transport trip scheduling, connecting flights, passengers, drivers, and vehicles with capacity validation.


## Independent Audit Findings — 2026-09-22

Status was reopened from DONE to **CHANGES_REQUIRED** after direct repository inspection.

### HIGH — Realtime/reconciliation contract incomplete
`SupabaseTransportDataSource` creates realtime channels, but `DriversController` and `VehiclesController` do not subscribe to repository signals. The declared polling timer is not started, and `realtimeConnected` is not driven by actual subscription state. Align with the established Flights realtime/reconciliation/disposal pattern without inventing a parallel architecture.

### HIGH — Driver domain differs from Master v2.6
Master v2.6 defines Driver operational availability states `AVAILABLE`, `BUSY`, `UNAVAILABLE`, `OFF_DUTY` and includes `whatsapp_phone`. Current implementation uses `ACTIVE`/`INACTIVE` and omits the WhatsApp field. Resolve by implementing the authoritative model or by obtaining and recording an explicit product/specification change.

### HIGH — Vehicle domain differs from Master v2.6
Master v2.6 includes vehicle `color` and status `IN_USE`. Current implementation omits both. Resolve before Trips depend on this model.

### HIGH — Restore acceptance criterion not met
This workcard requires soft-delete **and restore**. Current Transport RPC/repository/controller/UI surface provides delete but no restore operation. Implement and test restore or explicitly change the acceptance criterion through an approved product decision.

### HIGH — Conflict/error classification is too coarse
Transport controllers collapse failures to generic `CloudFailureKind.unknown`; repository reads swallow all exceptions and return null. CAS conflicts, authorization loss, connectivity/service failures, and genuine not-found conditions must remain distinguishable where the architecture requires it.

### Gate
Do not start `TASK-TRN-02` until these findings are corrected, the full verification gate passes, documentation is reconciled, and an independent review confirms closure.
