# UMAN EVENT MANAGER — Master Product & System Specification v2.6
> Architecture migration 2026-09-17: ADR-001 and Technical v1.2 supersede previous persistence assumptions. Phase 1 is Authenticated Cloud Persistence & Realtime Foundation (Event slice). Broader MVP business requirements below remain required in subsequent phases, not claims of implemented features. The referenced Breslov design markdown is absent; preserve available reference assets and obtain it before visual sign-off.

## SECTION 1: Document Header & Status Matrix

- **Document Title:** UMAN EVENT MANAGER — Master Product & System Specification v2.6
- **Version:** 2.6
- **Status:** IMPLEMENTATION BASELINE — OPEN PRODUCT DECISIONS EXPLICITLY DEFERRED
- **Classification:** Internal — Authoritative Product Specification
- **Audience:** AI Development Agents, Product Owner, Technical Leads

### Status Matrix

| Area | Status | Notes |
| :--- | :--- | :--- |
| Event Model | MVP — Defined | Core event scoping and isolation |
| People | MVP — Defined | Profiles, groups, relationships |
| Flights | MVP — Defined | Inbound/Outbound, assignments |
| Transport | MVP — Defined | Ground transit, routes, passengers |
| Accommodation | MVP — Defined | Buildings, rooms, beds, assignments |
| Tasks | MVP — Defined | Actionable items, assignments |
| Finance | MVP — Defined | Incomes, expenses, balances |
| Control Center | MVP — Defined | Real-time operational dashboard |
| Rules Engine | MVP — Defined | Validation, warnings, derivations |
| Unresolved State | MVP — Defined | Global issue tracking and resolution |
| Today View | MVP — Defined | Time-sensitive context |
| Search | MVP — Defined | Global and contextual search |
| Bilingual UX | MVP — Defined | EN/HE UI and data support |
| Sharing Snapshot | MVP — Defined | Plain-text static snapshot for copy/share/WhatsApp |
| Structured Data Export | MVP — Defined | Event-scoped CSV and JSON export |
| Formatted Reports | Phase 2 — Deferred | PDF/HTML reports are not MVP sharing |
| Data Integrity | MVP — Defined | Validation, conflict prevention |
| Backup/Restore | MVP — Defined | Operator-managed server backup/recovery |
| Security | MVP — Defined | Auth, RLS, TLS and secure local storage |
| Cloud-First | MVP — Defined | Server writes; offline cached reads |
| Realtime Sync | Mandatory | Automatic propagation and reconciliation |
| Event authorization | Mandatory | Membership RLS and administrator RPCs |
| Audit | MVP — Defined | Mandatory server-generated attributed audit |
| Import/Export | MVP — Defined | CSV data loading/extraction |
| Migration | MVP — Defined | DB schema versioning |
| Performance | MVP — Defined | Responsive on both administrator devices |
| Data Model | MVP — Defined | Core entities and relationships |
| Edge Cases | MVP — Defined | Handling unusual scenarios |
| Acceptance Criteria | MVP — Defined | Success metrics for MVP |
| Traceability | MVP — Defined | Tracking actions to issues |

*(Note: The matrix covers representative areas from the full list of 40 requested, categorized per instructions.)*

### Platform Delivery Baseline

Android is the primary Windows development and daily-testing platform; Android and iOS are mandatory production targets. Final user acceptance is on a real iPhone. The binding delivery policy, iOS Compatibility Gate, and TestFlight release path are defined in `CROSS_PLATFORM_DELIVERY.md` v1.0.

## SECTION 2: Executive Summary

UMAN EVENT MANAGER is an cloud-first operational command center for temporary, high-stress group logistics. Primary use case: managing large delegations (50-500+ people) traveling to Uman, Ukraine for Rosh Hashanah. 

The system answers three questions: 
1. What is happening? 
2. What is missing or wrong? 
3. What do I need to do next? 

Manager sovereignty is absolute. Yonatan and Yosef use separate authenticated administrator accounts with event membership. Supabase PostgreSQL is canonical; committed changes propagate automatically through realtime. Local data is a non-authoritative read cache.

## SECTION 3: Product Definition & Core Promises

### What UMAN EVENT MANAGER Is
An cloud-first operational command center for temporary high-stress group logistics.

### What It Is NOT
It is NOT a spreadsheet, CRM, accounting platform, flight tracker, general-purpose cloud platform, social network, ERP, autonomous manager, generic DB builder, or generic PM tool.

### Core Promises
- **Manager Sovereignty:** System may calculate, validate, detect, warn, highlight, suggest, derive, request confirmation, and auto-resolve only a derived unresolved item whose triggering condition disappeared. System must NEVER silently reassign, change, modify, overwrite, alter, or delete manager-entered source data, or treat a derived resolution as a source-data change.
- **No Silent Data Loss:** No operation may silently destroy, overwrite, or discard meaningful information. Destructive actions must be explicit.
- **Source vs Derived Data Separation:** Strict boundary between user-entered source data and system-calculated derivations.
- **Manager Overrides:** Any automated derivation or rule can be overridden manually.
- **Missing Info ≠ Negative Fact:** Empty fields imply absence of knowledge, not negation.

### Target User
Two authenticated operations administrators coordinating a large delegation under time pressure with unreliable connectivity.

### Operational Context
Uman Rosh Hashanah delegation — flights, ground transport, accommodation, tasks, finances, issues, all managed under extreme time pressure.

## SECTION 4: The Three Questions

### 1. WHAT IS HAPPENING?
**Current operational picture across all domains.**
- *Example (Flights):* Viewing all inbound flights arriving today and their current statuses.
- *Example (Accommodation):* Seeing which rooms are fully booked vs. available.

### 2. WHAT IS MISSING OR WRONG?
**Every detectable gap, conflict, inconsistency.**
- *Example (People):* John Doe arrives in 4 hours but has no assigned bed or ground transport.
- *Example (Transport):* Bus 3 is scheduled to depart in 10 minutes, but 5 assigned passengers have not checked in.
- *Example (Accommodation):* Bed A in Room 101 is assigned to two different people for the same dates.

### 3. WHAT DO I NEED TO DO NEXT?
**Actionable items with direct resolution paths.**
- *Example:* "Assign transport to 12 unassigned passengers landing at KBP on LY202."
- *Example:* "Resolve double-booking in Building A, Room 302."
- *Example:* "Collect remaining balance of $400 from Group Y before check-in."

## SECTION 5: Non-Negotiable Product Principles

### 1. Manager Sovereignty
The system may calculate, validate, detect, warn, highlight, suggest, derive, request confirmation, and auto-resolve only a derived unresolved item whose triggering condition disappeared. It must NEVER silently reassign, change, modify, overwrite, alter, or delete manager-entered source data. The manager's explicit command is always the final authority over source data and explicit resolutions.

### 2. No Silent Data Loss
No operation may silently destroy, overwrite, or discard meaningful information. Any destructive action must be explicit and intentional.

### 3. Source Data vs Derived Data vs Operational State
- **Source Data:** The raw facts entered by the manager or imported (e.g., flight lands at 14:00).
- **Derived Data:** Computations based on source (e.g., flight landing at 14:00 means bus departs at 15:30).
- **Operational State:** Current real-world standing (e.g., "Bus Delayed"). 
Source data is sacred; derived data is recalculated; operational state informs actions.

### 4. Manager Overrides
`is_locked=TRUE` means "do not automatically replace/recalculate." A manager can explicitly lock a derived field to a manual value. The manager can explicitly change or remove the override later. It is not permanently immutable.

### 5. Missing Information Is Not a Negative Fact
Distinguish between Unknown, Not Entered, Not Applicable, and Confirmed (e.g., Zero).
- *Example:* A missing age for a participant means the age is unknown, not that the participant is 0 years old. 

### 6. Event Isolation
Every query, calculation, search, and rule is scoped to exactly one event. There is zero bleed-over of data or state between Event A and Event B.

### 7. Deterministic Derived State
Same source data + same rules = same derived state, always. There is no randomness or "AI guessing" in core business logic.

---

## SECTION 6: MVP Scope vs. Phase 2 Boundary

The MVP is cloud-first and multi-user. Phase 1 verifies an authenticated Event vertical slice before broader business features.

### Feature Classification

| Feature Area | Included in MVP (Build Now) | Strictly Deferred (Phase 2+) |
| :--- | :--- | :--- |
| **Core Architecture** | Cloud-first server persistence, Auth, RLS, realtime, audit and read cache | CRDT, Event Sourcing, peer-to-peer state |
| **Event & Lifecycle** | Event management, lifecycle stages, multi-event isolation | Character-level coediting and presence |
| **Identity & Access** | Separate administrator accounts and event membership | Advanced role editor, field-level permissions UI, self-service invitations |
| **People & Logistics**| People management, Flight management & manifests, Driver & Vehicle management, Multi-passenger transport | Global person identity across events |
| **Accommodation** | Apartment → Room → SleepingPlace → Assignment, Date-aware sleeping assignments | Automated hotel PMS integrations |
| **Operations** | Tasks & Apartment Issues, Reactive domain rules, Control Center, Today view, Unresolved items, Universal search | Meals, Menus, Recipes, Cook calculations, Food inventory, automated purchasing |
| **Financials** | Expenses, Participant Payments, Multi-currency calculations | Banking integrations, automated currency rate sync |
| **Localization** | Hebrew/English bilingual UX with RTL/LTR | Additional languages beyond HE/EN |
| **Customization** | Manager customization, event-scoped settings, local data import/export | Global organization-level templates |

### Shared/Read-Only Output (MVP)

Data sharing in the MVP is entirely one-way and read-only. External snapshots do not grant editable access. Administrators share authenticated server state; participant/staff accounts are out of scope.

*   **Snapshots:** Generation of read-only snapshots tailored for WhatsApp sharing.
*   **Supported Snapshot Types:** Transport lists, accommodation lists, arrival/departure manifests, task lists, and operational summaries.
*   **Presentation:** Snapshots must be clearly identifiable as static point-in-time documents, distinct from live operational state.

---

## SECTION 7: Event Model & Lifecycle

The **Event** is the root operational container. Every data record in the system belongs to exactly one event. There is strict cross-event isolation; data does not leak between events.

**Data Model: Event**
*   `id` (UUIDv4)
*   `name` (String)
*   `hebrew_name` (String, nullable)
*   `description` (Text, nullable)
*   `year` (Integer)
*   `start_date` (Date)
*   `end_date` (Date)
*   `base_currency` (String, ISO 4217)
*   `lifecycle_stage` (Enum: PLANNING, READY, TRAVEL, IN_UMAN, DEPARTURE, CLOSEOUT, ARCHIVED)
*   `manager_notes` (Text, nullable)
*   `settings` (JSON)
*   `created_at_utc` (Timestamp)
*   `updated_at_utc` (Timestamp)
*   `is_deleted` (Boolean)

### Lifecycle Stages & Definitions

1.  **PLANNING:** Initial setup. All data entry permitted. No operational restrictions or active alerts triggered by timeline proximity.
2.  **READY:** Pre-travel preparation is complete. The manager confirms readiness. All structural data (apartments, vehicles) should be finalized and reviewed.
3.  **TRAVEL:** Active travel period. Inbound flights and transport are active. Operational alerts (e.g., flight delays, missing pickups) are critical.
4.  **IN_UMAN:** On-site operations phase. Accommodation assignments are active. Tasks and apartment issues take operational priority.
5.  **DEPARTURE:** Return travel period. Outbound flights and return transport are active.
6.  **CLOSEOUT:** Financial and operational reconciliation. No new operational assignments can be created. Manager reviews and finalizes all records.
7.  **ARCHIVED:** Read-only historical record. No editing permitted except authorized corrections by the manager.

### Lifecycle Transitions

| From | To | Valid | Requires Manager Authorization | Notes / Behavior |
| :--- | :--- | :--- | :--- | :--- |
| PLANNING | READY | Yes | Yes | Validates that minimum setup requirements are met. |
| READY | PLANNING | Yes | Yes | Reversible if more core planning is required. |
| READY | TRAVEL | Yes | Yes | Explicit manager action; automatic timeline thresholds remain undefined. |
| TRAVEL | IN_UMAN | Yes | Yes | Explicit manager action; no inferred majority-arrived transition. |
| IN_UMAN | DEPARTURE | Yes | Yes | Explicit manager action; departures do not change the stage automatically. |
| DEPARTURE | CLOSEOUT | Yes | Yes | Stops all active operational monitoring. |
| CLOSEOUT | ARCHIVED | Yes | Yes | Locks event. Read-only enforced by server mutation policy. |
| ANY | ARCHIVED | Yes | Yes | Force archive (e.g., event cancelled). |
| ARCHIVED | CLOSEOUT | No | N/A | Archiving is a final state for operational purposes. |

*   **Historical Visibility:** Archived events are visible in search and reference lists but exclude active operational widgets (Today View, Unresolved Items).
*   **Event Isolation Rules:** A Person, Trip, or Flight created in Event A cannot be referenced or linked to from Event B.

---

## SECTION 8: Manager Control & Customization

The system provides targeted, event-scoped customization capabilities to adapt to specific group needs.

**Supported Customizations:**
*   Custom categories for expenses
*   Custom sleeping place types beyond built-in defaults
*   Custom payment methods
*   Custom task priorities and labels
*   Custom status labels where appropriate
*   Event-level settings (base currency, default airport, timezone preferences)
*   Display preferences (RTL/LTR overrides, default views)

**Constraints:**
All customization is strictly event-scoped. Changes apply only to the current Event. Customizations cannot alter core domain rules, lifecycle transitions, or required entity fields.

