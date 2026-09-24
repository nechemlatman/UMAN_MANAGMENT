# UMAN EVENT MANAGER — TASK BRIEF

**Task ID:** TASK-TRN-01
**Owner:** Codex Lead Builder
**Status:** REVIEW (closure corrections; final review and CI pending)
**Branch / Worktree:** `main` (actual shared checkout)

## Objective

Implement the Driver and Vehicle vertical slices (Transport Foundation) in Flutter and Supabase, including pure domain entities, repository contracts, cloud codecs, controllers, UI screens, database migrations with composite FK readiness, RLS, CAS, and server-side audit logging, and automated WASM DB / Flutter test verification.

## Scope

- **Database**: Supabase migration `20260920120000_drivers_and_vehicles.sql` adding `drivers` and `vehicles` tables, RLS policies, SECURITY DEFINER RPCs (`save_driver`, `list_drivers`, `read_driver`, `delete_driver`, `save_vehicle`, `list_vehicles`, `read_vehicle`, `delete_vehicle`), composite unique `(event_id, id)` constraints, and audit logging.
- **Domain**: Pure Dart entities `Driver`, `DriverInput`, `DriverStatus`, `Vehicle`, `VehicleInput`, `VehicleType`, `VehicleStatus`, and repository contract `TransportRepository`.
- **Infrastructure**: Supabase implementation `SupabaseTransportRepository` with codecs `driver_codec.dart`, `vehicle_codec.dart`.
- **Application**: `DriversController`, `VehiclesController` managing reactive state, search, and optimistic CAS updates.
- **Presentation**:
  - `DriversPage` (searchable list, operational availability filters).
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

## Current Handoff — 2026-09-24

**State: REVIEW, not DONE.** Codex Lead Builder retains implementation ownership.
The repair was committed concurrently as `52be6b3` and is already on `main`
(through `f3e8d8d`). The closure correction is being committed on the actual
`main` checkout. No claim of independent CI approval or production deployment.

### Implemented and locally verified

- Driver availability: AVAILABLE, BUSY, UNAVAILABLE, OFF_DUTY; WhatsApp phone.
  Vehicle color and IN_USE. Editors/details expose these fields and lists filter
  availability. Existing API/storage aliases `full_name`, `phone_number`, and
  `license_number` implement Master name/phone/license_info; license UI is now
  labeled License Info. These aliases retain existing stored data/API compatibility.
- Realtime canonical invalidation, reconnect and foreground refresh, serialized
  reads with reruns during invalidation, 20-second periodic reconciliation,
  access-loss clearing and subscription/repository disposal. The SDK uses one
  event-filtered channel for both Transport tables; pending removal is awaited.
- Driver/Vehicle restore with CAS, tombstones and correct before/after audit;
  deleted-list restore actions, preserved conflict drafts, sanitized errors.
- Repository scope checking; authorized absence alone yields null. CAS,
  authorization, validation, connectivity/service and unknown failures remain distinct.
- RPC execution restricted to authenticated users with transactional authorization;
  realtime publication repaired; changed-payload creation retries rejected;
  audit-insertion failure rolls back source mutation and version.

### Forward migration and operator attribution

Original `20260920120000_drivers_and_vehicles.sql` is unchanged. The corrective
migration is `20260924092718_transport_foundation_repair.sql`.

The owner explicitly approved ACTIVE -> AVAILABLE and INACTIVE -> UNAVAILABLE
on 2026-09-24. BUSY/OFF_DUTY are never inferred. Existing IDs, contact data,
creation metadata and tombstones survive; versions increase to invalidate drafts.

Independent review correctly rejected using the previous `updated_by` as the
migration audit actor. The pending corrective migration now follows
`supabase/README.md` / `supabase/provision.example.sql`: a trusted operator sets
`request.jwt.claim.sub` to the **actual approving Auth administrator**, in the
same database session before applying the migration. Existing rows require a
non-null, existing Auth actor; absence/invalid actor aborts and rolls back.
`updated_by` and new audit `actor_user_id` use that explicit actor. Existing audit
rows remain immutable; new snapshots identify the legacy mapping as a migration.
An empty fresh install requires no actor because no driver data is changed.
This is operator attribution, not a per-driver manager status-choice workflow.

Read-only staging migration inspection on 2026-09-24 showed only
202609170001, 20260919201737, 20260919202929, 20260920063325. Neither Transport
migration has been applied there; correcting the pending repair does not rewrite
staging history. No remote mutations were performed. For any other deployment,
inspect history before applying; do not rerun or modify an applied migration.

### Verification and remaining gate

- Formatting checked on all Transport-changed Dart files.
- Full Flutter suite: 88 tests (includes architecture/security, RTL/LTR restore,
  draft preservation, SDK HTTP/WebSocket, reconciliation, revocation and disposal).
- PostgreSQL/PGlite: 304 checks, including upgrading actual legacy active and
  deleted drivers, explicit approver distinct from the previous editor, missing
  actor rollback, privileges, CAS, atomic audit and restore.
- Android debug APK built successfully. Physical-device walkthrough, two-account
  staging realtime and all iOS runtime gates remain unverified.
- Security scan: no findings across 306 tracked files and 432 history blobs at scan time.
- Final analyzer/format/test evidence is recorded in STATUS.md after completion.
- Independent review accepted the core repair but requested migration attribution
  and documentation corrections. Those are corrected here; **final review and
  Core Verification on the resulting commit remain pending**. Earlier CI on
  `f3e8d8d` does not verify this closure correction.

Next task remains `TASK-TRN-02` (Trip/TripPassenger). Do not start it until the
review and CI closure gate is satisfied. Latest owner instruction limits this
checkpoint to closure corrections, verification and commit.
