# UMAN EVENT MANAGER — TASK BRIEF

**Task ID:** TASK-ACC-01  
**Owner:** Unassigned (PLANNED)  
**Status:** PLANNED  
**Branch / Worktree:** TBD (`codex/accommodation-slice`)  

---

## Objective

Implement the **Accommodation Foundation** vertical slice in Flutter and Supabase, establishing housing logistics across the four-level hierarchy (**Apartment → Room → SleepingPlace → AccommodationAssignment**). This slice enforces `[start_date, end_date)` civil date semantics, same-day turnover validation, interval overlap detection, manager capacity overrides, strict same-event composite FK integrity, CAS optimistic concurrency control, transactional server audit logging, soft-delete/restore capabilities, and realtime propagation.

---

## Scope

- **Database (`supabase/migrations/`)**:
  - Versioned Supabase migration adding `apartments`, `rooms`, `sleeping_places`, and `accommodation_assignments` tables.
  - Unique composite constraints `(event_id, id)` on all four tables.
  - Composite same-event foreign key constraints:
    - `rooms(event_id, apartment_id)` → `apartments(event_id, id)`
    - `sleeping_places(event_id, room_id)` → `rooms(event_id, id)`
    - `accommodation_assignments(event_id, sleeping_place_id)` → `sleeping_places(event_id, id)`
    - `accommodation_assignments(event_id, person_id)` → `people(event_id, id)`
  - Row Level Security (RLS) policies enforcing `is_event_admin(event_id)` authorization.
  - Transactional `SECURITY DEFINER` RPCs (`save_apartment`, `list_apartments`, `delete_apartment`, `restore_apartment`, `save_room`, `list_rooms`, `delete_room`, `restore_room`, `save_sleeping_place`, `list_sleeping_places`, `delete_sleeping_place`, `restore_sleeping_place`, `save_accommodation_assignment`, `list_accommodation_assignments`, `delete_accommodation_assignment`, `restore_accommodation_assignment`).
  - Server audit triggers inserting records into `public.audit_entries`.
- **Domain (`lib/domain/entities/`, `lib/domain/repositories/`)**:
  - Pure Dart entities: `Apartment`, `Room`, `SleepingPlace`, `AccommodationAssignment`, `ApartmentStatus` (`ACTIVE`, `UNAVAILABLE`, `CLOSED`), `SleepingPlaceType` (`REGULAR_BED`, `BUNK_BED`, `SOFA_BED`, `MATTRESS`, `CUSTOM`), `AssignmentStatus` (`ACTIVE`, `TEMPORARY`, `CANCELLED`).
  - Value objects: `CivilDate`.
  - Input objects: `ApartmentInput`, `RoomInput`, `SleepingPlaceInput`, `AccommodationAssignmentInput`.
  - Repository contract: `AccommodationRepository`.
- **Infrastructure (`lib/infrastructure/cloud/`)**:
  - `SupabaseAccommodationRepository` implementing `AccommodationRepository`.
  - Codecs: `apartment_codec.dart`, `room_codec.dart`, `sleeping_place_codec.dart`, `accommodation_assignment_codec.dart`.
- **Application (`lib/application/`)**:
  - `AccommodationController` managing hierarchy state, date range interval math (`[start_date, end_date)`), same-day turnover validation, overlap detection alerts (`ACCOMMODATION_OVERLAP`), unassigned person detection (`PERSON_WITHOUT_SLEEPING_PLACE`), optimistic CAS updates, realtime channel subscriptions, bounded periodic background reconciliation (30s), error classification, and proper subscription disposal.
- **Presentation (`lib/presentation/accommodation/`)**:
  - `ApartmentsPage` (list of apartments with occupancy summaries, room/bed counts, status, and cost).
  - `ApartmentDetailsPage` (hierarchical tree view: Apartment → Rooms → Sleeping Places → Active/Scheduled Assignments).
  - `ApartmentEditorPage`, `RoomEditorPage`, `SleepingPlaceEditorPage`.
  - `AccommodationAssignmentEditor` (date range selector with inclusive start / exclusive end visualization, person selector, overlap warning banner, temporary assignment toggle, manager override notes).
  - `EventShell` drawer/navigation integration under Accommodation module.
  - BiDi text isolation (`BidiTextFormatter.isolate`).
  - Visual Design System compliance (`Theme.of(context).colorScheme`).
- **Testing & Verification**:
  - Domain unit tests for date math, interval overlaps, and turnover (`test/domain/accommodation_test.dart`).
  - Controller tests (`test/accommodation_controller_test.dart`).
  - Presentation widget tests (`test/accommodation_widget_test.dart`).
  - WASM DB checks in `tools/db-test/accommodation-checks.mjs` integrated into `verify.mjs`.

---

## Out of Scope

- Automated hotel PMS or channel manager API integrations.
- Automated allocation of unassigned people to beds (Manager Sovereignty Principle).
- Financial expense/payment allocations across room occupants (deferred under OPD-002/003).