---

## SECTION 9: People Management

**MVP Model:** The `Person` entity is event-scoped. Each event maintains its own isolated person records. Cross-event person reuse is deferred to a future capability.
*Justification:* Event-scoped persons drastically simplify data structure, eliminate cross-event data leakage risks, and negate the need for a global identity management system for event-scoped operations.

**Data Model: Person**
*   `id` (UUIDv4)
*   `event_id` (UUID, FK)
*   `first_name` (String)
*   `last_name` (String)
*   `hebrew_first_name` (String, nullable)
*   `hebrew_last_name` (String, nullable)
*   `phone` (String)
*   `whatsapp_phone` (String, nullable)
*   `email` (String, nullable)
*   `passport_name` (String, nullable)
*   `passport_number` (String, nullable)
*   `passport_expiration_date` (Date, nullable)
*   `date_of_birth` (Date, nullable)
*   `nationality` (String, nullable)
*   `emergency_contact_name` (String, nullable)
*   `emergency_contact_phone` (String, nullable)
*   `notes` (Text, nullable)
*   `custom_fields` (JSON)
*   `status` (Enum: ACTIVE, INACTIVE)
*   `created_at_utc` (Timestamp)
*   `updated_at_utc` (Timestamp)
*   `is_deleted` (Boolean)

**Relationships:**
*   → `FlightPassenger` (1:N)
*   → `TripPassenger` (1:N)
*   → `AccommodationAssignment` (1:N)
*   → `Task` (Assignee) (1:N)
*   → `ApartmentIssue` (Reporter) (1:N)
*   → `Expense` (Payer) (1:N)
*   → `Payment` (1:N)

**Behaviors:**
*   **Search:** Supports Hebrew, English, and mixed-language querying.
*   **Deletion:** Soft delete only. Preserves relationships for historical accuracy, marks record as `is_deleted = true`. Supports restore.
*   **WhatsApp Integration:** Read-only snapshot sharing directly to WhatsApp via intent/URL schema.
*   **Duplicate Detection:** System evaluates name similarity and phone number matches during creation/import. If a potential duplicate is detected, the system issues a warning. The manager makes the final decision. The system **never** auto-merges person records.

---

## SECTION 10: Flight Management

The system treats Flight information as source data input by the manager. The system is NOT an authoritative flight tracker; it strictly tracks the manager's known state of operations.

**Data Model: Flight**
*   `id` (UUIDv4)
*   `event_id` (UUID, FK)
*   `direction` (Enum: INBOUND, OUTBOUND)
*   `airline` (String)
*   `flight_number` (String)
*   `departure_airport` (String)
*   `arrival_airport` (String)
*   `scheduled_departure_utc` (Timestamp)
*   `scheduled_arrival_utc` (Timestamp)
*   `actual_departure_utc` (Timestamp, nullable)
*   `actual_arrival_utc` (Timestamp, nullable)
*   `status` (Enum: SCHEDULED, DELAYED, CANCELLED, DIVERTED, LANDED, UNKNOWN)
*   `delay_minutes` (Integer, nullable)
*   `terminal` (String, nullable)
*   `gate` (String, nullable)
*   `notes` (Text, nullable)
*   `is_locked` (Boolean)
*   `created_at_utc` (Timestamp)
*   `updated_at_utc` (Timestamp)
*   `is_deleted` (Boolean)

**Data Model: FlightPassenger**
*   `id` (UUIDv4)
*   `flight_id` (UUID, FK)
*   `person_id` (UUID, FK)
*   `seat_number` (String, nullable)
*   `booking_reference` (String, nullable)
*   `notes` (Text, nullable)
*   `status` (Enum: CONFIRMED, TENTATIVE, CANCELLED)
*   `created_at_utc` (Timestamp)
*   `updated_at_utc` (Timestamp)
*   `is_deleted` (Boolean)

**Flight Status Change Behaviors:**
*   **DELAYED:** Generates an advisory for the Control Center. Does **NOT** automatically change associated transport schedules.
*   **CANCELLED:** Generates a critical alert. Transport and accommodation are flagged as potentially affected. The manager must manually review and reallocate.
*   **Schedule Change:** Generates an alert. Original schedule data is preserved for comparison, and the new schedule is recorded. The manager reviews transport impact.

---

## SECTION 11: Driver Management

A `Driver` is treated as a separate, distinct domain entity and is **NOT** embedded within a Vehicle record.

**Data Model: Driver**
*   `id` (UUIDv4)
*   `event_id` (UUID, FK)
*   `name` (String)
*   `phone` (String)
*   `whatsapp_phone` (String, nullable)
*   `license_info` (String, nullable)
*   `notes` (Text, nullable)
*   `status` (Enum: AVAILABLE, BUSY, UNAVAILABLE, OFF_DUTY)
*   `created_at_utc` (Timestamp)
*   `updated_at_utc` (Timestamp)
*   `is_deleted` (Boolean)

**Relationships & Behaviors:**
*   → `Trip` (driver for trip) (1:N over time)
*   A Driver is NOT permanently bound to a Vehicle. A driver may operate different vehicles at different times, and may be assigned to different trips flexibly.

---

## SECTION 12: Vehicle Management

**Data Model: Vehicle**
*   `id` (UUIDv4)
*   `event_id` (UUID, FK)
*   `name_or_identifier` (String)
*   `vehicle_type` (Enum: CAR, VAN, MINIBUS, BUS, CUSTOM)
*   `capacity` (Integer - maximum passengers)
*   `license_plate` (String, nullable)
*   `color` (String, nullable)
*   `notes` (Text, nullable)
*   `status` (Enum: AVAILABLE, IN_USE, MAINTENANCE, UNAVAILABLE)
*   `created_at_utc` (Timestamp)
*   `updated_at_utc` (Timestamp)
*   `is_deleted` (Boolean)

**Relationships & Behaviors:**
*   → `Trip` (vehicle for trip) (1:N over time)
*   A Vehicle is NOT permanently bound to a Driver.
*   `capacity` is strictly used by the Domain Rules engine to validate against active trip passenger assignments.

---

## SECTION 13: Transport Management

Transport Management centers around the `Trip`, coordinating people, drivers, and vehicles.

**Data Model: Trip**
*   `id` (UUIDv4)
*   `event_id` (UUID, FK)
*   `direction` (Enum: INBOUND, OUTBOUND, LOCAL)
*   `origin` (String)
*   `destination` (String)
*   `scheduled_departure_utc` (Timestamp)
*   `scheduled_arrival_utc` (Timestamp)
*   `actual_departure_utc` (Timestamp, nullable)
*   `actual_arrival_utc` (Timestamp, nullable)
*   `driver_id` (UUID, FK, nullable)
*   `vehicle_id` (UUID, FK, nullable)
*   `related_flight_id` (UUID, FK, nullable)
*   `status` (Enum: PLANNED, CONFIRMED, IN_PROGRESS, COMPLETED, CANCELLED)
*   `notes` (Text, nullable)
*   `is_locked` (Boolean)
*   `created_at_utc` (Timestamp)
*   `updated_at_utc` (Timestamp)
*   `is_deleted` (Boolean)

**Data Model: TripPassenger**
*   `id` (UUIDv4)
*   `trip_id` (UUID, FK)
*   `person_id` (UUID, FK)
*   `pickup_location` (String, nullable)
*   `pickup_notes` (Text, nullable)
*   `passenger_status` (Enum: ASSIGNED, CONFIRMED, PICKED_UP, DROPPED_OFF, NO_SHOW, CANCELLED)
*   `notes` (Text, nullable)
*   `created_at_utc` (Timestamp)
*   `updated_at_utc` (Timestamp)
*   `is_deleted` (Boolean)

**Domain Rules & Behaviors:**
*   **Capacity Validation:** A trip is over capacity only when its count of active passengers is strictly greater than the related vehicle's capacity (`passenger_count > capacity`). Exactly at capacity is valid. The system will **never** silently remove passengers to resolve an overallocation; the manager must resolve it.
*   **Driver/Vehicle Replacement:** Reassigning a driver or vehicle preserves historical context. The previous assignment is recorded in the server-generated audit log. The new assignment becomes the live source data.
*   **Flight-Transport Linkage:** A trip MAY reference a related flight (e.g., Airport Transfer). If the related flight changes (e.g., delayed or cancelled), the system generates advisories but **NEVER** automatically modifies the trip schedule or assignments. The manager must review the alert and confirm operational changes manually.

---

## SECTION 14: Accommodation & Sleeping Logistics

### 14.1 Hierarchy and Data Models
The accommodation model is strictly hierarchical: **Apartment → Room → SleepingPlace → AccommodationAssignment**.

#### Apartment
* **id**: UUIDv4
* **event_id**: Foreign Key
* **name**: String
* **address**: String
* **hebrew_address**: String
* **floor**: String/Integer
* **entry_code**: String
* **landlord_name**: String
* **landlord_phone**: String
* **notes**: Text
* **status**: Enum (`ACTIVE`, `UNAVAILABLE`, `CLOSED`)
* **total_cost**: Decimal
* **cost_currency**: ISO 4217
* **cost_notes**: Text
* **created_at_utc**, **updated_at_utc**: Timestamp
* **is_deleted**: Boolean

#### Room
* **id**: UUIDv4
* **apartment_id**: Foreign Key
* **name/number**: String
* **floor**: String/Integer
* **description**: Text
* **notes**: Text
* **created_at_utc**, **updated_at_utc**: Timestamp
* **is_deleted**: Boolean

#### SleepingPlace
* **id**: UUIDv4
* **room_id**: Foreign Key
* **label**: String
* **type**: Enum (`REGULAR_BED`, `BUNK_BED`, `SOFA_BED`, `MATTRESS`, `CUSTOM`)
* **custom_type_name**: String (Nullable, required if type is `CUSTOM`)
* **position_notes**: Text
* **is_active**: Boolean
* **created_at_utc**, **updated_at_utc**: Timestamp
* **is_deleted**: Boolean

#### AccommodationAssignment
The system explicitly avoids a simple "Occupant" field on the sleeping place. Instead, it utilizes an event-scoped assignment model to track historical and future occupancy securely.

* **id**: UUIDv4
* **sleeping_place_id**: Foreign Key
* **person_id**: Foreign Key
* **start_date**: Date (Inclusive)
* **end_date**: Date (Exclusive)
* **status**: Enum (`ACTIVE`, `TEMPORARY`, `CANCELLED`)
* **notes**: Text
* **is_locked**: Boolean
* **created_at_utc**, **updated_at_utc**: Timestamp
* **is_deleted**: Boolean

### 14.2 Business Rules and Logic

#### Date Semantics
* `start_date` is **inclusive** (representing the first night the person is sleeping in the place).
* `end_date` is **exclusive** (representing the checkout day; the person does not sleep there on this night).
* *Example*: A person assigned from `2025-10-01` to `2025-10-05` sleeps there on the nights of Oct 1, 2, 3, and 4, checking out on Oct 5.

#### Same-Day Turnover
* A person checking out and another checking in on the same day do **not** conflict.
* *Example*: Person A with `end_date=Oct 3` and Person B with `start_date=Oct 3` have no overlap. Person A leaves on Oct 3, and Person B arrives on Oct 3.

#### Overlap Detection
* Two assignments for the same `sleeping_place` are considered overlapping if their `[start_date, end_date)` intervals mathematically intersect.
* When an overlap is detected, the system generates an `ACCOMMODATION_OVERLAP` alert. The manager must resolve this manually.

#### Person Without Sleeping Place
* The system evaluates each night within the event's active accommodation period. If a person has no active `AccommodationAssignment` for a given night, a `PERSON_WITHOUT_SLEEPING_PLACE` alert is generated.

#### Capacity Override
* Managers possess the authority to explicitly override standard capacity rules (e.g., placing an extra mattress in a room).
* This is achieved by utilizing the `is_locked` flag on the assignment, accompanied by mandatory `notes` explaining the override context.

#### Reassignment
* To move a person, the system mandates creating a new `AccommodationAssignment` and optionally cancelling or ending the previous one.
* The system must never silently update or mutate assignments to move people.

#### Temporary Assignment
* Assignments marked with `status=TEMPORARY` are surfaced distinctly in the user interface (e.g., visually differentiated).
* Temporary assignments are still completely subject to standard overlap rules and capacity constraints.


## SECTION 15: Tasks & Apartment Issues

### 15.1 Task Management

#### Task Model
* **id**: UUIDv4
* **event_id**: Foreign Key
* **title**: String
* **description**: Text
* **assignee_id**: Foreign Key to Person (Nullable)
* **priority**: Enum (`CRITICAL`, `HIGH`, `MEDIUM`, `LOW`)
* **due_date_utc**: Timestamp (Nullable)
* **due_date_local**: Timestamp (Nullable, utilized for display purposes)
* **status**: Enum (`NEW`, `IN_PROGRESS`, `WAITING`, `COMPLETED`, `CANCELLED`)
* **completed_at_utc**: Timestamp (Nullable)
* **cancelled_at_utc**: Timestamp (Nullable)
* **notes**: Text
* **created_at_utc**, **updated_at_utc**: Timestamp
* **is_deleted**: Boolean

#### Task Lifecycle
* Standard progression: `NEW` → `IN_PROGRESS` → `COMPLETED`
* Delayed progression: `NEW` → `IN_PROGRESS` → `WAITING` → `IN_PROGRESS` → `COMPLETED`
* Cancellation: Any non-terminal state can transition to `CANCELLED`.
* Terminal states (`COMPLETED`, `CANCELLED`) can be explicitly restored to active states by a manager.

