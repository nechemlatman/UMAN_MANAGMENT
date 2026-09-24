# UMAN EVENT MANAGER — TASK BRIEF

**Task ID:** TASK-ACC-01  
**Owner:** Unassigned (PLANNED)  
**Status:** PLANNED  
**Branch / Worktree:** TBD  

---

## 1. Objective

Prepare the **Accommodation Foundation** vertical slice in Flutter and Supabase, establishing housing logistics across the four-level hierarchy (**Apartment → Room → SleepingPlace → AccommodationAssignment**). This slice enforces `[start_date, end_date)` civil date semantics, same-day turnover validation, mathematical interval overlap detection, capacity overrides, strict same-event composite foreign-key integrity, CAS optimistic concurrency control, transactional server audit logging, soft-delete/restore capabilities, and realtime state propagation.

---

## 2. Structural Breakdown: Specifications, Conventions, & Implementation Proposals

Requirements are structured into three distinct tiers:

### Tier A: Authoritative Specification Requirements
*(Mandatory domain semantics from `UMAN_EVENT_MANAGER_SPEC_v2.6.md` Section 14, `TECH_SPEC_v1.2`, and `ADR-001`)*
- **Hierarchy & Data Models**:
  - `Apartment`: `id`, `event_id`, `name`, `address`, `hebrew_address`, `floor`, `entry_code`, `landlord_name`, `landlord_phone`, `notes`, `status` (`ACTIVE`, `UNAVAILABLE`, `CLOSED`), `total_cost`, `cost_currency`, `cost_notes`.
  - `Room`: `id`, `event_id`, `apartment_id`, `name_or_number`, `floor`, `description`, `notes`.
  - `SleepingPlace`: `id`, `event_id`, `room_id`, `label`, `type` (`REGULAR_BED`, `BUNK_BED`, `SOFA_BED`, `MATTRESS`, `CUSTOM`), `custom_type_name` (required if type is `CUSTOM`), `position_notes`, `is_active`.
  - `AccommodationAssignment`: `id`, `event_id`, `sleeping_place_id`, `person_id`, `start_date` (CivilDate), `end_date` (CivilDate), `status` (`ACTIVE`, `TEMPORARY`, `CANCELLED`), `notes`, `is_locked`.
- **Date Semantics (`[start_date, end_date)`)**:
  - `start_date` is **inclusive** (first night person sleeps there).
  - `end_date` is **exclusive** (checkout day; person does not sleep there on this night).
- **Same-Day Turnover**:
  - Checkout and checkin on the same date on the same bed do **not** conflict (e.g. Person A checkout on Oct 3 and Person B checkin on Oct 3).
- **Overlap Detection**:
  - Two active assignments (`status != CANCELLED` and `is_deleted = false`) on the same `sleeping_place` overlap if their `[start_date, end_date)` intervals mathematically intersect ($\max(start_A, start_B) < \min(end_A, end_B)$).
  - When an overlap is detected, the system generates an `ACCOMMODATION_OVERLAP` alert. The manager resolves this manually.
- **Capacity Override**:
  - Managers may explicitly override standard capacity rules (e.g. placing an extra mattress in a room). This is achieved using the `is_locked` flag on the assignment with mandatory `notes` explaining the override.
  - *Specification Distinction*: Spec v2.6 treats Overlap Detection and Capacity Override as separate concepts. `is_locked` is explicitly specified for Capacity Overrides. Whether `is_locked` also suppresses overlap alerts is unresolved in Spec v2.6 (see Tier C / Section 9).
- **Reassignment & Sovereignty**:
  - Reassigning a person requires creating a new assignment and ending/cancelling the previous one. The system **never** silently mutates existing assignments.
- **Same-Event Scope**: All records are strictly event-scoped. Cross-event bed or occupant linkage is prohibited.
- **Transactional Audit**: All material mutations generate immutable server audit entries in `public.audit_entries` in the same database transaction.

### Tier B: Established Project Architecture & Conventions
*(Patterns established in Event, People, and Flights vertical slices)*
- **Database & RLS**: PostgreSQL tables with composite unique constraints `(event_id, id)`, RLS policies delegating authorization to `public.is_event_admin(event_id)`, restricted `SECURITY DEFINER` RPCs.
- **Concurrency (CAS)**: Optimistic Concurrency Control using server-managed `version bigint`. Mismatched expected versions throw SQLSTATE `40001` (`Record changed`).
- **Realtime & Reconciliation**: Realtime invalidation channels invalidate local repository state, combined with bounded periodic background reconciliation polling, foreground reconnect handlers, and proper stream disposal on controller teardown.
- **Soft-Delete & Restore**: Standard `is_deleted boolean` and `deleted_at_utc timestamptz` columns, with repository and server function support for soft deletion and restoration.
- **Flutter Layering**: Pure Dart domain entities, value objects (`CivilDate`), codecs, Supabase repository implementations, reactive BLoC/Cubit/Controller state management, BiDi text formatting (`BidiTextFormatter.isolate`), and semantic UI design system tokens (`Theme.of(context).colorScheme`).

