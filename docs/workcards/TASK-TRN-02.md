# UMAN EVENT MANAGER — TASK BRIEF

**Task ID:** TASK-TRN-02  
**Owner:** Unassigned (PLANNED)  
**Status:** PLANNED  
**Branch / Worktree:** TBD (`codex/trips-and-passengers`)  

---

## Objective

Implement the **Trip** and **TripPassenger** vertical slice for ground transport trip scheduling in Flutter and Supabase. This slice links flights, passengers, drivers, and vehicles while enforcing strict event-scoped composite foreign-key integrity, capacity validation, CAS optimistic concurrency control, transactional server audit logging, soft-delete/restore capabilities, and realtime propagation.

---

## Scope

- **Database (`supabase/migrations/`)**:
  - Versioned Supabase migration adding `trips` and `trip_passengers` tables.
  - Unique composite constraint `(event_id, id)` on `trips` to allow child foreign keys.
  - Composite same-event foreign key constraints:
    - `trips(event_id, driver_id)` → `drivers(event_id, id)`
    - `trips(event_id, vehicle_id)` → `vehicles(event_id, id)`
    - `trips(event_id, related_flight_id)` → `flights(event_id, id)`
    - `trip_passengers(event_id, trip_id)` → `trips(event_id, id)`
    - `trip_passengers(event_id, person_id)` → `people(event_id, id)`
  - Row Level Security (RLS) policies enforcing `is_event_admin(event_id)` authorization.
  - Transactional `SECURITY DEFINER` RPCs (`save_trip`, `read_trip`, `list_trips`, `delete_trip`, `restore_trip`, `save_trip_passenger`, `list_trip_passengers`, `delete_trip_passenger`, `restore_trip_passenger`).
  - Server audit triggers inserting records into `public.audit_entries`.
- **Domain (`lib/domain/entities/`, `lib/domain/repositories/`)**:
  - Pure Dart entities: `Trip`, `TripPassenger`, `TripDirection` (`INBOUND`, `OUTBOUND`, `LOCAL`), `TripStatus` (`PLANNED`, `CONFIRMED`, `IN_PROGRESS`, `COMPLETED`, `CANCELLED`), `TripPassengerStatus` (`ASSIGNED`, `CONFIRMED`, `PICKED_UP`, `DROPPED_OFF`, `NO_SHOW`, `CANCELLED`).
  - Input objects: `TripInput`, `TripPassengerInput`.
  - Repository contract: `TripsRepository`.
- **Infrastructure (`lib/infrastructure/cloud/`)**:
  - `SupabaseTripsRepository` implementing `TripsRepository`.
  - Codecs: `trip_codec.dart`, `trip_passenger_codec.dart`.
- **Application (`lib/application/`)**:
  - `TripsController` handling reactive state, list filtering (direction, status, date, search), optimistic CAS updates, vehicle capacity warning derivation, realtime channel subscriptions, bounded periodic background reconciliation (30s), error classification, and proper subscription disposal.
- **Presentation (`lib/presentation/transport/`)**:
  - `TripsPage` (searchable/filterable list with capacity indicators and linked flight badges).
  - `TripDetailsPage` (route, flight link, driver, vehicle, capacity status, passenger list, audit history).
  - `TripEditorPage` (create/edit trip, assign driver/vehicle/flight).
  - `TripPassengerEditor` (add/edit/remove passenger, pickup location/notes, status).
  - `EventShell` drawer/navigation integration under Transport module.
  - BiDi text isolation (`BidiTextFormatter.isolate`).
  - Visual Design System compliance (`Theme.of(context).colorScheme`).
- **Testing & Verification**:
  - Unit tests for pure domain entities and capacity math (`test/domain/trip_test.dart`).
  - Controller tests (`test/trips_controller_test.dart`).
  - Presentation widget tests (`test/trip_widget_test.dart`).
  - WASM DB checks in `tools/db-test/trip-checks.mjs` integrated into `verify.mjs`.

---

## Out of Scope

- Automated GPS or OBD-II hardware location tracking.
- Automated modification of trip schedules or passenger lists upon flight delay/cancellation (Manager Sovereignty Principle).
- Accommodation assignment, finance, or rules engine features beyond transport capacity alerts.
- Driver and Vehicle foundation bug fixes (must be resolved in `TASK-TRN-01` before starting).

---

## Relevant Specifications

- `UMAN_EVENT_MANAGER_SPEC_v2.6.md` (Section 13: Transport Management)
- `UMAN_EVENT_MANAGER_TECH_SPEC_v1.2.md` (Domain migration review, composite FKs, CAS, Audit, Realtime)
- `ADR-001-CLOUD-FIRST-REALTIME-MULTIUSER.md`
- `UMAN_EVENT_MANAGER_VISUAL_DESIGN_SYSTEM.md`