#### Overdue Detection
* If a task's `due_date_utc` is in the past (`< now`) AND its `status` is NOT IN (`COMPLETED`, `CANCELLED`), the system generates an `OVERDUE_TASK` alert.

### 15.2 Apartment Issues

#### ApartmentIssue Model
* **id**: UUIDv4
* **apartment_id**: Foreign Key
* **event_id**: Foreign Key
* **title**: String
* **description**: Text
* **reporter_id**: Foreign Key to Person (Nullable)
* **priority**: Enum (`CRITICAL`, `HIGH`, `MEDIUM`, `LOW`)
* **status**: Enum (`OPEN`, `IN_PROGRESS`, `RESOLVED`, `CLOSED`)
* **resolved_at_utc**: Timestamp (Nullable)
* **resolution_notes**: Text
* **photos_json**: JSON (Nullable, containing local file references)
* **notes**: Text
* **created_at_utc**, **updated_at_utc**: Timestamp
* **is_deleted**: Boolean

#### Issue Alerting
* Any issue where the `status` is NOT IN (`RESOLVED`, `CLOSED`) immediately generates an `UNRESOLVED_APARTMENT_ISSUE` alert.


## SECTION 16: Financial & Multi-Currency System

### 16.1 Core Design Principles
* **Preservation of Origin**: Original transaction currencies and amounts are ALWAYS preserved unconditionally.
* **Derived Conversions**: Converted or base amounts are strictly derived data; they never overwrite origin values.
* **Reproducibility**: Exchange rates utilized for conversions are preserved to guarantee historical reproducibility.
* **Transparency**: No undocumented or implicit conversions occur.
* **Locking**: Managers can lock finalized financial calculations to prevent future rate fluctuations from altering historical records.

### 16.2 Financial Models

#### Expense Model
* **id**: UUIDv4
* **event_id**: Foreign Key
* **description**: String
* **category**: String
* **original_amount**: Decimal
* **original_currency**: ISO 4217
* **base_amount**: Decimal (Derived)
* **base_currency**: ISO 4217 (Inherited from Event)
* **exchange_rate**: Decimal
* **exchange_rate_source**: Enum (`MANUAL`, `IMPORTED`)
* **exchange_rate_timestamp_utc**: Timestamp
* **payer_id**: Foreign Key to Person (Nullable)
* **expense_date**: Date
* **receipt_reference**: String
* **notes**: Text
* **is_locked**: Boolean
* **created_at_utc**, **updated_at_utc**: Timestamp
* **is_deleted**: Boolean

#### Payment Model
* **id**: UUIDv4
* **event_id**: Foreign Key
* **person_id**: Foreign Key
* **amount**: Decimal
* **currency**: ISO 4217
* **base_amount**: Decimal (Derived)
* **base_currency**: ISO 4217
* **exchange_rate**: Decimal
* **exchange_rate_source**: Enum (`MANUAL`, `IMPORTED`)
* **exchange_rate_timestamp_utc**: Timestamp
* **payment_date**: Date
* **payment_method**: Enum (`CASH`, `BANK_TRANSFER`, `CREDIT_CARD`, `CHECK`, `OTHER`, `CUSTOM`)
* **reference**: String
* **notes**: Text
* **is_locked**: Boolean
* **created_at_utc**, **updated_at_utc**: Timestamp
* **is_deleted**: Boolean

### 16.3 Logic and Rules

#### Financial totals and deferred allocation
* All monetary amounts with a recorded rate are converted to the event's `base_currency` using that precise recorded `exchange_rate`.
* Expense allocation, participant share, and therefore a final per-person unpaid balance are **not defined for MVP implementation**. There is no authoritative formula and no allocation entity in this baseline.
* The `UNPAID_BALANCE` code remains a reserved, inactive rule definition. Phase 1 must not evaluate it or display a calculated unpaid balance until the Product Owner approves the allocation model and acceptance tests.
* The later financial feature phase may persist and list `Expense` and `Payment`, validate/reproduce their individual base conversions, and show non-allocated event-level totals only. It must not infer allocation from payments, names, groups, or equal shares.

#### Currency Rules
* **No Invention**: The system explicitly never invents or guesses exchange rates.
* **Manual Rates**: Managers can manually input an exchange rate, marking the source as `MANUAL`.
* **Imported Rates**: (Future Capability) The system will support importing rates, marking the source as `IMPORTED`.
* **Preservation**: The specific rate utilized for a finalized calculation is preserved via the `is_locked` mechanism.
* **Reproducibility Guarantee**: Historical calculations must remain reproducible. Identical inputs processed with identical stored rates must yield the exact same result.
* **Immutability**: Original monetary information is never replaced or obfuscated by converted information.

---

## SECTION 17: Control Center

The Control Center is the primary operational dashboard. It is NOT a passive statistics page.

**Purpose**: Give the manager an immediate, prioritized operational picture.

**Content (prioritized)**:
1. Critical unresolved items (CRITICAL priority)
2. High-priority unresolved items
3. Overdue tasks
4. Today's arrivals and departures
5. Active transport gaps (passengers without transport)
6. Accommodation gaps (persons without sleeping place)
7. Unresolved apartment issues
8. Vehicle overcapacity alerts
9. Non-allocated event-level financial totals; per-person unpaid balances are unavailable pending OPD-002/003
10. Approaching deadlines (tasks due within configurable window)
11. Event lifecycle status
12. Summary counts (people, flights, trips, assignments, tasks)

Every actionable item must have a direct tap/navigation path to the relevant entity and resolution workflow.

Control Center must trigger time-dependent rule evaluation on open.

Control Center must not become a second source of truth. It reads from derived state only.

## SECTION 18: Reactive Domain Rules Engine

**Purpose**: Detect, calculate, and surface operational conditions from source data.

**Properties**:
- **Deterministic**: same inputs → same outputs.
- **Deterministic Alert Identity**: `deterministicAlertId = SHA-256(canonical(ruleCode, entityType, entityId, scopeKey))`. Same rule + same entity + same scope yields the exact same alert ID. Re-evaluation never creates duplicate alerts, and existing manager acknowledgment states remain attached to the logical alert. Random UUIDs are forbidden for logical alert identity.
- **Domain-scoped**: rules belong to specific operational domains.
- **Testable**: every rule is tested with pure Dart unit tests against known inputs.
- **Idempotent**: repeated evaluation produces identical results with zero duplicate active records.
- **Explainable**: each rule describes what it detected, why, and provides direct resolution options.
- **Lightweight**: pure Dart implementation with zero external framework dependencies.

**Rule Domains & Approved Rule Codes**:

| Domain | Prefix | Rule Code | Severity | Description / Trigger Condition |
|---|---|---|---|---|
| PEOPLE | PPL | PERSON_WITHOUT_SLEEPING_PLACE | HIGH | Person has no active accommodation assignment for event dates |
| PEOPLE | PPL | PERSON_WITHOUT_TRANSPORT | HIGH | Person has no trip passenger assignment for inbound/outbound travel |
| PEOPLE | PPL | PASSPORT_EXPIRY_RISK | HIGH | `Person.passport_expiration_date` is within 6 months of event departure date (`Event.start_date`) |
| FLIGHTS | FLT | FLIGHT_DELAY_IMPACT | MEDIUM | Flight delayed; advisory issued for manager to review transport alignment |
| FLIGHTS | FLT | FLIGHT_CANCELLED | CRITICAL | Flight cancelled; passengers and transport require immediate manual reallocation |
| FLIGHTS | FLT | DUPLICATE_FLIGHT_ASSIGNMENT | HIGH | Person assigned to multiple inbound or multiple outbound flights with overlapping or within-12h schedules |
| FLIGHTS | FLT | FLIGHT_MISSING_INFO | MEDIUM | Required schedule or airport information is absent, so dependent transport assessment is degraded |
| TRANSPORT | TRN | VEHICLE_OVER_CAPACITY | HIGH | Assigned passengers on a trip exceed `Vehicle.capacity` |
| TRANSPORT | TRN | TRN_NO_DRIVER | HIGH | `Trip` scheduled within 2 hours of departure (`scheduled_departure_utc`) without an assigned `Driver` |
| TRANSPORT | TRN | UNLINKED_FLIGHT_ARRIVAL | MEDIUM | Inbound `FlightPassenger` arriving without a `TripPassenger` assignment on a trip departing within 3 hours of flight arrival |
| TRANSPORT | TRN | TRIP_VEHICLE_UNAVAILABLE | HIGH | A non-cancelled trip references a vehicle whose status is MAINTENANCE or UNAVAILABLE |
| ACCOMMODATION | ACC | ACCOMMODATION_OVERLAP | HIGH | Two active assignments for the same `SleepingPlace` overlap in date range |
| ACCOMMODATION | ACC | OVERFLOW_ROOM_CAPACITY | HIGH | Active assignments for a `Room` on any date exceed total active `SleepingPlace` bed count in that room |
| TASKS | TSK | OVERDUE_TASK | HIGH | Task incomplete and past `due_date_utc` |
| APARTMENT_ISSUES | APT | UNRESOLVED_APARTMENT_ISSUE | MEDIUM | Apartment issue logged with status OPEN or IN_PROGRESS |
| FINANCE | FIN | UNPAID_BALANCE | MEDIUM | Reserved/inactive until Product Owner approves expense allocation and participant-share semantics (OPD-002/003) |
| FINANCE | FIN | EXPENSE_WITHOUT_RATE | MEDIUM | A non-base-currency expense or payment lacks the recorded exchange rate needed for conversion |
| PEOPLE | PPL | PERSON_MISSING_CRITICAL_INFO | MEDIUM | A manager-selected required travel-contact field is absent; the required-field policy is event-scoped |
| OPERATIONS | OPS | EVENT_LIFECYCLE_TRANSITION_NEEDED | INFO | Event stage transition criteria met |

**Trigger & Evaluation Model**:
- **Full Evaluation**: Executed on app startup integrity check, manual audit, data recovery, or explicit full refresh.
- **Scoped Evaluation**: Executed during normal CRUD operations. The system identifies the affected scope (e.g., accommodation scope, transport scope) and re-evaluates only relevant rules and queries. Full-database loading is forbidden for ordinary CRUD-triggered evaluations.
- **Hybrid Scheduling Policy**: High-priority isolated changes trigger immediate scoped evaluation. Bursts of related edits trigger a debounced/throttled evaluation (target 300ms initial parameter) to coalesce changes before updating unresolved state and notifying UI.

**Rule Output**: Each rule evaluation produces zero or more deterministic `UnresolvedItem` records (or auto-resolves obsolete items).

## SECTION 19: Unresolved Operational State

`UnresolvedItem`: id (SHA-256 deterministic hash, PK), event_id (FK), rule_code, entity_type, entity_id (UUIDv4), scope_key (nullable composite key), severity (CRITICAL/HIGH/MEDIUM/LOW/INFO), title, description, status (DETECTED/ACKNOWLEDGED/RESOLVED/DISMISSED), detected_at_utc, acknowledged_at_utc, resolved_at_utc, dismissed_at_utc, dismissed_reason, auto_resolved (BOOLEAN), resolution_notes, created_at_utc, updated_at_utc, deleted_at_utc (nullable), version (INT, default 1), last_modified_by_device_id (nullable string)

`UnresolvedItem` is NEVER source data. It is derived operational state.

The source entity remains authoritative. `UnresolvedItem` is a lens into source data.

**Deterministic Identity Algorithm**:
- Canonical string: `rule_code + "|" + entity_type + "|" + entity_id + "|" + (scope_key ?? "")`
- `id` = `sha256(canonical_string).toHex()`
- Prevents duplicate active items across evaluations and preserves manager acknowledgment state.

**Control Center Triage & Interaction Safeguards**:
- **Triage**: Control Center supports grouping alerts by Location (Building/Airport), Entity, or Rule Type, and filtering by Severity.
- **Direct Action Deep-Links**: Alerts contain direct action paths (e.g., "Assign Bed", "Assign Driver", "Reassign Bus", "Review Passenger", "Open Flight").
- **Interaction Safeguards**: Bulk dismissal is permitted only for non-critical informational advisories. Critical and High severity alerts require explicit individual manager interaction.

**Lifecycle and deterministic upsert semantics**:
- **DETECTED**: a newly observed condition. Set `detected_at_utc`, `created_at_utc`, and `updated_at_utc` to the evaluation time; set `auto_resolved=FALSE`, with all resolution timestamps null.
- **ACKNOWLEDGED**: manager has seen it; it remains active. Re-evaluation of the same active identity preserves status, acknowledgment fields, and the original `detected_at_utc`.
- **RESOLVED**: condition disappeared during evaluation (`auto_resolved=TRUE`) or a manager explicitly resolved it (`auto_resolved=FALSE`). Set `resolved_at_utc` only on that transition.
- **DISMISSED**: manager explicitly dismissed it. The default `OperationalRule.re_trigger_after_dismiss` is FALSE; while false, a still-present or recurring condition does not reopen that logical item. If a manager enables it, a later recurrence reopens the same deterministic ID as DETECTED with a new detection timestamp.
- For every scoped evaluation, upsert the returned deterministic IDs and compare them only with active items in that same event and rule scope. Any previously active DETECTED/ACKNOWLEDGED item in that scope that is absent from the new result transitions once to RESOLVED with `auto_resolved=TRUE`. Do not mark a newly detected issue auto-resolved, and do not resolve a still-returned item.
- Pair and multi-entity scopes must be canonical. For an unordered pair, `scope_key = sort([id1, id2]).join('|')`; never use iteration order.

