# UMAN EVENT MANAGER — TASK BRIEF

**Task ID:** TASK-TRN-02  
**Owner:** Unassigned (PLANNED)  
**Status:** PLANNED  
**Branch / Worktree:** TBD  

---

## 1. Objective

Prepare the **Trip** and **TripPassenger** vertical slice for ground transport trip scheduling in Flutter and Supabase. This slice links flights, passengers, drivers, and vehicles while enforcing strict event-scoped composite foreign-key integrity, vehicle capacity validation, CAS optimistic concurrency control, transactional server audit logging, soft-delete/restore capabilities, and realtime state propagation.

---

## 2. Structural Breakdown: Specifications, Conventions, & Implementation Proposals

To keep this brief implementation-ready while maintaining strict documentation accuracy, requirements are separated into three tiers:

### Tier A: Authoritative Specification Requirements
*(Mandatory domain semantics from `UMAN_EVENT_MANAGER_SPEC_v2.6.md`, `TECH_SPEC_v1.2`, and `ADR-001`)*
- **Trip Entity & Fields**: Direction (`INBOUND`, `OUTBOUND`, `LOCAL`), origin, destination, `scheduled_departure_utc`, `scheduled_arrival_utc`, optional `actual_departure_utc` / `actual_arrival_utc`, optional `driver_id`, optional `vehicle_id`, optional `related_flight_id`, status (`PLANNED`, `CONFIRMED`, `IN_PROGRESS`, `COMPLETED`, `CANCELLED`), notes, `is_locked`.
- **TripPassenger Entity & Fields**: `trip_id`, `person_id`, optional `pickup_location`, optional `pickup_notes`, `passenger_status` (`ASSIGNED`, `CONFIRMED`, `PICKED_UP`, `DROPPED_OFF`, `NO_SHOW`, `CANCELLED`), notes.
- **Flight Linkage & Manager Sovereignty**: Referencing a flight is optional. Flight schedule changes, delays, or cancellations generate advisories but **never** automatically alter trip departure times or passenger manifests.
- **Vehicle Capacity Rules**: Active passenger count = count of non-deleted `TripPassenger` records where `passenger_status != CANCELLED`. Trip is **over capacity** iff `active_passengers > vehicle.capacity`. Exactly at capacity is valid. Over-capacity generates advisories; system **never** silently removes passengers.
- **Same-Event Scope**: All records are strictly event-scoped. Cross-event references (e.g. linking a Trip in Event A to a Driver or Person in Event B) are strictly prohibited.
- **Transactional Audit**: All material mutations must generate immutable server audit entries in `public.audit_entries` in the same database transaction.

### Tier B: Established Project Architecture & Conventions
*(Patterns established in Event, People, and Flights vertical slices)*
- **Database & RLS**: PostgreSQL tables with composite unique constraints `(event_id, id)`, RLS policies delegating authorization to `public.is_event_admin(event_id)`, restricted `SECURITY DEFINER` RPCs.
- **Concurrency (CAS)**: Optimistic Concurrency Control using server-managed `version bigint`. Mismatched expected versions throw SQLSTATE `40001` (`Record changed`).
- **Realtime & Reconciliation**: Realtime invalidation channels invalidate local repository state, combined with bounded periodic background reconciliation polling, foreground reconnect handlers, and proper stream disposal on controller teardown.
- **Soft-Delete & Restore**: Standard `is_deleted boolean` and `deleted_at_utc timestamptz` columns, with repository and server function support for soft deletion and restoration.
- **Flutter Layering**: Pure Dart domain entities, value objects, codecs, Supabase repository implementations, reactive BLoC/Cubit/Controller state management, BiDi text isolation (`BidiTextFormatter.isolate`), and semantic UI design system tokens (`Theme.of(context).colorScheme`).

### Tier C: Proposed Implementation Details
*(Suggested technical choices subject to implementation agent finalization)*
- **Proposed Database Table & Migration Structure**: Suggested table names `public.trips` and `public.trip_passengers` with same-event composite foreign keys `(event_id, driver_id)`, `(event_id, vehicle_id)`, `(event_id, related_flight_id)`, `(event_id, trip_id)`, `(event_id, person_id)`.
- **Proposed RPC API Surface**: `save_trip`, `read_trip`, `list_trips`, `delete_trip`, `restore_trip`, `save_trip_passenger`, `list_trip_passengers`, `delete_trip_passenger`, `restore_trip_passenger`.
- **Proposed UI Screens**: `TripsPage` (filterable list with capacity indicators), `TripDetailsPage`, `TripEditorPage`, `TripPassengerEditor`.

---

## 3. Out of Scope

- Automated GPS or driver location tracking.
- Automated modification of trip schedules upon linked flight changes.
- Accommodation assignment, finance, or rules engine features beyond transport capacity alerts.
- Foundation Driver/Vehicle repairs (must be completed under `TASK-TRN-01` before starting `TASK-TRN-02`).

---

## 4. Relevant Specifications

- `UMAN_EVENT_MANAGER_SPEC_v2.6.md` (Section 13: Transport Management)
- `UMAN_EVENT_MANAGER_TECH_SPEC_v1.2.md` (Domain migration review, composite FKs, CAS, Audit, Realtime)
- `ADR-001-CLOUD-FIRST-REALTIME-MULTIUSER.md`
- `UMAN_EVENT_MANAGER_VISUAL_DESIGN_SYSTEM.md`

---

## 5. Dependencies & Prerequisites

1. **`TASK-TRN-01` Foundation Repair Gate**:
   - `TASK-TRN-01` audit corrections must be resolved and verified on `main`.
   - `drivers` and `vehicles` tables must have unique `(event_id, id)` constraints and Spec v2.6 reconciled fields.