### Tier C: Proposed Implementation Details
*(Suggested technical choices subject to implementation agent finalization)*
- **Proposed Database Table & Migration Structure**: Suggested table names `public.apartments`, `public.rooms`, `public.sleeping_places`, `public.accommodation_assignments` with same-event composite foreign keys `(event_id, apartment_id)`, `(event_id, room_id)`, `(event_id, sleeping_place_id)`, `(event_id, person_id)`.
- **Proposed RPC API Surface**: `save_apartment`, `list_apartments`, `delete_apartment`, `restore_apartment`, `save_room`, `list_rooms`, `delete_room`, `restore_room`, `save_sleeping_place`, `list_sleeping_places`, `delete_sleeping_place`, `restore_sleeping_place`, `save_accommodation_assignment`, `list_accommodation_assignments`, `delete_accommodation_assignment`, `restore_accommodation_assignment`.
- **Proposed UI Screens**: `ApartmentsPage` (list with occupancy summaries), `ApartmentDetailsPage` (hierarchical tree view), `ApartmentEditorPage`, `RoomEditorPage`, `SleepingPlaceEditorPage`, `AccommodationAssignmentEditor`.

---

## 3. Out of Scope

- Automated hotel PMS or channel manager API integrations.
- Automated allocation of unassigned people to beds (Manager Sovereignty Principle).
- Financial expense/payment allocations across room occupants (deferred under OPD-002/003).

---

## 4. Relevant Specifications

- `UMAN_EVENT_MANAGER_SPEC_v2.6.md` (Section 14: Accommodation & Sleeping Logistics)
- `UMAN_EVENT_MANAGER_TECH_SPEC_v1.2.md` (Domain migration review, composite FKs, CAS, Audit, Realtime)
- `ADR-001-CLOUD-FIRST-REALTIME-MULTIUSER.md`
- `UMAN_EVENT_MANAGER_VISUAL_DESIGN_SYSTEM.md`

---

## 5. Dependencies & Prerequisites

1. **`TASK-PEOPLE-01` Verification Gate**:
   - `people` table verified with unique `(event_id, id)` constraint for `AccommodationAssignment.person_id` foreign key.
2. **Event Scoping Foundation**:
   - `events` table and RLS authorization helpers (`is_event_admin`).

---

## 6. Domain Hierarchy & Schema Specification (Spec v2.6 Section 14)

### 1. Apartment Entity
* **`id`**: UUIDv4 (Primary key)
* **`event_id`**: UUIDv4 (FK to `events(id)`)
* **`name`**: String (Apartment identifier)
* **`address`**: String (Physical address)
* **`hebrew_address`**: String? (Optional Hebrew address)
* **`floor`**: String? (Optional floor)
* **`entry_code`**: String? (Optional entry/door code)
* **`landlord_name`**: String? (Optional landlord name)
* **`landlord_phone`**: String? (Optional landlord phone)
* **`notes`**: String? (Optional notes)
* **`status`**: Enum (`ACTIVE`, `UNAVAILABLE`, `CLOSED`)
* **`total_cost`**: Decimal? (Optional total cost)
* **`cost_currency`**: String? (ISO 4217 currency code)
* **`cost_notes`**: String? (Optional financial notes)
* **`created_at_utc`**, **`updated_at_utc`**: Timestamptz
* **`is_deleted`**: bool
* **`version`**: bigint

### 2. Room Entity
* **`id`**: UUIDv4 (Primary key)
* **`event_id`**: UUIDv4 (FK to `events(id)`)
* **`apartment_id`**: UUIDv4 (FK to Apartment)
* **`name_or_number`**: String (Room name or number)
* **`floor`**: String? (Optional floor)
* **`description`**: String? (Optional description)
* **`notes`**: String? (Optional notes)
* **`created_at_utc`**, **`updated_at_utc`**: Timestamptz
* **`is_deleted`**: bool
* **`version`**: bigint