## SECTION 20: Today View

Today is a time-oriented operational view showing what matters RIGHT NOW.

**Content**:
- Today's trips (departures, arrivals)
- Today's flight arrivals and departures
- Overdue tasks
- Tasks due today
- Accommodation changes today (check-ins, check-outs)
- Active apartment issues
- Time-sensitive unresolved items
- Important financial actions due today

Today must NEVER become a second source of truth. It reads from the same domain data as everything else.

**Time reference**: 'Today' is determined by the device's local date. Stored UTC times are converted for display.

Today triggers time-dependent rule evaluation on open.

## SECTION 21: Universal Search

Search operates across the ACTIVE event only. Event isolation is absolute.

**Searchable content**:
- Person names (first, last, Hebrew, English)
- Phone numbers (normalized matching)
- Flight numbers
- Airline names
- Airport codes
- Apartment names and addresses
- Room names
- Driver names
- Vehicle identifiers and license plates
- Task titles and descriptions
- Apartment issue titles
- Notes fields
- Expense descriptions and categories
- Payment references

**Search requirements**:
- Hebrew text support
- English text support
- Mixed Hebrew/English queries
- Partial matching
- Case-insensitive for Latin text
- Diacritic-insensitive where practical
- Results grouped by entity type
- Soft-deleted records excluded from default search (optionally includable)
- Performance: < 80ms on benchmark dataset

## SECTION 22: Bilingual UX — Hebrew RTL / English LTR & Operational Ergonomics

**Bilingual & BIDI Requirements**:
- Full Hebrew RTL interface.
- Full English LTR interface.
- Runtime language switching without app restart.
- **Centralized BIDI Text Formatting Helper**: Mixed-directional strings (Hebrew names, English flight numbers, phone numbers, passport IDs, dates, room numbers, bus codes) MUST be processed via a centralized formatting abstraction (`BidiTextFormatter`) utilizing Unicode directional isolation markers (`\u200E` LRM / `\u200F` RLM) or Flutter bidi utilities. Manual, inline insertion of raw directional unicode control characters across UI widgets is forbidden.
- Logical directional layout: `Start`/`End`, `Leading`/`Trailing` padding and alignment — NOT hard-coded `Left`/`Right`.
- Changing interface language MUST NEVER alter stored source data.
- User-entered Hebrew text preserved exactly (no transliteration, no normalization).
- User-entered English text preserved exactly.
- All system labels, messages, and navigation bilingual.
- Date and number formatting localized per locale.
- Universal Search handles both Hebrew and English simultaneously.

**High-Stress Outdoor & Low-Light Operational UX**:
- **High-Contrast Dark Theme**: Native support for high-contrast dark theme for low-light operations (e.g., unlit bus terminals or late-night flights) and high-visibility light theme for direct outdoor Ukrainian sunlight.
- **Legibility & Touch Targets**: Touch targets must meet minimum 48x48dp dimensions; typography optimized for rapid scanning under operational stress.
- **Multi-Modal Severity Communication**: Severity states (CRITICAL, HIGH, MEDIUM) must be communicated through text labels, iconography, typography, and visual structure — NEVER by color alone.
- **Haptic Feedback**: Optional tactile haptic feedback on critical operational warnings and destructive confirmations.

## SECTION 23: External Sharing Snapshots & PII Sanitization

The system generates static, point-in-time read-only snapshots for sharing via WhatsApp, SMS, email, or local file export.

**Snapshot Types**:
- Transport manifest (trip route, departure time, driver, vehicle, assigned passengers)
- Accommodation manifest (building, room, sleeping place, dates, assigned participants)
- Arrival manifest (expected arrivals by date/flight)
- Departure manifest (expected departures by date/flight)
- Task list (assigned tasks with status)
- Participant contact list
- Operational summary
- Financial summary (configurable detail level)

**PII Sanitization & Masking Policy**:
- **Default Behavior (`PII MASKING = ON`)**: Sensitive personal identification data is automatically masked in generated external text snapshots:
  - Passport numbers: masked to last 4 digits (e.g., `****1234`)
  - Phone numbers: masked to last 4 digits (e.g., `***-***-1234`)
- **Operational Necessity Exception**: Full participant names, room numbers, and trip details are retained unmasked as they are operationally necessary for flight check-in and vehicle boarding.
- **Explicit Unmasked Export**: The manager can trigger an explicit user action: **"Export Full Details (Unmasked)"**. The system must display a privacy confirmation warning explaining the exposure before generating an unmasked snapshot.

**Snapshot Properties**:
- Contains event name and UTC/local generation timestamp.
- Clearly identifiable header marking it as a static point-in-time document, NOT live data.
- Plain text formatted for immediate readability on WhatsApp and mobile messaging apps.
- Bilingual (Hebrew/English) format support.
- Creates no remote state, no cloud records, no external server calls.

## SECTION 24: Data Integrity & Record Lifecycle

Distinct operations — each has different semantics:

| Operation | Meaning | Data Preserved? | Reversible? | Example |
|---|---|---|---|---|
| Delete (soft) | Mark record as logically removed | Yes (is_deleted=TRUE, deleted_at_utc=TIMESTAMP) | Yes (restore) | Remove a person added by mistake |
| Archive | Make record historical/inactive | Yes | Manager decision | Event after closeout |
| Cancel | Mark planned operation as cancelled | Yes (status=CANCELLED) | Manager can reactivate | Cancel a trip |
| Unassign | Remove a relationship, not the entity | Both entities preserved | Re-assignable | Remove person from sleeping place |
| Resolve | Close a derived/operational condition | Condition record preserved | Can reopen if condition recurs | Resolve apartment issue |
| Restore | Reactivate a soft-deleted record | Yes | N/A | Restore accidentally deleted person |

Rules:
- No operation may silently orphan important relationships.
- Atomic operations: where multiple records must change together, the operation must be atomic (all succeed or all fail).
- Cascade behavior: soft-deleting a parent does NOT auto-delete children. Children retain their own lifecycle. The system surfaces orphaned relationships as alerts.
- Referential integrity: FK relationships enforced. Cannot create a TripPassenger referencing a non-existent Person.

## SECTION 25: Backup, Restore & Recovery

Canonical recovery uses operator-controlled PostgreSQL backups and isolated restore verification. No client may replace server data using a local cache. Preserve backup integrity, explicit destructive approval and recovery testing; encrypted portable export is deferred beyond the cloud foundation.

## SECTION 26: Security & Privacy

Supabase Auth is mandatory. TLS protects transport; event-membership RLS and restricted RPCs protect data. Sessions and small caches use platform-secure storage. No privileged key ships in Flutter. No password, token or passport data in logs. Passport access/retention must be reviewed before Person delivery; do not introduce custom encryption. See Technical v1.2 threat controls and ADR-001.

## SECTION 27: Cloud-First Architecture

PostgreSQL is the only source of truth. Flutter presentation uses application controllers and pure-Dart repository contracts implemented in Supabase infrastructure. Cached reads remain available temporarily offline, visibly stale. All writes require connectivity and server confirmation. No offline mutation queue or independent local master.

## SECTION 28: Realtime & Concurrency

Subscribe to domain changes, then reload canonical state on startup/login, subscription/reconnect, foreground, mutation and conflict. Every mutable record uses server attribution/timestamps and an integer version. Stale expected versions are rejected; preserve the draft and require intentional resolution. No silent last-write-wins. Realtime is notification, never integrity enforcement.

## SECTION 29: Authentication & Event Authorization

Yonatan and Yosef have distinct Supabase Auth accounts. event_members assigns administrator roles per event. RLS rejects anonymous and non-member reads; RPCs enforce membership on every write. Provision memberships through controlled backend operations. Additional managers require membership, not schema redesign.

## SECTION 30: Mandatory Audit Trail

Every material mutation atomically emits a server-generated audit entry: id, event_id, actor_user_id, timestamp, entity_type, entity_id, operation, old/new snapshots. Client writes to audit are forbidden. Archive/restore and later payment, assignment and alert operations must be attributable. Privileged backend administration remains a trusted operational boundary.

## SECTION 31: Data Import & Export

Import:
- Supported: structured data import (e.g., participant list from CSV/Excel)
- Event-scoped: imported data belongs to the target event
- Behavior: never silently overwrite existing records
- Duplicate detection: warn on potential duplicates (name + phone match)
- Manager reviews and confirms each import batch
- Mapping: manager maps import columns to entity fields
- Validation: invalid records flagged, not silently skipped
- Atomic: import batch succeeds or fails as a unit
- Recovery: interrupted import leaves no partial state

Export:
- Structured export of event data (CSV, JSON)
- Filtered export (specific entities, date ranges)
- Export includes source data only (not derived state)
- Export is event-scoped
- Export does not modify source data

Not in MVP:
- Generic integration platform
- API-based import/export
- Automated recurring imports
- Remote data source connections

## SECTION 32: Database Migration & Versioning

Version-controlled Supabase SQL migrations define schema, indexes, FKs, checks, RLS, grants, functions, triggers and publication. Deploy in order through backend tooling, never from a phone. Destructive changes require verified backups. PostgreSQL transactions roll back failed migration steps. Clients use compatible API versions and rebuild disposable caches.

## SECTION 33: Performance Requirements & Benchmark Methodology

Benchmark dataset:
- 1,000 participants
- 50 flights with 1,200 flight-passenger records
- 500 trips with 2,500 trip-passenger records
- 30 apartments, 120 rooms, 400 sleeping places
- 1,200 accommodation assignments
- 300 tasks
- 80 apartment issues
- 2,000 expense records
- 1,500 payment records
- 200 active unresolved items
- 20 drivers, 15 vehicles

Target performance benchmarks:
| Operation | Cold | Warm | Target |
|---|---|---|---|
| App launch to interactive | First launch | - | < 1.5s |
| App launch to interactive | Subsequent | - | < 800ms |
| Control Center render | - | Data cached | < 100ms |
| Control Center render | - | Fresh query | < 300ms |
| Universal search (typed query) | - | - | < 80ms per keystroke |
| Entity list render (100 items) | - | - | < 50ms |
| Entity list scroll (infinite) | - | - | 60fps |
| Single entity CRUD | - | - | Measure server latency separately; never imply local commit |
| Rule evaluation (single domain) | - | - | < 30ms |
| Rule evaluation (full event) | - | - | < 200ms |
| Backup preparation | - | - | < 5s |
| Backup write | - | - | Proportional to data size |

Representative test device: Mid-range Android device (e.g., Samsung Galaxy A-series, 2023+) with 4GB RAM.

Measurement methodology:
- Cold launch: app process killed, measurement from tap to interactive UI
- Warm launch: app in background, measurement from foreground to interactive
- All measurements on benchmark dataset
- 10 measurements, report p50 and p95
- Acceptable variance: ±20%
- Regression threshold: >30% degradation from baseline triggers investigation

Performance principles:
- No unnecessary full-table scans
- No repeated identical queries within single operation
- No loading entire datasets into memory
- No evaluating unrelated domains during rule checks
- Lazy loading for lists
- Indexed search columns
- Batch operations where appropriate

## SECTION 34: Conceptual Data Model & Relationship Schema

Present the COMPLETE conceptual data model.

> [!NOTE]
> All mutable business entities require event scope, server UUIDs, timestamps, created_by, updated_by, version and soft-delete metadata. Junctions carry event_id with composite same-event FKs. Audit is immutable; deterministic alert IDs are retained. Technical v1.2 contains the entity migration review.

For EACH entity, document:
- Purpose (1-2 sentences)
- Fields (name, type, source/derived classification, nullable, constraints)
- Relationships (to which entities, cardinality, FK)
- Lifecycle (creation, modification, deletion, archival)
- Event ownership (direct via event_id, or indirect through parent)
- Validation rules
- Integrity constraints

Entities:

### 1. Event
Root container. All operational data scoped to one event.
- Fields: id (UUID, PK), name (TEXT, required), hebrew_name (TEXT), description (TEXT), year (INT), start_date (DATE), end_date (DATE), base_currency (TEXT, ISO 4217, required), lifecycle_stage (ENUM, required), manager_notes (TEXT), settings_json (TEXT), created_at_utc, updated_at_utc, is_deleted, deleted_at_utc (DATETIME, nullable), version (INT, default 1), created_by (UUID, required), updated_by (UUID, required)
- Relationships: parent of all event-scoped entities
- Event ownership: self
- Lifecycle: Create → lifecycle transitions → Archive

### 2. Person
An individual participating in an event.
- Fields: id (UUID, PK), event_id (UUID, FK→Event, required), first_name (TEXT, required), last_name (TEXT), hebrew_first_name (TEXT), hebrew_last_name (TEXT), phone (TEXT), whatsapp_phone (TEXT), email (TEXT), passport_name (TEXT), passport_number (TEXT), passport_expiration_date (DATE, nullable), date_of_birth (DATE), nationality (TEXT), emergency_contact_name (TEXT), emergency_contact_phone (TEXT), notes (TEXT), custom_fields_json (TEXT), status (ENUM: ACTIVE/INACTIVE, default ACTIVE), created_at_utc, updated_at_utc, is_deleted, deleted_at_utc (DATETIME, nullable), version (INT, default 1), created_by (UUID, required), updated_by (UUID, required)
- Relationships: →FlightPassenger(1:N), →TripPassenger(1:N), →AccommodationAssignment(1:N), →Task.assignee(1:N), →ApartmentIssue.reporter(1:N), →Expense.payer(1:N), →Payment(1:N)
- Event ownership: direct (event_id)
- Validation: first_name required, event_id required