2. **`TASK-FLT-01` Verification Gate**:
   - `flights` table verified with unique `(event_id, id)` constraint.
3. **`TASK-PEOPLE-01` Verification Gate**:
   - `people` table verified with unique `(event_id, id)` constraint.

---

## 6. Domain Model & Database Schema Specification

### Trip Entity (Spec v2.6 Section 13)

| Field | Spec / Data Type | Notes & Operational Rules |
|---|---|---|
| `id` | UUIDv4 | Server-generated primary key |
| `event_id` | UUIDv4 | Foreign key to `events(id)` |
| `direction` | Enum (`INBOUND`, `OUTBOUND`, `LOCAL`) | Operational transport direction |
| `origin` | String | Transport pickup point |
| `destination` | String | Transport drop-off point |
| `scheduled_departure_utc` | DateTime (Timestamptz) | Scheduled departure |
| `scheduled_arrival_utc` | DateTime (Timestamptz) | Scheduled arrival (must be > departure) |
| `actual_departure_utc` | DateTime? (Timestamptz) | Nullable actual departure |
| `actual_arrival_utc` | DateTime? (Timestamptz) | Nullable actual arrival |
| `driver_id` | UUIDv4? | Optional FK to Driver |
| `vehicle_id` | UUIDv4? | Optional FK to Vehicle |
| `related_flight_id` | UUIDv4? | Optional FK to Flight |
| `status` | Enum (`PLANNED`, `CONFIRMED`, `IN_PROGRESS`, `COMPLETED`, `CANCELLED`) | Trip lifecycle status |
| `notes` | String? | Optional notes |
| `is_locked` | bool | Manager lock flag (default false) |
| `created_at_utc` | DateTime | Server timestamp |
| `updated_at_utc` | DateTime | Server timestamp |
| `is_deleted` | bool | Soft-delete status |
| `version` | bigint | CAS version counter |

### TripPassenger Entity (Spec v2.6 Section 13)

| Field | Spec / Data Type | Notes & Operational Rules |
|---|---|---|
| `id` | UUIDv4 | Server-generated primary key |
| `event_id` | UUIDv4 | Foreign key to `events(id)` |
| `trip_id` | UUIDv4 | FK to Trip |
| `person_id` | UUIDv4 | FK to Person |
| `pickup_location` | String? | Optional specific pickup point |
| `pickup_notes` | String? | Optional pickup instructions |
| `passenger_status` | Enum (`ASSIGNED`, `CONFIRMED`, `PICKED_UP`, `DROPPED_OFF`, `NO_SHOW`, `CANCELLED`) | Passenger transit status |
| `notes` | String? | Optional notes |
| `created_at_utc` | DateTime | Server timestamp |
| `updated_at_utc` | DateTime | Server timestamp |
| `is_deleted` | bool | Soft-delete status |
| `version` | bigint | CAS version counter |

---

## 7. Operational & Concurrency Semantics

### Flight Linkage & Manager Sovereignty
- A trip MAY reference a `related_flight_id`.
- If the linked flight changes status (e.g. `DELAYED` or `CANCELLED`), the system generates an advisory alert in the Control Center / Unresolved Items.
- The system **never** automatically modifies trip schedules or passenger manifests. Manager review is required.

### Vehicle Capacity & Passenger Overallocation
- Active passengers = `passenger_status != CANCELLED` and `is_deleted = false`.
- A trip is **over capacity** iff `active_passengers > vehicle.capacity`.
- `active_passengers == vehicle.capacity` is valid.
- System **never** automatically evicts passengers. Over-capacity condition displays visual warnings in UI.

### Concurrency, Audit, Realtime, & Soft-Delete (Project Patterns)
- **CAS**: RPC updates compare expected `version`. Mismatches throw SQLSTATE `40001`.
- **Audit**: Mutations append rows to `public.audit_entries` in the same transaction.
- **Realtime**: Subscriptions invalidate local state; bounded periodic reconciliation fetches canonical rows.
- **Soft-Delete / Restore**: Standard `is_deleted` columns with restore operations.

---

## 8. Acceptance Criteria & Verification

1. **Composite Integrity**: Database schema and RPCs prevent referencing drivers, vehicles, flights, or people from a different event.
2. **Capacity Validation**: Over-capacity trips produce visual warnings without auto-evicting passengers.
3. **Flight Independence**: Linked flight delays trigger alerts without mutating trip fields.
4. **CAS Concurrency**: Concurrent edits with mismatched versions fail cleanly.
5. **Server Audit**: Mutations append immutable `audit_entries` rows in the same transaction.
6. **Realtime Sync**: State updates propagate across multi-user sessions.
7. **Verification**: `flutter analyze --no-pub`, `flutter test --no-pub`, and `node tools/db-test/verify.mjs` pass cleanly.

---

## 9. Unresolved Decisions & Implementation Proposals

- **UPD-001 (Trip Status Auto-Transition)**: Whether entering `actual_arrival_utc` should automatically move `Trip.status` to `COMPLETED` or require explicit manager command is unresolved in Spec v2.6. Proposed: require explicit manager transition via RPC to honor Manager Sovereignty.
- **UPD-002 (Pickup Location Defaults)**: Whether `TripPassenger.pickup_location` defaults to the person's accommodation address or flight arrival airport when null is unspecified. Proposed: preserve as explicit source input (nullable text).
- **Proposed DB Structure**: Proposed exact migration SQL, RPC function names, and composite FK constraints are implementation proposals to be validated by the implementation agent during migration creation.