---

## Relevant Specifications

- `UMAN_EVENT_MANAGER_SPEC_v2.6.md` (Section 14: Accommodation & Sleeping Logistics)
- `UMAN_EVENT_MANAGER_TECH_SPEC_v1.2.md` (Domain migration review, composite FKs, CAS, Audit, Realtime)
- `ADR-001-CLOUD-FIRST-REALTIME-MULTIUSER.md`
- `UMAN_EVENT_MANAGER_VISUAL_DESIGN_SYSTEM.md`

---

## Dependencies / Shared Resources

1. **`TASK-PEOPLE-01` People Slice**:
   - `people` table must exist with unique `(event_id, id)` constraint for `AccommodationAssignment.person_id` foreign key.
2. **Event Scoping Foundation**:
   - `events` table and RLS authorization helpers (`is_event_admin`).
3. **Supabase Migration**:
   - Requires new versioned SQL migration for `apartments`, `rooms`, `sleeping_places`, and `accommodation_assignments`.

---

## Domain Hierarchy & Schema Specification

### 1. Apartment Entity
* **`id`**: UUIDv4 (Primary key)
* **`event_id`**: UUIDv4 (FK to `events(id)`)
* **`name`**: String (Non-empty, max 200 chars)
* **`address`**: String (Non-empty, max 500 chars)
* **`hebrew_address`**: String? (Nullable, max 500 chars)
* **`floor`**: String? (Nullable, max 50 chars)
* **`entry_code`**: String? (Nullable, max 100 chars)
* **`landlord_name`**: String? (Nullable, max 200 chars)
* **`landlord_phone`**: String? (Nullable, max 50 chars)
* **`notes`**: String? (Nullable, max 10,000 chars)
* **`status`**: Enum (`ACTIVE`, `UNAVAILABLE`, `CLOSED`)
* **`total_cost`**: Decimal? (Nullable numeric)
* **`cost_currency`**: String? (ISO 4217, e.g. `USD`, `EUR`, `ILS`)
* **`cost_notes`**: String? (Nullable, max 2,000 chars)
* **`created_at_utc`**, **`updated_at_utc`**: Timestamptz
* **`is_deleted`**: bool (Soft-delete flag)
* **`version`**: bigint (CAS version)

### 2. Room Entity
* **`id`**: UUIDv4 (Primary key)
* **`event_id`**: UUIDv4 (FK to `events(id)`)
* **`apartment_id`**: UUIDv4 (Composite FK `(event_id, apartment_id)` → `apartments(event_id, id)`)
* **`name_or_number`**: String (Non-empty, max 100 chars)
* **`floor`**: String? (Nullable, max 50 chars)
* **`description`**: String? (Nullable, max 1,000 chars)
* **`notes`**: String? (Nullable, max 5,000 chars)
* **`created_at_utc`**, **`updated_at_utc`**: Timestamptz
* **`is_deleted`**: bool
* **`version`**: bigint

### 3. SleepingPlace Entity
* **`id`**: UUIDv4 (Primary key)
* **`event_id`**: UUIDv4 (FK to `events(id)`)
* **`room_id`**: UUIDv4 (Composite FK `(event_id, room_id)` → `rooms(event_id, id)`)
* **`label`**: String (Non-empty, max 100 chars)
* **`type`**: Enum (`REGULAR_BED`, `BUNK_BED`, `SOFA_BED`, `MATTRESS`, `CUSTOM`)
* **`custom_type_name`**: String? (Required if `type` == `CUSTOM`)
* **`position_notes`**: String? (Nullable, max 1,000 chars)
* **`is_active`**: bool (Default true)
* **`created_at_utc`**, **`updated_at_utc`**: Timestamptz
* **`is_deleted`**: bool
* **`version`**: bigint

### 4. AccommodationAssignment Entity
* **`id`**: UUIDv4 (Primary key)
* **`event_id`**: UUIDv4 (FK to `events(id)`)
* **`sleeping_place_id`**: UUIDv4 (Composite FK `(event_id, sleeping_place_id)` → `sleeping_places(event_id, id)`)
* **`person_id`**: UUIDv4 (Composite FK `(event_id, person_id)` → `people(event_id, id)`)
* **`start_date`**: CivilDate (Inclusive check-in date)
* **`end_date`**: CivilDate (Exclusive checkout date)
* **`status`**: Enum (`ACTIVE`, `TEMPORARY`, `CANCELLED`)
* **`notes`**: String? (Nullable, max 5,000 chars)
* **`is_locked`**: bool (Default false; indicates manager capacity/over-booking override)
* **`created_at_utc`**, **`updated_at_utc`**: Timestamptz
* **`is_deleted`**: bool
* **`version`**: bigint

---

## Technical Semantics & Business Rules