### 3. Driver
A person who drives transport vehicles (separate from Person entity).
- Fields: id (UUID, PK), event_id (UUID, FK→Event), name (TEXT, required), phone (TEXT), whatsapp_phone (TEXT), license_info (TEXT), notes (TEXT), status (ENUM: AVAILABLE/BUSY/UNAVAILABLE/OFF_DUTY), created_at_utc, updated_at_utc, is_deleted, deleted_at_utc (DATETIME, nullable), version (INT, default 1), created_by (UUID, required), updated_by (UUID, required)
- Relationships: →Trip.driver_id(1:N)
- Event ownership: direct

### 4. Flight
A scheduled or actual flight movement.
- Fields: id (UUID, PK), event_id (UUID, FK→Event), direction (ENUM: INBOUND/OUTBOUND), airline (TEXT), flight_number (TEXT), departure_airport (TEXT), arrival_airport (TEXT), scheduled_departure_utc (DATETIME), scheduled_arrival_utc (DATETIME), actual_departure_utc (DATETIME, nullable), actual_arrival_utc (DATETIME, nullable), status (ENUM: SCHEDULED/DELAYED/CANCELLED/DIVERTED/LANDED/UNKNOWN), delay_minutes (INT, nullable), terminal (TEXT), gate (TEXT), notes (TEXT), is_locked (BOOL, default FALSE), created_at_utc, updated_at_utc, is_deleted, deleted_at_utc (DATETIME, nullable), version (INT, default 1), created_by (UUID, required), updated_by (UUID, required)
- Relationships: →FlightPassenger(1:N), →Trip.related_flight_id(1:N)
- Event ownership: direct

### 5. FlightPassenger
Junction: Person on a Flight.
- Fields: id (UUID, PK), flight_id (UUID, FK→Flight), person_id (UUID, FK→Person), seat_number (TEXT, nullable), booking_reference (TEXT, nullable), notes (TEXT), status (ENUM: CONFIRMED/TENTATIVE/CANCELLED), created_at_utc, updated_at_utc, is_deleted, deleted_at_utc (DATETIME, nullable), version (INT, default 1), created_by (UUID, required), updated_by (UUID, required)
- Event ownership: indirect through Flight→Event
- Unique constraint: (flight_id, person_id) — same person cannot be on same flight twice

### 6. Vehicle
A transport vehicle.
- Fields: id (UUID, PK), event_id (UUID, FK→Event), name (TEXT, required), vehicle_type (ENUM: CAR/VAN/MINIBUS/BUS/CUSTOM), capacity (INT, required, >0), license_plate (TEXT), color (TEXT), notes (TEXT), status (ENUM: AVAILABLE/IN_USE/MAINTENANCE/UNAVAILABLE), created_at_utc, updated_at_utc, is_deleted, deleted_at_utc (DATETIME, nullable), version (INT, default 1), created_by (UUID, required), updated_by (UUID, required)
- Relationships: →Trip.vehicle_id(1:N)
- Event ownership: direct

### 7. Trip
One transport movement.
- Fields: id (UUID, PK), event_id (UUID, FK→Event), direction (ENUM: INBOUND/OUTBOUND/LOCAL), origin (TEXT), destination (TEXT), scheduled_departure_utc (DATETIME), scheduled_arrival_utc (DATETIME, nullable), actual_departure_utc (DATETIME, nullable), actual_arrival_utc (DATETIME, nullable), driver_id (UUID, FK→Driver, nullable), vehicle_id (UUID, FK→Vehicle, nullable), related_flight_id (UUID, FK→Flight, nullable), status (ENUM: PLANNED/CONFIRMED/IN_PROGRESS/COMPLETED/CANCELLED), notes (TEXT), is_locked (BOOL), created_at_utc, updated_at_utc, is_deleted, deleted_at_utc (DATETIME, nullable), version (INT, default 1), created_by (UUID, required), updated_by (UUID, required)
- Relationships: →TripPassenger(1:N)
- Event ownership: direct
- Constraint: if vehicle_id set, count(active TripPassengers) > Vehicle.capacity generates alert (not hard block), evaluated in a server transaction

### 8. TripPassenger
Junction: Person on a Trip.
- Fields: id (UUID, PK), trip_id (UUID, FK→Trip), person_id (UUID, FK→Person), pickup_location (TEXT), pickup_notes (TEXT), passenger_status (ENUM: ASSIGNED/CONFIRMED/PICKED_UP/DROPPED_OFF/NO_SHOW/CANCELLED), notes (TEXT), created_at_utc, updated_at_utc, is_deleted, deleted_at_utc (DATETIME, nullable), version (INT, default 1), created_by (UUID, required), updated_by (UUID, required)
- Event ownership: indirect through Trip→Event

### 9. Apartment
An accommodation unit.
- Fields: id (UUID, PK), event_id (UUID, FK→Event), name (TEXT, required), address (TEXT), hebrew_address (TEXT), floor (TEXT), entry_code (TEXT), landlord_name (TEXT), landlord_phone (TEXT), notes (TEXT), status (ENUM: ACTIVE/UNAVAILABLE/CLOSED), total_cost (DECIMAL, nullable), cost_currency (TEXT, nullable), cost_notes (TEXT), created_at_utc, updated_at_utc, is_deleted, deleted_at_utc (DATETIME, nullable), version (INT, default 1), created_by (UUID, required), updated_by (UUID, required)
- Relationships: →Room(1:N), →ApartmentIssue(1:N)
- Event ownership: direct

### 10. Room
A room within an apartment.
- Fields: id (UUID, PK), apartment_id (UUID, FK→Apartment), name (TEXT, required), floor (TEXT), description (TEXT), notes (TEXT), created_at_utc, updated_at_utc, is_deleted, deleted_at_utc (DATETIME, nullable), version (INT, default 1), created_by (UUID, required), updated_by (UUID, required)
- Relationships: →SleepingPlace(1:N)
- Event ownership: indirect through Apartment→Event

### 11. SleepingPlace
A specific sleeping position within a room.
- Fields: id (UUID, PK), room_id (UUID, FK→Room), label (TEXT, required), type (ENUM: REGULAR_BED/BUNK_BED/SOFA_BED/MATTRESS/CUSTOM), custom_type_name (TEXT, nullable), position_notes (TEXT), is_active (BOOL, default TRUE), created_at_utc, updated_at_utc, is_deleted, deleted_at_utc (DATETIME, nullable), version (INT, default 1), created_by (UUID, required), updated_by (UUID, required)
- Relationships: →AccommodationAssignment(1:N)
- Event ownership: indirect through Room→Apartment→Event
- DO NOT add occupant_id here

### 12. AccommodationAssignment
The authoritative occupancy relationship.
- Fields: id (UUID, PK), sleeping_place_id (UUID, FK→SleepingPlace), person_id (UUID, FK→Person), start_date (DATE, inclusive), end_date (DATE, exclusive), status (ENUM: ACTIVE/TEMPORARY/CANCELLED), notes (TEXT), is_locked (BOOL), created_at_utc, updated_at_utc, is_deleted, deleted_at_utc (DATETIME, nullable), version (INT, default 1), created_by (UUID, required), updated_by (UUID, required)
- Event ownership: indirect through SleepingPlace→Room→Apartment→Event
- Transactional rule: detect overlapping [start_date, end_date) for same sleeping_place_id where status != CANCELLED and is_deleted = FALSE; persist ACCOMMODATION_OVERLAP without silently discarding an explicit manager assignment (AC-01)
- Date semantics: start_date inclusive, end_date exclusive. Person sleeps nights start_date through end_date-1.

### 13. Task
An operational task.
- Fields: id (UUID, PK), event_id (UUID, FK→Event), title (TEXT, required), description (TEXT), assignee_id (UUID, FK→Person, nullable), priority (ENUM: CRITICAL/HIGH/MEDIUM/LOW), due_date_utc (DATETIME, nullable), status (ENUM: NEW/IN_PROGRESS/WAITING/COMPLETED/CANCELLED), completed_at_utc, cancelled_at_utc, notes (TEXT), created_at_utc, updated_at_utc, is_deleted, deleted_at_utc (DATETIME, nullable), version (INT, default 1), created_by (UUID, required), updated_by (UUID, required)
- Event ownership: direct

### 14. ApartmentIssue
An issue reported for an apartment.
- Fields: id (UUID, PK), event_id (UUID, FK→Event), apartment_id (UUID, FK→Apartment), title (TEXT, required), description (TEXT), reporter_id (UUID, FK→Person, nullable), priority (ENUM: CRITICAL/HIGH/MEDIUM/LOW), status (ENUM: OPEN/IN_PROGRESS/RESOLVED/CLOSED), resolved_at_utc, resolution_notes (TEXT), notes (TEXT), created_at_utc, updated_at_utc, is_deleted, deleted_at_utc (DATETIME, nullable), version (INT, default 1), created_by (UUID, required), updated_by (UUID, required)
- Event ownership: direct (also linked through apartment)

### 15. Expense
A financial expense record.
- Fields: id (UUID, PK), event_id (UUID, FK→Event), description (TEXT, required), category (TEXT), original_amount (DECIMAL, required, source), original_currency (TEXT, ISO 4217, required, source), base_amount (DECIMAL, derived), base_currency (TEXT, derived from Event), exchange_rate (DECIMAL, source once set), exchange_rate_source (ENUM: MANUAL/IMPORTED, source), exchange_rate_timestamp_utc (DATETIME), payer_id (UUID, FK→Person, nullable), expense_date (DATE), receipt_reference (TEXT), notes (TEXT), is_locked (BOOL), created_at_utc, updated_at_utc, is_deleted, deleted_at_utc (DATETIME, nullable), version (INT, default 1), created_by (UUID, required), updated_by (UUID, required)
- Event ownership: direct

### 16. Payment
A payment from a participant.
- Fields: id (UUID, PK), event_id (UUID, FK→Event), person_id (UUID, FK→Person, required), amount (DECIMAL, required, source), currency (TEXT, ISO 4217, required, source), base_amount (DECIMAL, derived), base_currency (TEXT, derived from Event), exchange_rate (DECIMAL, source once set), exchange_rate_source (ENUM: MANUAL/IMPORTED), exchange_rate_timestamp_utc (DATETIME), payment_date (DATE), payment_method (ENUM: CASH/BANK_TRANSFER/CREDIT_CARD/CHECK/OTHER), reference (TEXT), notes (TEXT), is_locked (BOOL), created_at_utc, updated_at_utc, is_deleted, deleted_at_utc (DATETIME, nullable), version (INT, default 1), created_by (UUID, required), updated_by (UUID, required)
- Event ownership: direct

### 17. OperationalRule (event-scoped configuration)
Defines the enabled/configured behavior of one canonical rule for one event. The code catalog is an application constant; this record is the event-scoped configuration, not a second code registry.
- Fields: id (UUIDv4, PK), event_id (UUID, FK→Event, required), rule_code (TEXT, required, canonical catalog member), domain (TEXT), severity_default (ENUM), title_template (TEXT), description_template (TEXT), is_active (BOOL, default TRUE), is_dismissable (BOOL), re_trigger_after_dismiss (BOOL, default FALSE), created_at_utc, updated_at_utc, is_deleted, deleted_at_utc (DATETIME, nullable), version (INT, default 1), created_by (UUID, required), updated_by (UUID, required)
- Event ownership: direct. Unique constraint: `(event_id, rule_code)`.
- Validation: `rule_code` must exactly match the canonical catalog in Section 18. The rules implementation phase seeds a row per catalog rule for a new event; reserved `UNPAID_BALANCE` is seeded inactive.

### 18. UnresolvedItem
Derived alert record.
- Fields: id (SHA-256 TEXT, PK), event_id (UUID, FK→Event), rule_code (TEXT), entity_type (TEXT), entity_id (UUID), scope_key (TEXT, nullable), severity (ENUM: CRITICAL/HIGH/MEDIUM/LOW/INFO), title (TEXT), description (TEXT), status (ENUM: DETECTED/ACKNOWLEDGED/RESOLVED/DISMISSED), detected_at_utc (DATETIME), acknowledged_at_utc (DATETIME, nullable), resolved_at_utc (DATETIME, nullable), dismissed_at_utc (DATETIME, nullable), dismissed_reason (TEXT, nullable), auto_resolved (BOOL, default FALSE), resolution_notes (TEXT, nullable), created_at_utc (DATETIME), updated_at_utc (DATETIME), deleted_at_utc (DATETIME, nullable), version (INT, default 1), created_by (UUID, required), updated_by (UUID, required)
- Event ownership: direct

### 19. AuditEntry
Historical record of operations.
- Fields: id (UUID, PK), event_id (UUID, FK→Event, required), entity_type (TEXT), entity_id (UUID), action (ENUM: CREATE/UPDATE/DELETE/RESTORE/ASSIGN/UNASSIGN/STATUS_CHANGE/LOCK/UNLOCK), timestamp_utc (DATETIME), changes_json (TEXT, nullable), actor_user_id (UUID, required), notes (TEXT)
- Event ownership: direct where applicable
- Append-only: never modified, never deleted
- Mandatory server-generated entries for all material mutations