### 3. SleepingPlace Entity
* **`id`**: UUIDv4 (Primary key)
* **`event_id`**: UUIDv4 (FK to `events(id)`)
* **`room_id`**: UUIDv4 (FK to Room)
* **`label`**: String (Bed/sleeping place label)
* **`type`**: Enum (`REGULAR_BED`, `BUNK_BED`, `SOFA_BED`, `MATTRESS`, `CUSTOM`)
* **`custom_type_name`**: String? (Required if `type` == `CUSTOM`)
* **`position_notes`**: String? (Optional location notes)
* **`is_active`**: bool (Default true)
* **`created_at_utc`**, **`updated_at_utc`**: Timestamptz
* **`is_deleted`**: bool
* **`version`**: bigint

### 4. AccommodationAssignment Entity
* **`id`**: UUIDv4 (Primary key)
* **`event_id`**: UUIDv4 (FK to `events(id)`)
* **`sleeping_place_id`**: UUIDv4 (FK to SleepingPlace)
* **`person_id`**: UUIDv4 (FK to Person)
* **`start_date`**: CivilDate (Inclusive check-in date)
* **`end_date`**: CivilDate (Exclusive checkout date)
* **`status`**: Enum (`ACTIVE`, `TEMPORARY`, `CANCELLED`)
* **`notes`**: String? (Optional notes)
* **`is_locked`**: bool (Default false; capacity override flag)
* **`created_at_utc`**, **`updated_at_utc`**: Timestamptz
* **`is_deleted`**: bool
* **`version`**: bigint

---

## 7. Operational & Concurrency Semantics

### Date Semantics & Turnover
- `start_date` is **inclusive** (first night person sleeps in the bed).
- `end_date` is **exclusive** (checkout date; person does NOT sleep there on this night).
- Same-day turnover: Assignment A with `end_date = 2025-10-03` and Assignment B with `start_date = 2025-10-03` on the same bed do NOT conflict.

### Overlap Detection vs. Capacity Override
- Two active assignments (`status != CANCELLED` and `is_deleted = false`) on the same `sleeping_place_id` overlap if their `[start_date, end_date)` intervals mathematically intersect.
- Overlaps trigger an `ACCOMMODATION_OVERLAP` advisory alert.
- `is_locked = true` with notes is specified for *Capacity Override* (e.g. placing an extra mattress in a room).
- Whether `is_locked` also suppresses overlap alerts is an unresolved specification relationship; the system does not silently mutate assignments.

### Concurrency, Audit, Realtime, & Soft-Delete (Project Patterns)
- **CAS**: Expected `version` check on mutations. Mismatches throw SQLSTATE `40001`.
- **Audit**: Transactional server entries in `public.audit_entries`.
- **Realtime**: Subscriptions invalidate local repository state; bounded periodic reconciliation fetches canonical rows.
- **Soft-Delete / Restore**: Standard `is_deleted` columns with restore operations.

---

## 8. Acceptance Criteria & Verification

1. **Hierarchical Navigation**: UI supports browsing and managing Apartment → Room → SleepingPlace → Assignment tree.
2. **Date Semantics & Turnover**: `[start_date, end_date)` interval math accurately handles multi-night stays and same-day turnover without false conflicts.
3. **Overlap Alerting**: Overlapping assignments generate `ACCOMMODATION_OVERLAP` warnings without silently mutating data.
4. **Composite FK Isolation**: Cross-event room/bed/assignment linkage is strictly blocked by composite foreign keys.
5. **CAS & Concurrency**: Stale version edits fail with SQLSTATE `40001`.
6. **Server Audit**: Create/update/delete/restore operations generate transactional audit logs.
7. **Verification**: `flutter analyze --no-pub`, `flutter test --no-pub`, and `node tools/db-test/verify.mjs` pass cleanly.

---

## 9. Unresolved Decisions & Implementation Proposals

- **UPD-004 (Relationship between `is_locked` and `ACCOMMODATION_OVERLAP` alerts)**: Spec v2.6 specifies `is_locked` for capacity override with notes, and specifies `ACCOMMODATION_OVERLAP` alert generation for overlapping assignments. Whether `is_locked` suppresses `ACCOMMODATION_OVERLAP` alerts or if the alert persists until dates are adjusted is unresolved in Spec v2.6. Proposed: surface the alert while displaying the manager's `is_locked` override note.
- **Proposed DB Structure**: Proposed exact migration SQL, RPC function names, and composite FK constraints are implementation proposals to be validated by the implementation agent during migration creation.