---

## Dependencies / Shared Resources

1. **`TASK-TRN-01` Foundation Repair Gate**:
   - `TASK-TRN-01` audit corrections must be verified and merged into `main` before `TASK-TRN-02` work begins.
   - `drivers` and `vehicles` tables must have unique `(event_id, id)` constraints and restored Spec v2.6 fields/enums.
2. **`TASK-FLT-01` Flights Slice**:
   - `flights` table must exist with unique `(event_id, id)` constraint.
3. **`TASK-PEOPLE-01` People Slice**:
   - `people` table must exist with unique `(event_id, id)` constraint.
4. **Supabase Migration**:
   - Requires new versioned SQL migration for `trips` and `trip_passengers`.

---

## Domain Models & Database Schema

### Trip Entity

| Field | Type | DB Constraints / Semantics |
|---|---|---|
| `id` | UUIDv4 | Primary key (`gen_random_uuid()`) |
| `event_id` | UUIDv4 | FK to `events(id)` on delete restrict |
| `direction` | Enum | `INBOUND`, `OUTBOUND`, `LOCAL` |
| `origin` | String | Non-empty, max 200 chars |
| `destination` | String | Non-empty, max 200 chars |
| `scheduled_departure_utc` | DateTime | Timestamptz (must be < `scheduled_arrival_utc`) |
| `scheduled_arrival_utc` | DateTime | Timestamptz |
| `actual_departure_utc` | DateTime? | Nullable timestamptz |
| `actual_arrival_utc` | DateTime? | Nullable timestamptz |
| `driver_id` | UUIDv4? | Composite FK `(event_id, driver_id)` → `drivers(event_id, id)` |
| `vehicle_id` | UUIDv4? | Composite FK `(event_id, vehicle_id)` → `vehicles(event_id, id)` |
| `related_flight_id` | UUIDv4? | Composite FK `(event_id, related_flight_id)` → `flights(event_id, id)` |
| `status` | Enum | `PLANNED`, `CONFIRMED`, `IN_PROGRESS`, `COMPLETED`, `CANCELLED` |
| `notes` | String? | Max 10,000 chars |
| `is_locked` | bool | Manager lock flag (default false) |
| `created_at_utc` | DateTime | Server default `now()` |
| `updated_at_utc` | DateTime | Server default `now()` |
| `is_deleted` | bool | Soft-delete flag (default false) |
| `version` | bigint | CAS concurrency version (default 1) |

### TripPassenger Entity

| Field | Type | DB Constraints / Semantics |
|---|---|---|
| `id` | UUIDv4 | Primary key (`gen_random_uuid()`) |
| `event_id` | UUIDv4 | FK to `events(id)` on delete restrict |
| `trip_id` | UUIDv4 | Composite FK `(event_id, trip_id)` → `trips(event_id, id)` |
| `person_id` | UUIDv4 | Composite FK `(event_id, person_id)` → `people(event_id, id)` |
| `pickup_location` | String? | Nullable, max 200 chars |
| `pickup_notes` | String? | Nullable, max 1,000 chars |
| `passenger_status` | Enum | `ASSIGNED`, `CONFIRMED`, `PICKED_UP`, `DROPPED_OFF`, `NO_SHOW`, `CANCELLED` |
| `notes` | String? | Nullable, max 5,000 chars |
| `created_at_utc` | DateTime | Server default `now()` |
| `updated_at_utc` | DateTime | Server default `now()` |
| `is_deleted` | bool | Soft-delete flag (default false) |
| `version` | bigint | CAS concurrency version (default 1) |

---

## Detailed Technical Semantics

### 1. Same-Event Composite Foreign Keys
To prevent cross-event data leakage (e.g. linking a Trip in Event A to a Driver or Person in Event B), all child tables MUST use composite foreign keys:
```sql
alter table public.trips add unique (event_id, id);

alter table public.trips
    add constraint trips_driver_event_fkey
        foreign key (event_id, driver_id) references public.drivers(event_id, id) on delete restrict,
    add constraint trips_vehicle_event_fkey
        foreign key (event_id, vehicle_id) references public.vehicles(event_id, id) on delete restrict,
    add constraint trips_flight_event_fkey
        foreign key (event_id, related_flight_id) references public.flights(event_id, id) on delete set null;

alter table public.trip_passengers
    add constraint trip_passengers_trip_event_fkey
        foreign key (event_id, trip_id) references public.trips(event_id, id) on delete restrict,
    add constraint trip_passengers_person_event_fkey
        foreign key (event_id, person_id) references public.people(event_id, id) on delete restrict;
```