Relationship diagram (describe in words — mermaid optional):
- Event 1:N → Person, Driver, Vehicle, Flight, Trip, Apartment, Task, ApartmentIssue, Expense, Payment, UnresolvedItem
- Person 1:N → FlightPassenger, TripPassenger, AccommodationAssignment, Task(assignee), ApartmentIssue(reporter), Expense(payer), Payment
- Flight 1:N → FlightPassenger
- Flight 1:N → Trip(related_flight)
- Trip 1:N → TripPassenger
- Trip N:1 → Driver, Vehicle
- Apartment 1:N → Room, ApartmentIssue
- Room 1:N → SleepingPlace
- SleepingPlace 1:N → AccommodationAssignment
- AccommodationAssignment N:1 → Person, SleepingPlace

---

## SECTION 35: Uman Operational Edge Cases & Mitigation Rules

For EACH edge case, provide:
1. Source data affected
2. Derived consequence
3. Operational alert generated
4. Automatic behavior allowed
5. Manager confirmation required?
6. Result if manager takes no action
7. Data preservation requirement

Edge cases:

### Flight Delay
1. Source: Flight.actual_departure_utc later than scheduled, Flight.delay_minutes updated
2. Derived: Related trips may need time adjustment. FLIGHT_DELAY_IMPACT alert.
3. Alert: FLIGHT_DELAY_IMPACT — severity based on delay magnitude and transport dependency
4. Auto: Update flight status to DELAYED. Generate alert. NO auto-change to trips.
5. Manager: Yes — must review affected trips and decide whether to reschedule
6. No action: Alert remains active. Trips unchanged. Passengers may miss transport.
7. Preserve: Original schedule, actual times, all trip data unchanged

### Flight Cancellation
1. Source: Flight.status = CANCELLED
2. Derived: All passengers need alternative. All related trips affected.
3. Alert: FLIGHT_CANCELLED — CRITICAL severity
4. Auto: Update flight status. Generate alert. NO auto-change to passengers or trips.
5. Manager: Yes — must reassign passengers to alternative flights and review transport
6. No action: Alert remains critical. Passengers and trips unchanged.
7. Preserve: Original flight record, all passenger assignments (status updated)

### Flight Schedule Change
1. Source: Flight scheduled times updated by manager
2. Derived: Related trips may be misaligned
3. Alert: FLIGHT_DELAY_IMPACT if related trips exist
4. Auto: Generate alert only. NO auto-modify trips.
5. Manager: Yes
6. No action: Alert persists. Trips may be misaligned with actual flight times.
7. Preserve: Both old and new schedule (via audit), trip data unchanged

### Actual Arrival Differing from Schedule
1. Source: Flight.actual_arrival_utc differs from scheduled
2. Derived: Informational update. Transport may be affected.
3. Alert: FLIGHT_DELAY_IMPACT if significant; the threshold is event configuration, default 30 minutes
4. Auto: Record actual time. Generate alert if threshold exceeded.
5. Manager: Only if transport is affected
6. No action: Informational alert. Historical record preserved.
7. Preserve: Both scheduled and actual times

### Border Delay
1. Source: Not directly modeled. Manager updates Trip or Person notes.
2. Derived: Trip may be delayed.
3. Alert: None auto-generated. Manager can create manual task.
4. Auto: None
5. Manager: Discretionary
6. No action: No system impact
7. Preserve: Manager notes

### Driver Replacement
1. Source: Trip.driver_id changed
2. Derived: Previous driver freed. New driver assigned.
3. Alert: None (normal operation). Audit trail records change.
4. Auto: Update trip driver. No other changes.
5. Manager: Implicit (manager initiates the change)
6. N/A
7. Preserve: Audit entry of previous driver assignment

### Vehicle Replacement
1. Source: Trip.vehicle_id changed
2. Derived: Capacity may change. If new vehicle smaller, overcapacity possible.
3. Alert: VEHICLE_OVER_CAPACITY if new vehicle capacity < current passengers
4. Auto: Update trip vehicle. Generate capacity alert if needed.
5. Manager: If overcapacity results
6. No action: Overcapacity alert persists
7. Preserve: Audit entry of previous vehicle

### Vehicle Breakdown
1. Source: Vehicle.status = MAINTENANCE/UNAVAILABLE
2. Derived: Active trips using this vehicle affected
3. Alert: TRIP_VEHICLE_UNAVAILABLE for each affected trip
4. Auto: Generate alerts. NO auto-reassign vehicle.
5. Manager: Yes — must assign replacement vehicle
6. No action: Alerts persist. Trips show unavailable vehicle.
7. Preserve: Vehicle record, trip records unchanged

### Vehicle Overcapacity
1. Source: TripPassenger count > Vehicle.capacity for a trip
2. Derived: VEHICLE_OVER_CAPACITY
3. Alert: VEHICLE_OVER_CAPACITY — HIGH severity
4. Auto: Generate alert only. NEVER silently remove passengers.
5. Manager: Yes — must either remove passengers or assign larger vehicle
6. No action: Alert persists. All passengers remain assigned.
7. Preserve: All passenger assignments

### Passenger Added Last Minute
1. Source: New TripPassenger created
2. Derived: Capacity recheck triggered
3. Alert: VEHICLE_OVER_CAPACITY if capacity exceeded
4. Auto: Add passenger. Check capacity. Generate alert if needed.
5. Manager: If overcapacity
6. No action: Passenger added, alert persists if overcapacity
7. Preserve: All data

### Passenger Removed from Trip
1. Source: TripPassenger.status = CANCELLED or is_deleted
2. Derived: Capacity freed. Person may need alternative transport.
3. Alert: PERSON_WITHOUT_TRANSPORT if person has no other transport for this movement
4. Auto: Remove from trip. Check if person still has transport.
5. Manager: If person needs alternative transport
6. No action: Person has no transport for this leg. Alert persists.
7. Preserve: TripPassenger record (soft delete or cancelled status)

### Transport Reassignment
1. Source: Person moved from one trip to another
2. Derived: Capacity changes on both trips
3. Alert: Capacity alerts if either trip affected
4. Auto: Update assignments. Recheck capacity.
5. Manager: Initiates the change
6. N/A
7. Preserve: Audit trail of reassignment

### Accommodation Reassignment
1. Source: New AccommodationAssignment created, old one ended/cancelled
2. Derived: Overlap check on new assignment
3. Alert: ACCOMMODATION_OVERLAP if conflict
4. Auto: Create new assignment. Check overlap. NO auto-cancel old.
5. Manager: Must explicitly end old assignment if needed
6. No action: Both assignments may coexist (overlap alert)
7. Preserve: Both assignment records

### Sleeping-Place Conflict
1. Source: Two active assignments for same sleeping_place with overlapping dates
2. Derived: ACCOMMODATION_OVERLAP
3. Alert: ACCOMMODATION_OVERLAP — HIGH severity
4. Auto: Detect and alert only. NEVER silently remove an assignment.
5. Manager: Yes — must resolve (cancel one, adjust dates, or override)
6. No action: Alert persists. Both assignments remain.
7. Preserve: Both assignment records

### Early Departure
1. Source: Manager adjusts Person's outbound flight/transport to earlier date
2. Derived: Accommodation assignment may extend beyond departure
3. Alert: Informational — accommodation extends past departure
4. Auto: Alert only
5. Manager: May adjust accommodation
6. No action: Accommodation remains as-is
7. Preserve: All records

### Extended Stay
1. Source: Person staying longer than originally planned
2. Derived: May need additional accommodation nights
3. Alert: PERSON_WITHOUT_SLEEPING_PLACE for additional nights
4. Auto: Detect uncovered nights. Alert.
5. Manager: Must extend or create new accommodation assignment
6. No action: Alert persists for uncovered nights
7. Preserve: All records

### Same-Day Accommodation Turnover
1. Source: Person A end_date = Oct 3, Person B start_date = Oct 3, same sleeping place
2. Derived: No conflict (end_date exclusive). Valid turnover.
3. Alert: None — this is expected behavior
4. Auto: Allow without alert
5. Manager: No action needed
6. N/A
7. Preserve: Both assignments

### Missing Passenger Information
1. Source: Person record missing critical fields (passport, phone)
2. Derived: PERSON_MISSING_CRITICAL_INFO
3. Alert: MEDIUM severity, informational
4. Auto: Alert only
5. Manager: Should complete information before travel
6. No action: Alert persists. Operations continue.
7. Preserve: Partial record

### Incomplete Flight Information
1. Source: Flight missing departure/arrival times
2. Derived: Cannot calculate transport dependencies
3. Alert: FLIGHT_MISSING_INFO — MEDIUM
4. Auto: Alert only
5. Manager: Should complete flight details
6. No action: Alert persists. Transport linking degraded.
7. Preserve: Partial flight record

### Cash Payment
1. Source: Payment with method=CASH, potentially foreign currency
2. Derived: Balance calculation using recorded exchange rate
3. Alert: None unless balance-related
4. Auto: Record payment. Calculate base amount.
5. Manager: Enters exchange rate if foreign currency
6. N/A
7. Preserve: Original amount, currency, rate

### Multiple Currencies
1. Source: Expenses/payments in various currencies
2. Derived: All converted to base_currency using recorded rates
3. Alert: EXPENSE_WITHOUT_RATE if rate missing
4. Auto: Convert using recorded rate. Alert if rate missing.
5. Manager: Must provide exchange rates
6. No action: Amounts unconverted. Totals incomplete.
7. Preserve: All original amounts and currencies

### Manual Exchange Rate
1. Source: Manager enters exchange_rate, source=MANUAL
2. Derived: base_amount calculated using this rate
3. Alert: None
4. Auto: Calculate conversion
5. Manager: Provides rate
6. N/A
7. Preserve: Rate, source, timestamp

### Accidental Deletion
1. Source: is_deleted = TRUE on a record
2. Derived: Record hidden from active views. Relationships preserved.
3. Alert: None (deliberate action with confirmation)
4. Auto: Soft-delete only. Confirmation required before delete.
5. Manager: Confirmation before delete. Can restore.
6. N/A
7. Preserve: Full record, soft-deleted. Restorable.

### Application Restart During Operation
1. Source: App killed mid-operation
2. Derived: Depends on transaction state
3. Alert: None (system handles)
4. Auto: Database transactions ensure atomicity. Either committed or not.
5. Manager: May need to re-enter uncommitted data
6. N/A
7. Preserve: All committed transactions. Uncommitted discarded safely.

### Device Restart
Same as application restart. Database integrity maintained by PostgreSQL transaction semantics; local cache is refreshed after restart.

### Backup Interruption
1. Source: Backup file partially written
2. Derived: Invalid backup file
3. Alert: Backup failed notification
4. Auto: Mark backup as failed/incomplete
5. Manager: Should retry backup
6. No action: No valid backup exists for this attempt
7. Preserve: Current database unaffected

### Failed Restore
1. Source: Restore process fails at any step
2. Derived: Current database preserved
3. Alert: Restore failed notification with reason
4. Auto: Roll back to pre-restore state
5. Manager: Can retry or use different backup
6. No action: Current database intact
7. Preserve: Pre-restore backup exists

### Database Corruption
1. Source: Server integrity check fails
2. Derived: Data may be unreliable
3. Alert: Critical — database corruption detected
4. Operator detects server integrity failure, informs managers and initiates isolated recovery.
5. Operator: Restore only from a verified backup with approved recovery scope
6. No action: Application may be unstable. Repeated warnings.
7. Preserve: Retain server incident evidence and backups; never upload local cache as canonical state.

### Schema Migration Failure
1. Source: Migration script fails
2. Derived: App cannot operate with mismatched schema
3. Alert: Migration failed notification
4. Auto: Restore from pre-migration backup
5. Manager: Must update app or contact support
6. No action: App restored to pre-migration state
7. Preserve: Pre-migration backup, original database

### Poor/No Connectivity
Show timestamped cached state, disable mutations and reconcile automatically on reconnect.

### Multi-Manager Conflicting Edits
Reject stale versions, preserve entered text, reload canonical state and require an intentional retry.

## SECTION 36: Acceptance Criteria

Complete, testable end-to-end scenarios:

### AC-01: Accommodation Assignment & Overlap Detection
Preconditions: Event exists, Apartment with Room and SleepingPlace created, Person A and Person B exist.
1. Assign Person A to SleepingPlace S1, dates Oct 1-5 → SUCCESS
2. Assign Person B to SleepingPlace S1, dates Oct 3-8 → SUCCESS (assignment created)
3. System detects overlapping dates (Oct 3-5) → ACCOMMODATION_OVERLAP alert generated
4. Verify alert references both assignments, both persons, the sleeping place, and the overlapping dates
5. Manager cancels Person A's assignment effective Oct 3 (updates end_date to Oct 3) → Alert auto-resolves
6. Verify no active ACCOMMODATION_OVERLAP for S1 in this date range
7. Verify Person A now has PERSON_WITHOUT_SLEEPING_PLACE for Oct 3-5

### AC-02: Transport Capacity & Alert Resolution
1. Create Vehicle V1 with capacity=3
2. Create Trip T1 with Vehicle V1
3. Add Person A, B, C as TripPassengers → SUCCESS, no alert
4. Add Person D as TripPassenger → SUCCESS (passenger added)
5. System generates VEHICLE_OVER_CAPACITY for Trip T1 (4 > 3)
6. Verify all 4 passengers remain assigned (no silent removal)
7. Manager removes Person D from Trip T1 → Alert auto-resolves
8. Verify VEHICLE_OVER_CAPACITY cleared

### AC-03: Flight Change Impact on Transport
1. Create Flight F1 arriving 14:00
2. Create Trip T1 linked to F1, departing 15:00
3. Add passengers to both
4. Update F1 arrival to 18:00 (schedule change)
5. System generates FLIGHT_DELAY_IMPACT alert
6. Verify Trip T1 is UNCHANGED (still departing 15:00)
7. Alert clearly indicates the flight-transport misalignment
8. Manager updates Trip T1 departure to 19:00 → Manager's decision, alert resolves