### 1. Date Semantics (`[start_date, end_date)`)
- `start_date` is **inclusive** (represents the first night the person sleeps in the bed).
- `end_date` is **exclusive** (represents the checkout date; the person does NOT sleep there on this night).
- *Example*: `start_date = 2025-10-01`, `end_date = 2025-10-05` covers nights of Oct 1, 2, 3, 4 with checkout on Oct 5.

### 2. Same-Day Turnover Validation
- A checkout and check-in occurring on the same date on the same bed do **NOT** conflict.
- *Example*: Assignment A with `end_date = 2025-10-03` and Assignment B with `start_date = 2025-10-03` on SleepingPlace X do NOT overlap.

### 3. Overlap Detection & Warning Generation
- Two active assignments (`status != CANCELLED` and `is_deleted = false`) on the same `sleeping_place_id` overlap if and only if:
  $$\max(start_A, start_B) < \min(end_A, end_B)$$
- When an overlap is detected, the system generates an `ACCOMMODATION_OVERLAP` advisory alert in the Control Center / Unresolved Items.
- The system MUST NOT hard-block an explicit manager write; Manager Sovereignty allows intentional temporary double-booking with `is_locked = true` and explanatory `notes`.
- System MUST NEVER silently reassign or mutate existing assignments to resolve conflicts.

### 4. Same-Event Composite Foreign Keys
- All accommodation tables must enforce same-event composite foreign keys to guarantee event isolation:
```sql
alter table public.apartments add unique (event_id, id);
alter table public.rooms add unique (event_id, id);
alter table public.sleeping_places add unique (event_id, id);

alter table public.rooms
    add constraint rooms_apartment_event_fkey
        foreign key (event_id, apartment_id) references public.apartments(event_id, id) on delete restrict;

alter table public.sleeping_places
    add constraint sleeping_places_room_event_fkey
        foreign key (event_id, room_id) references public.rooms(event_id, id) on delete restrict;

alter table public.accommodation_assignments
    add constraint assignments_sleeping_place_event_fkey
        foreign key (event_id, sleeping_place_id) references public.sleeping_places(event_id, id) on delete restrict,
    add constraint assignments_person_event_fkey
        foreign key (event_id, person_id) references public.people(event_id, id) on delete restrict;
```

### 5. CAS & Concurrency Control
- All mutation RPCs require `p_expected_version bigint`. Mismatched version writes throw SQLSTATE `40001` (`Record changed`).
- Controllers display stale update warnings and refresh canonical state while preserving uncommitted user draft inputs.

### 6. Server Audit Requirements
- All mutations across apartments, rooms, sleeping places, and assignments MUST generate transactional entries in `public.audit_entries` inside the same database transaction.

### 7. Soft-Delete & Restore
- All entities support soft deletion (`is_deleted = true`, `deleted_at_utc = now()`).
- Transactional RPCs (`restore_apartment`, `restore_room`, `restore_sleeping_place`, `restore_accommodation_assignment`) restore soft-deleted records, increment `version`, and record audit entries.

### 8. Realtime Propagation
- `SupabaseAccommodationRepository` subscribes to Supabase realtime events for accommodation tables.
- Realtime changes invalidate local state and trigger re-fetching of canonical data.
- Bounded periodic background polling (30 seconds) ensures state convergence.

---

## Acceptance Criteria

1. **Hierarchical Navigation & Management**: UI supports browsing and managing Apartment → Room → SleepingPlace → Assignment tree.
2. **Date Semantics & Turnover**: `[start_date, end_date)` interval math accurately handles multi-night stays and same-day turnover without false conflicts.
3. **Overlap Alerting**: Overlapping assignments generate `ACCOMMODATION_OVERLAP` warnings without silently mutating data.
4. **Composite FK Isolation**: Cross-event room/bed/assignment linkage is strictly blocked by composite foreign keys.
5. **CAS & Concurrency**: Stale version edits fail with SQLSTATE `40001`.
6. **Server Audit**: All create/update/delete/restore operations generate transactional audit logs.
7. **Soft-Delete & Restore**: Soft-deleted entities can be restored via RPC without data loss.
8. **Clean Code & Verification**: `flutter analyze --no-pub` returns 0 issues; all tests and WASM DB checks pass.

---

## Verification Required

- `flutter analyze --no-pub`
- `flutter test --no-pub` (Unit tests in `test/domain/accommodation_test.dart`, `test/accommodation_controller_test.dart`, widget tests in `test/accommodation_widget_test.dart`)
- `node tools/db-test/verify.mjs` (WASM DB checks in `tools/db-test/accommodation-checks.mjs`)

---

## External Gates

1. **`TASK-PEOPLE-01` Verification Gate**: People table must be verified on main.
2. **Two-Account Independent Session Gate**: Multi-user realtime sync verified on Supabase staging.
3. **Android / iOS Delivery Gate**: Android APK build and iOS static review clean.