### 2. Flight Linkage Semantics (Manager Sovereignty)
- A trip MAY reference a `related_flight_id`.
- If the linked flight's status changes to `DELAYED` or `CANCELLED`, the system MUST generate an advisory warning for the Control Center / Unresolved Items.
- The system MUST NEVER automatically alter trip schedules, departure times, or passenger manifests. Manager confirmation is strictly required.

### 3. Driver & Vehicle Linkage Semantics
- Driver and vehicle assignments are optional (nullable FKs).
- Reassigning a driver or vehicle preserves complete historical attribution via server `audit_entries`.

### 4. Capacity Semantics
- Active passenger count = count of `TripPassenger` records where `passenger_status != CANCELLED` and `is_deleted = false`.
- A trip is **OVER CAPACITY** if and only if `active_passengers > vehicle.capacity`.
- `active_passengers == vehicle.capacity` is VALID (at capacity).
- The system MUST NEVER automatically remove passengers to resolve overallocation. Over-capacity conditions trigger visual warnings in UI and alerts in Unresolved Items.

### 5. CAS & Concurrency Requirements
- Every mutation RPC accepts `p_expected_version bigint`.
- On update, the RPC checks: `where event_id=p_event_id and id=p_id for update`. If `version <> p_expected_version` or `is_deleted = true`, the RPC throws SQLSTATE `40001` (`Record changed`).
- Controllers handle CAS failure by displaying a stale write alert and prompting the user to reload canonical state while retaining local uncommitted text in form controllers.

### 6. Server Audit Requirements
- All creation, update, soft-delete, and restore RPCs MUST atomically record mutations in `public.audit_entries` in the same transaction:
```sql
insert into public.audit_entries(event_id, actor_user_id, entity_type, entity_id, operation, old_value, new_value)
values(p_event_id, actor, 'trips', r.id::text, case when created then 'CREATE' else 'UPDATE' end, before_row, to_jsonb(r));
```

### 7. Manager Overrides & `is_locked`
- `is_locked = true` on `Trip` signals that manual values are explicitly locked against automated rule re-derivations. Manager can toggle `is_locked` at any time.

### 8. Realtime & Reconciliation
- `SupabaseTripsRepository` subscribes to Supabase realtime broadcast events for `trips` and `trip_passengers`.
- Realtime payload invalidates local state and triggers background fetch of canonical rows.
- Periodic background polling interval (30 seconds) ensures state reconciliation during transient connection drops.
- Subscription handles proper cleanup on controller disposal / logout.

### 9. Soft-Delete & Restore
- Soft-delete sets `is_deleted = true`, `deleted_at_utc = now()`.
- Dedicated `restore_trip` and `restore_trip_passenger` RPCs reverse soft deletion (`is_deleted = false`, `deleted_at_utc = null`), increment `version`, and log a `RESTORE` audit entry.

---

## Acceptance Criteria

1. **Composite Integrity**: Database schema and RPCs strictly prevent referencing drivers, vehicles, flights, or people from a different event.
2. **Capacity Validation**: Over-capacity trips (`active_passengers > vehicle.capacity`) produce non-blocking warnings in UI and alerts in Unresolved Items without auto-evicting passengers.
3. **Flight Independence**: Linked flight delays/cancellations trigger alerts but never mutate trip fields without manager action.
4. **CAS Concurrency**: Concurrent edits with mismatched versions fail with SQLSTATE `40001`.
5. **Server Audit**: All mutations append immutable `audit_entries` rows in the same transaction.
6. **Soft-Delete & Restore**: Both `trips` and `trip_passengers` support soft deletion and restoration via transactional RPCs.
7. **Realtime Sync**: Mutations on one client propagate automatically to subscribed multi-user sessions.
8. **Clean Code & Build**: `flutter analyze --no-pub` returns 0 issues; all unit/widget tests and WASM DB checks pass.

---

## Verification Required

- `flutter analyze --no-pub`
- `flutter test --no-pub` (Unit tests in `test/domain/trip_test.dart`, `test/trips_controller_test.dart`, widget tests in `test/trip_widget_test.dart`)
- `node tools/db-test/verify.mjs` (WASM DB checks in `tools/db-test/trip-checks.mjs`)

---

## External Gates

1. **`TASK-TRN-01` Repair Gate**: Driver & Vehicle foundation findings must be resolved and verified on `main`.
2. **Two-Account Independent Session Gate**: Realtime sync, stale CAS rejection, and reconnect behavior verified across two authenticated admin accounts on Supabase staging.
3. **Android / iOS Delivery Gate**: Android APK build and iOS static review clean.