### AC-04: Financial Record Integrity
1. Event base_currency = USD
2. Record Expense E1: 5,000 ILS, rate 3.5 ILS/USD, source=MANUAL
3. Verify: original_amount=5000, original_currency=ILS, exchange_rate=3.5, base_amount=1428.57 (5000/3.5)
4. Record Payment P1 from Person A: 500 USD
5. Verify: amount=500, currency=USD, base_amount=500
6. Verify only individual converted amounts and non-allocated event totals are shown; no participant balance is calculated
7. Change event base_currency → does NOT change stored exchange rates or original amounts
8. Lock Expense E1 (is_locked=TRUE) → base_amount preserved even if rate could be recalculated

### AC-05: Task Lifecycle & Overdue Detection
1. Create Task T1, due tomorrow, status=NEW
2. Advance authoritative test clock past due date
3. Open Control Center → OVERDUE_TASK alert for T1 appears
4. Open Today View → T1 appears in overdue section
5. Complete T1 (status=COMPLETED, completed_at_utc set)
6. Verify OVERDUE_TASK alert auto-resolves
7. Verify T1 no longer in Today overdue, no longer in Control Center alerts

### AC-06: Soft Delete & Restore
1. Create Person P1 with accommodation assignment and trip assignment
2. Soft-delete Person P1 (is_deleted=TRUE)
3. Verify P1 not visible in default person list
4. Verify P1's AccommodationAssignment and TripPassenger records still exist (not deleted)
5. Verify related alerts generated (orphaned assignments)
6. Restore Person P1 (is_deleted=FALSE)
7. Verify P1 visible again
8. Verify assignments still intact
9. Verify orphan alerts auto-resolve

### AC-07: Server Backup & Restore Safety
1. Operator creates a consistent backup of staging with representative data.
2. Restore a corrupted copy into an isolated recovery project; reject it.
3. Verify the canonical project is untouched.
4. Restore a valid backup to isolation; verify data, relationships and audit.
5. Only an explicit approved recovery action may replace canonical server state.

### AC-08: Offline resilience and realtime
1. Two distinct member accounts open the same event.
2. One commits a change; the other sees it without refresh.
3. Disconnect one device: cached data stays visible with offline warning; writes disabled.
4. Reconnect: missed changes reconcile automatically.
5. Submit stale version: reject, retain draft and show current record.
6. Anonymous/outsider reads return no event data.

### AC-09: Language Switching
1. Set interface language to Hebrew
2. Verify RTL layout throughout app
3. Enter person name in English: 'John Smith'
4. Enter hebrew_first_name: 'יוחנן'
5. Switch interface language to English
6. Verify LTR layout throughout app
7. Verify stored names unchanged: first_name='John Smith', hebrew_first_name='יוחנן'
8. Verify mixed-direction content displays correctly

### AC-10: Event Isolation
1. Create Event A and Event B
2. Create Person 'David Cohen' in Event A
3. Create Person 'David Cohen' in Event B (same name, different record)
4. Search 'David Cohen' in Event A → only Event A's David Cohen
5. Create Task in Event A → not visible in Event B
6. Create AccommodationAssignment in Event B → not visible in Event A
7. Verify Control Center shows only active event's data
8. Verify no cross-event relationship can be created

### AC-11: Data Migration
1. Create database with schema version N containing representative data
2. Deploy server migration N+1
3. Operator verifies pre-migration backup
4. Server migration executes transactionally, transforms schema
5. Verify all data preserved and accessible
6. Verify relationships intact
7. Verify schema version updated to N+1
8. (Failure scenario) Simulate migration failure → verify pre-migration backup restores successfully

### AC-12: Crash Recovery
1. Begin a multi-record operation (e.g., assign 5 people to a trip)
2. Simulate client disconnect during the server transaction
3. Restart application
4. Verify: all 5 assignments commit atomically or none do; client reconciliation discovers the result
5. Verify no partial/corrupted records
6. Verify database integrity check passes
7. Verify all existing data accessible

---

## SECTION 37: Requirement Traceability

Provide a compact traceability matrix connecting:
Requirement → Domain/Entity → Rule or Behavior → Acceptance Criterion

Format as a table:

| Req ID | Requirement | Domain | Entity/Entities | Rule/Behavior | Acceptance Criterion |
|---|---|---|---|---|---|
| REQ-001 | Manager sovereignty — no silent changes | All | All | All write operations require explicit manager action | AC-02, AC-03 |
| REQ-002 | Event isolation | Core | Event, All | Event-scoped queries, no cross-event leakage | AC-10 |
| REQ-003 | Offline operation | Architecture | All | Cached reads only offline; server-confirmed online writes | AC-08 |
| REQ-004 | Source data preservation | Data Integrity | All source entities | Original values never overwritten by derived values | AC-04 |
| REQ-005 | Accommodation overlap detection | Accommodation | AccommodationAssignment, SleepingPlace | ACCOMMODATION_OVERLAP rule | AC-01 |
| REQ-006 | Transport capacity enforcement | Transport | Trip, TripPassenger, Vehicle | VEHICLE_OVER_CAPACITY rule | AC-02 |
| REQ-007 | Flight changes don't alter transport | Flight/Transport | Flight, Trip | FLIGHT_DELAY_IMPACT advisory only | AC-03 |
| REQ-008 | Financial reproducibility | Finance | Expense, Payment | Original amounts + rates preserved | AC-04 |
| REQ-009 | Overdue task detection | Tasks | Task | OVERDUE_TASK rule | AC-05 |
| REQ-010 | Soft delete safety | Data Integrity | All deletable entities | is_deleted + restore capability | AC-06 |
| REQ-011 | Backup integrity | Recovery | Backup/Restore | Corrupted backup rejected, DB intact | AC-07 |
| REQ-012 | Bilingual support | UX | All UI | RTL/LTR switching, data preservation | AC-09 |
| REQ-013 | Data migration safety | Migration | Schema | Pre-migration backup, rollback on failure | AC-11 |
| REQ-014 | Crash recovery | Recovery | Database | Transaction atomicity, no partial state | AC-12 |
| REQ-015 | No silent data loss | Data Integrity | All | Destructive actions explicit, confirmations required | AC-06 |
| REQ-016 | Missing info ≠ negative fact | UX/Domain | Person, Flight, etc. | Null fields displayed as 'Not entered', not 'None' | AC-09 |
| REQ-017 | Manager overrides (is_locked) | All lockable | Expense, Payment, AccommodationAssignment, Trip, Flight | is_locked prevents auto-recalculation | AC-04 |
| REQ-018 | Idempotent rule evaluation | Rules Engine | UnresolvedItem | No duplicate active alerts | AC-01, AC-02 |
| REQ-019 | Deterministic derived state | Rules Engine | All derived | Same inputs → same outputs | AC-01-AC-12 |
| REQ-020 | UUIDv4 identities | Architecture | All persistent entities | Sync-ready identifiers | AC-10 |
| REQ-021 | UTC timestamps | Architecture | All temporal fields | No timezone ambiguity | AC-04, AC-05 |
| REQ-022 | Encrypted storage | Security | Database | AES-256 equivalent at rest | AC-08 |
| REQ-023 | Multi-currency support | Finance | Expense, Payment | Original currency preserved, base conversion tracked | AC-04 |
| REQ-024 | Accommodation date semantics | Accommodation | AccommodationAssignment | Start inclusive, end exclusive | AC-01 |
| REQ-025 | Person-SleepingPlace via assignment | Accommodation | SleepingPlace, AccommodationAssignment | No Bed.occupant_id | AC-01 |
| REQ-026 | Trip-Person via TripPassenger | Transport | Trip, TripPassenger | No Trip.person_id | AC-02 |
| REQ-027 | Driver-Vehicle not permanent | Transport | Driver, Vehicle, Trip | Driver assigned per-trip, not per-vehicle | AC-02 |
| REQ-028 | UnresolvedItem is derived | Rules Engine | UnresolvedItem | Auto-resolves when source condition clears | AC-01, AC-02, AC-05 |
| REQ-029 | Audit readiness | Audit | AuditEntry | Mandatory server-generated attributable change history | AC-06 |
| REQ-030 | Performance benchmarks | Performance | All | Measurable targets on benchmark dataset | Performance section |
| REQ-031 | Deterministic Alert Identity | Rules Engine | UnresolvedItem | SHA-256 canonical hash identity; idempotent evaluations | AC-01, AC-02 |
| REQ-032 | Scoped Rule Evaluation & Hybrid Scheduling | Rules Engine | DomainRule | Scoped queries; debounced/immediate hybrid scheduling | Performance section |
| REQ-033 | Future-proof Database Metadata | Architecture | Persistent entities | `deleted_at_utc`, `version`, `last_modified_by_device_id` added | AC-11 |
| REQ-034 | Secure Auth Session & Cache Storage | Security | SecurityKeyService, SecurityStorageService | Keystore/Keychain session and cache protection; no backend secrets in client | AC-08 |
| REQ-035 | Verified server recovery | Recovery | Backup/Restore | Operator-managed integrity checks and isolated restore; client cache cannot replace server | AC-07 |
| REQ-036 | External Sharing Snapshot PII Sanitization | UX / Sharing | Snapshot Exporter | Default PII masking ON; explicit unmasked export warning | AC-09 |
| REQ-037 | Centralized BIDI Text Isolation | UX | Presentation | `BidiTextFormatter` helper for mixed Hebrew/English strings | AC-09 |
| REQ-038 | Operational Alert Triage & Outdoor UX | Presentation | Control Center | Grouping, severity filters, direct action deep-links, high-contrast theme | AC-05 |

### Canonical Rule Test Coverage

Every active code in Section 18 requires a pure-domain positive, negative, deterministic-ID, and lifecycle test. The acceptance scenarios remain the end-to-end anchors: AC-01 (`ACCOMMODATION_OVERLAP`, sleeping-place coverage), AC-02 (`VEHICLE_OVER_CAPACITY`), AC-03 (`FLIGHT_DELAY_IMPACT`), AC-05 (`OVERDUE_TASK`), and AC-06 (orphan/restore impacts). The remaining active codes require focused domain tests before their feature phase completes; `UNPAID_BALANCE` is explicitly excluded because it is inactive pending OPD-002/003. `EVENT_LIFECYCLE_TRANSITION_NEEDED` must not emit automatically until its Product Owner criteria exist.

## SECTION 38: Definition of Done

The Master Specification is COMPLETE only when ALL of the following are true:

| # | Criterion | Status |
|---|---|---|
| 1 | MVP boundaries are explicit | ✅ Defined in Section 6 |
| 2 | Future features explicitly separated | ✅ Defined in Section 6, 28, 29 |
| 3 | Every major entity defined | ✅ Section 34 — 19 entities |
| 4 | Every relationship has defined cardinality | ✅ Section 34 |
| 5 | Event isolation defined | ✅ Sections 7, 34, AC-10 |
| 6 | Source and derived state separated | ✅ Section 5, 34 |
| 7 | Manager authority preserved | ✅ Section 5, all domain sections |
| 8 | Manager overrides defined | ✅ Section 5, 14, 16, 34 |
| 9 | Delete/archive/cancel/unassign/resolve/restore semantics | ✅ Section 24 |
| 10 | Individual financial conversions reproducible; allocation explicitly deferred | ✅ Section 16 |
| 11 | Accommodation date semantics defined | ✅ Section 14 |
| 12 | Transport passenger relationships defined | ✅ Section 13, 34 |
| 13 | Driver and vehicle relationships defined | ✅ Sections 11, 12, 13, 34 |
| 14 | Flight changes cannot silently rewrite transport | ✅ Sections 10, 13, 35 |
| 15 | Rules deterministic, scoped, idempotent | ✅ Section 18 |
| 16 | Unresolved item deduplication defined | ✅ Section 19 |
| 17 | Offline behavior defined | ✅ Section 27 |
| 18 | Crash recovery defined | ✅ Section 25, 35 |
| 19 | Backup/restore safety defined | ✅ Section 25, AC-07 |
| 20 | Migration safety defined | ✅ Section 32, AC-11 |
| 21 | Security outcomes defined | ✅ Section 26 |
| 22 | Realtime, version conflicts and reconnect reconciliation verified | ✅ Section 28 |
| 23 | Future permissions constraints defined (not implemented) | ✅ Section 29 |
| 24 | Performance targets measurable | ✅ Section 33 |
| 25 | Hebrew/English behavior defined | ✅ Section 22 |
| 26 | RTL/LTR behavior defined | ✅ Section 22 |
| 27 | Sharing behavior defined | ✅ Section 23 |
| 28 | Uman-specific edge cases covered | ✅ Section 35 |
| 29 | Acceptance tests cover critical workflows | ✅ Section 36 — 12 scenarios |
| 30 | Requirement traceability exists | ✅ Section 37 |
| 31 | No unresolved contradiction hidden | ✅ Section 40 |

## SECTION 39: Open Decisions & Explicitly Deferred Items

### Open Product Decisions

| ID | Decision | Impact | Interim MVP Behavior | Resolution Needed By |
|---|---|---|---|---|
| OPD-002 | Expense allocation model: equal split, custom per-person, or per-expense assignment | Balance calculation accuracy | No allocation, participant share, or `UNPAID_BALANCE` evaluation is implemented; only individual conversions and non-allocated event totals | Before financial feature completion |
| OPD-003 | Participant share calculation and final unpaid-balance semantics | Financial balance correctness | No formula or alert is implemented; `UNPAID_BALANCE` remains inactive | Before financial feature completion |

### Technical Decisions Finalized

Technical architecture is defined by v1.2 and ADR-001: Supabase/PostgreSQL, Auth, RLS, realtime, CAS versions, server audit and secure disposable cache.

### Explicitly Deferred MVP Features

| ID | Feature | Reason | Phase |
|---|---|---|---|
| DEF-004 | Advanced role editor | Initial event administrator role is enforced server-side | Phase 2 |
| DEF-005 | Rich merge comparison UI | Foundation preserves draft and requires intentional reopening | Phase 2 |
| DEF-006 | Meals / food management | Out of core scope | Phase 3+ |
| DEF-007 | Automated flight tracking API | MVP is manual/imported flight data | Phase 2 |
| DEF-008 | Automated exchange rate import | MVP uses manual rates | Phase 2 |
| DEF-009 | Push notifications | Record-level realtime is sufficient for the initial scope | Phase 2 |
| DEF-010 | App lock / biometric authentication | Defer to OS security | Phase 2 |
| DEF-011 | Comprehensive audit log viewer | Server auditing mandatory; advanced viewer deferred | Phase 2 |
| DEF-012 | Report generation (PDF) | Plain text snapshots in MVP | Phase 2 |
| DEF-013 | Global person directory | Event-scoped persons in MVP | Phase 2 |
| DEF-014 | Automated shopping / food purchasing | Out of scope | Phase 3+ |
| DEF-015 | Event templates | Nice-to-have, not MVP critical | Phase 2 |

## SECTION 40: Final Internal Consistency Audit

### Scope Audit
- ✅ Every feature classified as MVP, Future, or Open Decision
- ✅ No feature exists without classification
- ✅ Shared architectural constraints identified separately

### Entity Audit
- ✅ 19 entities defined with complete field lists
- ✅ All relationships reference valid entities
- ✅ All cardinalities logically coherent
- ✅ No circular dependencies
- ✅ Event ownership path defined for every entity

### Lifecycle Audit
- ✅ Create/edit/delete/archive/cancel/unassign/resolve/restore semantics defined (Section 24)
- ✅ No contradictions between lifecycle operations
- ✅ Soft delete preserves records
- ✅ Restore reverses soft delete

### Financial Audit
- ✅ Original transaction amounts preserved (Section 16)
- ✅ Derived base amounts clearly marked
- ✅ Exchange rates preserved with source and timestamp
- ✅ is_locked prevents auto-recalculation
- ✅ Original amounts and individual conversions are reproducible; allocation and unpaid balance are explicitly deferred (OPD-002/003)

### Accommodation Audit
- ✅ SleepingPlace and AccommodationAssignment are separate entities
- ✅ No Bed.occupant_id pattern
- ✅ Date semantics: start inclusive, end exclusive
- ✅ Same-day turnover explicitly handled
- ✅ Overlap detection defined

### Transport Audit
- ✅ Trip and TripPassenger are separate entities
- ✅ No Trip.person_id pattern
- ✅ Driver and Vehicle are separate entities
- ✅ No permanent Vehicle→Driver binding
- ✅ Capacity validation defined

### Flight Audit
- ✅ Flight changes generate alerts, NOT auto-changes to transport
- ✅ Flight is source data
- ✅ System is not an authoritative flight tracker

### Rules Audit
- ✅ Rules produce derived state only
- ✅ Rules are deterministic and idempotent
- ✅ Stable identity prevents duplicate alerts
- ✅ Auto-resolution when source condition clears

### Alert Audit
- ✅ UnresolvedItem is NOT source data
- ✅ Duplicate active alerts prevented by (rule_code, entity_type, entity_id, scope_key)
- ✅ Lifecycle: DETECTED → ACKNOWLEDGED → RESOLVED/DISMISSED

### Manager Authority Audit
- ✅ No automated process silently overrides manager decisions
- ✅ is_locked semantics defined
- ✅ All consequential changes require explicit manager action

### Cloud architecture audit
Historical offline audit superseded. Phase 1 status and evidence are tracked in PHASE1_PROGRESS.md; cloud and device tests are not presumed passed.

### Recovery Audit
- ✅ Crash recovery: transaction atomicity
- ✅ Backup: encrypted, integrity-checked
- Required: operator-controlled server restore, verified backup and failure safety
- ✅ Migration: pre-migration backup, failure recovery
- ✅ Corruption: detection and restore path

### Security Audit
- ✅ Encrypted storage at rest
- ✅ No PII in logs
- ✅ No telemetry in MVP
- ✅ No unnecessary network transmission
- Required: secure Auth sessions and platform-secure cached data

### Future Architecture Audit
- Required now: realtime invalidation and canonical reconciliation (Section 28)
- Required now: event membership, RLS and RPC authorization (Section 29)
- No CRDT, Event Sourcing or peer-to-peer synchronization
- ✅ UUIDv4, UTC timestamps, soft-delete, repository abstraction in place

### Performance Audit
- ✅ Benchmark dataset defined
- ✅ Measurable targets defined
- ✅ No requirement forces full-dataset processing
- ✅ Measurement methodology defined

### Bilingual Audit
- ✅ Hebrew RTL and English LTR defined
- ✅ Logical layout (Start/End) not hard-coded Left/Right
- ✅ Language change never alters source data
- ✅ Mixed-direction content handled

### Traceability Audit
- ✅ 38 requirements mapped to domains, entities, rules, and acceptance criteria; canonical rule coverage requirement added
- ✅ 12 acceptance test scenarios cover critical workflows
- ✅ No orphan requirements or rules identified

### Contradiction Check
- ✅ Pre-implementation freeze repairs applied: canonical fields, rule names, deterministic lifecycle, scoped evaluation, sharing boundary, finance deferral, and event-scoped rule configuration
- ✅ Only genuine Product Owner decisions remain open; no technical architecture decisions remain open

**AUDIT RESULT: Product requirements retained; cloud implementation verification is tracked separately in PHASE1_PROGRESS.md.**

# Visual Design System & Full UI Customization

## Objective

The application must not rely on arbitrary visual decisions made independently by developers or AI coding agents.

All visual characteristics of the application must be controlled through a centralized **Design System**.

The purpose of this architecture is to allow the product owner to continuously refine the visual appearance of the application without requiring major structural changes to individual screens.

The application UI must therefore be built from reusable design tokens and reusable components rather than hard-coded styling.

---

## 1. Core Principle

**No screen should define its own visual language.**

Individual screens may determine:

* which information is displayed
* the order of information
* which reusable components are used
* screen-specific layout requirements

However, screens should not independently invent:

* colors
* typography
* border radii
* shadows
* button styles
* card styles
* spacing
* icon sizes
* background colors
* field styling
* status colors
* elevation
* visual density

These values must come from the centralized Design System.

---

## 2. Design Tokens

The UI architecture must expose centralized design tokens.

### Colors

Examples:

* primary
* secondary
* accent
* background
* surface
* surfaceVariant
* textPrimary
* textSecondary
* textMuted
* border
* divider
* success
* warning
* error
* info
* selected
* disabled
* overlay

Additional domain-specific colors may exist for:

* payments
* flights
* transportation
* accommodation
* participants
* unresolved issues
* completed tasks

These colors must be configurable centrally.

No arbitrary hexadecimal colors should appear inside feature screens.

---

## 3. Typography

Typography must also be centralized.

The Design System must control:

* font family
* display font
* body font
* font sizes
* font weights
* line heights
* letter spacing

Semantic typography roles should include:

* displayLarge
* displayMedium
* pageTitle
* sectionTitle
* cardTitle
* bodyLarge
* bodyMedium
* bodySmall
* labelLarge
* labelMedium
* caption

Screens must reference these semantic styles rather than defining font sizes manually.

The system must fully support both:

* Hebrew
* English

Typography must be tested independently for RTL and LTR layouts.

---

## 4. Spacing System

All spacing should follow a defined spacing scale.

Example:

* XS
* S
* M
* L
* XL
* XXL

The exact numerical values must be defined centrally.

This includes:

* screen margins
* card padding
* list spacing
* section spacing
* button padding
* field spacing
* dialog padding

Developers and AI agents must not introduce arbitrary spacing values unless technically necessary.

---

## 5. Shape System

The Design System must centrally control:

* button corner radius
* card corner radius
* input field radius
* modal radius
* bottom sheet radius
* chip radius
* avatar radius

This allows the entire application to move between styles such as:

* sharp / professional
* soft / modern
* highly rounded
* minimal

without rebuilding individual screens.

---

## 6. Component Dimensions

Important UI dimensions should be centrally configurable.

Examples:

* standard button height
* compact button height
* large action button height
* text field height
* toolbar height
* navigation bar height
* card minimum height
* icon sizes
* avatar sizes
* list row height
* touch target sizes

The application must maintain accessible touch targets even if the visual style changes.

---

## 7. Reusable Component Library

The application should use a controlled component library.

Examples:

* PrimaryButton
* SecondaryButton
* DestructiveButton
* IconButton
* AppCard
* StatusCard
* SummaryCard
* PersonCard
* PaymentCard
* AppTextField
* SearchField
* AppDropdown
* FilterChip
* StatusBadge
* SectionHeader
* EmptyState
* ConfirmationDialog
* BottomSheet
* AppSnackbar

Feature screens should primarily be compositions of these components.

Changing a component in the Design System should update its appearance across the entire application.

---

## 8. Background System

Background styling must not be limited to a single flat color.

The design architecture should support interchangeable background strategies such as:

* solid color
* subtle gradient
* layered surfaces
* decorative background
* image-based background
* subtle texture
* section-specific surface colors

Decorative backgrounds must remain optional and must never reduce text readability.

---

## 9. Elevation and Shadows

Shadow behavior must be defined centrally.

The system should support styles such as:

* flat
* subtle elevation
* card elevation
* floating elements
* modal elevation

Shadow intensity, blur, spread and opacity should not be independently selected by individual screens.

---

## 10. Density

The interface should support configurable UI density.

Suggested modes:

### Comfortable

More whitespace and larger interaction areas.

### Standard

Balanced layout for normal usage.

### Compact

Higher information density for administrative screens and large tables/lists.

This is especially important because UMAN Event Manager contains information-heavy management screens.

---

## 11. Visual Themes

The architecture should allow multiple visual themes without changing feature code.

For example:

### Theme A — Warm Premium

Warm neutral backgrounds, restrained accent colors, elegant cards and generous spacing.

### Theme B — Professional Operations

Clean surfaces, higher information density and strong status visibility.

### Theme C — Minimal

Very limited decoration, flat surfaces and typography-driven hierarchy.

These themes do not necessarily need to be exposed to the end user in the MVP.

The purpose is architectural flexibility during product design.

---

## 12. Design Playground / UI Laboratory

A dedicated internal development screen should be created:

**Design Playground**

This screen should display all major reusable components simultaneously.

It should include examples of:

* buttons
* text fields
* cards
* badges
* chips
* dialogs
* typography
* colors
* icons
* lists
* participant cards
* payment statuses
* accommodation statuses
* warnings
* success states
* empty states

This allows the product owner to review the visual language without navigating through the entire application.

The Design Playground should become the primary environment for refining the application's appearance.

---

## 13. Design Token Preview

The Design Playground should also display:

* complete color palette
* typography hierarchy
* spacing scale
* corner radius scale
* icon scale
* elevation levels

This creates a visual reference for both humans and AI coding agents.

---

## 14. Hard-Coding Rule

The following values must not normally be hard-coded inside feature screens:

* colors
* font sizes
* font weights
* border radii
* shadows
* standard spacing
* standard component heights
* icon sizes

They must reference Design System values.

Exceptions should require a clear technical or UX reason.

---

## 15. AI Agent Design Rule

AI coding agents must not independently redesign the interface.

When implementing a screen, the agent must:

1. inspect the existing Design System
2. inspect existing reusable UI components
3. reuse existing patterns whenever possible
4. avoid inventing new colors or styles
5. avoid introducing new components when an equivalent already exists
6. preserve visual consistency across the application

If a new visual pattern is required, it must first be added to the shared component system.

---

## 16. Separation of Responsibilities

The architecture must distinguish between:

### Product Structure

What information and actions exist.

### UX Structure

How the user interacts with the information.

### Visual Design

How the interface visually appears.

AI agents may implement all three, but visual design decisions must be governed by the Design System rather than by arbitrary screen-level choices.

---

## 17. Iterative Visual Development

The expected design workflow is:

Product requirements
↓
Wireframe / screen structure
↓
Design System
↓
Design Playground
↓
Visual review
↓
Design token adjustment
↓
Reusable component refinement
↓
Feature screen implementation

This allows visual experimentation without destabilizing application logic.

---

## 18. Product Owner Control

The visual architecture should make it possible to request changes such as:

* “Make all buttons 10% taller.”
* “Reduce card rounding.”
* “Use warmer backgrounds.”
* “Increase Hebrew body text.”
* “Reduce shadows.”
* “Make management screens denser.”
* “Make warning states more visible.”
* “Make all cards flatter.”
* “Increase page margins.”
* “Change the primary color.”

These requests should normally require changes to a small number of centralized Design System definitions rather than modifications across dozens of screens.

---

## Acceptance Principle

A visual change that logically affects the entire application should normally be implementable in **one centralized location**.

If changing a global design property requires editing many feature screens individually, the UI architecture should be considered incorrectly implemented.

