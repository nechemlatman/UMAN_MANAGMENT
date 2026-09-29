# TASK-TRN-02 — Pre-Build Gate (Trip + TripPassenger)

**Reviewer role:** Read-only architecture review (no code, migration, or workcard changes made outside this document).
**Date:** 2026-09-24
**Inspected state:** `main` branch, working tree as currently checked out on disk.

---

## 1. Gate Verdict

## NOT READY

Two independent, sufficient reasons:

1. `STATUS.md` and `ACTIVE_WORK.md` both currently record `TASK-TRN-01` as
   `CHANGES_REQUIRED` (reopened from `DONE` on 2026-09-22), with an explicit
   instruction: *"Do not start `TASK-TRN-02` until the workcard findings are
   resolved and re-verified."* This repository state has not changed — the
   five HIGH findings in `docs/workcards/TASK-TRN-01.md` are still present in
   the code as inspected (see §2).
2. No `docs/workcards/TASK-TRN-02.md` exists yet. There is no committed scope,
   acceptance criteria, or DB proposal for TASK-TRN-02 to gate against. This
   review evaluates repository readiness for that future slice against the
   spec and the TASK-TRN-01 precedent, not an actual workcard draft.


---

## 2. Blocking Findings

### B1 — TASK-TRN-01 audit findings are unresolved (carried forward, still verified in code)
Confirmed by direct inspection, not just documentation:
- `TransportRepository` (`lib/domain/repositories/transport_repository.dart`) has
  no `signals` stream and no `dispose()`, unlike `FlightsRepository`. The
  datasource (`SupabaseTransportDataSource`) does open realtime channels, but
  `DriversController`/`VehiclesController` never subscribe to them, never start
  the declared `_poll` timer, and always leave `realtimeConnected: false`.
  Compare with `FlightsController.start()`, which listens to
  `repository.signals`, drives `realtimeConnected`, and runs
  `Timer.periodic(pollInterval, ...)`.
- No restore path exists anywhere in the Transport stack: no `restore_driver`/
  `restore_vehicle` RPC in `20260920120000_drivers_and_vehicles.sql`, no
  `restore(...)` method on `TransportRepository`, no UI action. Flights and
  People both implement restore via a single `set_..._deleted(..., p_deleted)`
  RPC toggling `is_deleted`/`deleted_at_utc` and logging `RESTORE` in
  `audit_entries`.
- Error handling collapses everything to `CloudFailureKind.unknown` in
  `DriversController`/`VehiclesController`, and `SupabaseTransportRepository.
  readDriver/readVehicle` swallow all exceptions via `catch (_) { return null;
  }`, which is indistinguishable from a legitimate "not found". Flights uses
  the shared `CloudFailure`/`CloudFailureKind` (`unavailable`, `unauthorized`,
  `conflict`, `invalid`, `unknown`) end to end.
- Driver/Vehicle field sets still diverge from `UMAN_EVENT_MANAGER_SPEC_v2.6.md`
  §11–12: Driver is missing `whatsapp_phone` and uses `ACTIVE/INACTIVE` instead
  of the spec's `AVAILABLE/BUSY/UNAVAILABLE/OFF_DUTY`; Vehicle is missing
  `color` and the spec's `IN_USE` status.

**Why this blocks TRN-02:** Trip and TripPassenger are specified to hold a
live `driver_id`/`vehicle_id` and must reflect Driver/Vehicle availability in
real time for multi-user scheduling (ADR-001: "Realtime notifications
invalidate repository state ... Periodic reconciliation covers missed
events"). Building Trip realtime/reconciliation on top of a Transport layer
that does not yet participate in that contract either forces TRN-02 to fix
TRN-01's gap as undeclared scope, or ships Trip with the same silent-staleness
defect, multiplied across three tables instead of two.

### B2 — Flight and Person are not composite-FK-ready the way Driver/Vehicle are
`public.people` and `public.drivers`/`public.vehicles` all declare
`unique(event_id, id)`, and `people_private.person_details` demonstrates the
intended pattern: `foreign key(event_id, person_id) references
public.people(event_id, id)`. **`public.flights` has no such
`unique(event_id, id)` constraint**, and `public.flight_passengers` references
`flight_id`/`person_id` with plain single-column FKs
(`references public.flights(id)`, `references public.people(id)`) — not
composite FKs against `(event_id, id)`.

This means today's schema cannot prevent, at the database level, a
`flight_passengers` row whose `flight_id` or `person_id` belongs to a
*different* event than its own `event_id`. The only protection is the RPC's
`p_event_id` authorization check on the row being written, which does not
verify the referenced row's `event_id`.

`UMAN_EVENT_MANAGER_SPEC_v2.6.md` §7 states explicitly: *"Event Isolation
Rules: A Person, Trip, or Flight created in Event A cannot be referenced or
linked to from Event B."* Trip's spec fields include `related_flight_id`
(nullable FK to Flight) alongside `driver_id`/`vehicle_id`. If Trip copies the
Flights pattern for `related_flight_id`, it inherits the same unenforced
cross-event reference gap Flights already has — for the exact relationship
the spec calls out by name.

**Required before/alongside TRN-02 implementation:** either (a) add
`unique(event_id, id)` to `public.flights` (and confirm `public.people`
already has it, which it does) so Trip can use real composite FKs for
`driver_id`, `vehicle_id`, and `related_flight_id`, or (b) if composite FKs are
judged infeasible for `related_flight_id` in the time available, add an
explicit RPC-level cross-event check (`flight.event_id = p_event_id`) with a
regression test proving it, and record that as a deliberate, reviewed
deviation rather than a silent gap. Doing neither repeats a known-risky
pattern on a third table.

### B3 — No committed TASK-TRN-02 workcard
`AGENT_ENTRYPOINT.md` and `MULTI_AGENT_PROTOCOL.md` both require a Task Brief
(Objective/Scope/Out of Scope/Acceptance Criteria/Verification) to exist in
`ACTIVE_WORK.md` and `docs/workcards/` *before* implementation begins. Neither
exists for TRN-02 today. Until a workcard is drafted and reviewed, "readiness"
can only be assessed against the product spec, not against a concrete,
agreed implementation plan — increasing the chance of scope drift once
implementation starts.

---

## 3. Non-Blocking Risks

These do not need to block the start of implementation, but should be
resolved during TRN-02 rather than deferred again:

- **`Driver`/`Vehicle` entity field naming drift vs. spec.** Beyond the status
  enums (B1), field names differ cosmetically: implementation uses
  `licenseNumber` where the spec says `license_info`, and `name` where the
  spec says `name_or_identifier`. Low risk on its own, but worth reconciling
  in the same pass as the status-enum fix so Trip's UI/reporting layer is
  built against final field names once, not twice.
- **`Trip.version`/CAS field not explicitly listed in spec §13.** Every other
  entity (Event, Person, Flight, Driver, Vehicle) carries `version bigint` for
  optimistic concurrency per ADR-001 ("Every update uses an expected integer
  version"). The Trip/TripPassenger data model in §13 omits `version` from its
  field list (likely an oversight, since ADR-001 is unconditional). Confirm in
  the TRN-02 workcard that Trip and TripPassenger both carry `version`,
  `is_deleted`/`deleted_at_utc`, `created_by`/`updated_by`, matching the
  pattern used everywhere else — do not treat the spec's field list as
  literal-complete for infrastructure columns.
- **Composite `unique` on `drivers`/`vehicles` is currently unused.** The
  `unique(event_id, id)` constraints exist and were explicitly built "for
  future Trip FKs" per `STATUS.md`, but no other table references them yet.
  TRN-02 is the first consumer; confirm the FK syntax
  (`foreign key(event_id, driver_id) references public.drivers(event_id, id)`)
  is exercised in a migration test before relying on it in application code.
- **`transport_private`, `flights_private`, `people_private` authorize
  functions are near-duplicates.** Each vertical slice has re-implemented the
  same membership/event-state check. Not a blocker, but a `trip` slice adding
  a fourth near-identical copy is a maintainability smell worth flagging (not
  worth a refactor mid-slice per MULTI_AGENT_PROTOCOL §6's scope discipline).
- **`readDriver`/`readVehicle` return `null` on any RPC error**, including
  genuine authorization or connectivity failures, which several call sites
  (e.g. `DriversController.refresh()`) treat as "record not found" and clear
  the selection silently. This is a pre-existing UX correctness issue, not
  just an internal classification gap; worth confirming it doesn't propagate
  into Trip's read paths when Trip reads a linked Driver/Vehicle/Flight.

---

## 4. Confirmed Dependencies (solid — do not redesign)

- **Event/CAS/audit foundation** (`202609170001_cloud_foundation.sql`):
  `events`, `event_members` (single `administrator` role), `audit_entries`,
  `is_event_admin()`, and the `audit_material_change()` trigger are stable,
  used identically by every subsequent slice, and require no changes for
  Trip. Trip should use RPC-level `insert into audit_entries(...)` calls in
  the same style as `save_driver`/`save_vehicle`/`save_flight`, not the
  trigger (which is wired only to `events`/`event_members`).
- **`(event_id, id)` composite uniqueness pattern** on `people` and
  `drivers`/`vehicles` is real and correctly built — Trip can safely
  composite-FK against Driver, Vehicle, and Person today.
- **CAS versioning and creation-idempotency pattern** (`creation_request_id`
  unique + `pg_advisory_xact_lock` + expected-version check on update) is
  consistent across `events`, `people`, `flights`, `drivers`, `vehicles`, and
  is safe to reuse verbatim for `trips` and `trip_passengers`.
- **RLS + SECURITY DEFINER RPC pattern**: no client DML policies anywhere;
  all mutation goes through narrowly-scoped RPCs with a private `authorize()`
  helper per module. This is consistent and should be followed for
  `transport_private`-style Trip functions (or reuse `transport_private` if
  Trip is scoped as part of the Transport module rather than its own).
- **Flights realtime/reconciliation/disposal pattern**
  (`FlightsController`/`FlightsRepository`) is the correct reference
  implementation — it, not the current Transport controllers, is what Trip's
  controller should be modeled on.
- **Soft-delete/restore RPC shape**: `set_flight_deleted`/`set_person_deleted`
  (single RPC, boolean `p_deleted` parameter, `DELETE`/`RESTORE` audit
  operation) is a proven, working pattern Trip/TripPassenger should copy
  directly rather than the delete-only pattern currently in Transport.

---

## 5. Required Product Decisions

Classified per the review brief's taxonomy:

| # | Question | Classification |
|---|---|---|
| 1 | Driver/Vehicle status enums and missing fields (`whatsapp_phone`, `color`, `IN_USE`) — implement spec v2.6 as written, or ratify the current simplified enums as an approved deviation? | **BLOCKING DECISION** — Trip's UI will surface Driver/Vehicle status; building against a value set that may be replaced under TRN-02's own review is wasted work either way. |
| 2 | Should `related_flight_id` use a real composite FK (requiring a `flights` migration to add `unique(event_id, id)`), or an RPC-level cross-event check? | **BLOCKING DECISION** — see B2. Affects the TRN-02 migration's shape from the first line. |
| 3 | Trip status transitions (`PLANNED → CONFIRMED → IN_PROGRESS → COMPLETED → CANCELLED`) — are all transitions freely reversible, or are some one-way (e.g. `COMPLETED`/`CANCELLED` terminal)? Spec §13 lists the enum but not a transition table (unlike Event's explicit table in §7). | **BLOCKING DECISION** — needed before `save_trip`/a dedicated transition RPC can validate transitions server-side. |
| 4 | "Active passenger" definition for capacity counting — does `CANCELLED`/`NO_SHOW` count against capacity, or only `ASSIGNED/CONFIRMED/PICKED_UP`? | **SAFE DEFAULT ALREADY DEFINED** — spec §13 says capacity validation counts "active passengers" and is violated only when `passenger_count > capacity`; the natural reading is CANCELLED/NO_SHOW are excluded, matching how `is_deleted` rows are already excluded elsewhere. Should be written down explicitly in the TRN-02 workcard, but does not need new manager input. |
| 5 | Duplicate passenger assignment (same person on same trip twice) | **IMPLEMENTATION DETAIL — DO NOT ESCALATE** — follow the existing `unique(flight_id, person_id)` precedent from `flight_passengers`; add `unique(trip_id, person_id)` (or scoped by non-deleted rows, matching whatever the flights precedent actually enforces at the DB level — confirm at implementation time, since a plain `unique(flight_id, person_id)` with soft-delete rows would block re-adding a person after their assignment was cancelled; this needs a partial unique index or equivalent, not a product decision). |
| 6 | Behavior when linked Driver/Vehicle becomes unavailable/deleted mid-trip | **SAFE DEFAULT ALREADY DEFINED** — spec §13 "Driver/Vehicle Replacement" already specifies preserving historical context via audit log and letting the new assignment become live source data; no silent auto-unassignment is implied. |
| 7 | Behavior when linked Flight is deleted/cancelled | **SAFE DEFAULT ALREADY DEFINED** — spec §13 "Flight-Transport Linkage" is explicit: advisories only, never automatic trip mutation. |
| 8 | `is_locked` semantics for Trip | **IMPLEMENTATION DETAIL — DO NOT ESCALATE** — Flight already has `is_locked` with no documented server-side enforcement found in `save_flight` (it is stored and returned but not read back to block mutation in the RPC as inspected). Trip should either enforce it consistently with Flight's actual behavior (permissive) or, if stricter enforcement is wanted for Trip, that upgrade should be flagged as a explicit, reviewed choice rather than assumed. |
| 9 | Whether cancelled passengers count toward capacity | Duplicate of #4 above — **SAFE DEFAULT ALREADY DEFINED**. |
| 10 | Restore interactions for Trip/TripPassenger | **IMPLEMENTATION DETAIL — DO NOT ESCALATE**, contingent on B1 being fixed first — copy the `set_flight_deleted`-style single-RPC restore pattern; do not repeat Transport's delete-only gap on a third module. |

---

## 6. Implementation Constraints (Codex must preserve)

1. Do not introduce a second realtime/reconciliation pattern. `Trip`'s
   controller must subscribe to a `signals` stream and run a periodic
   reconciliation timer exactly as `FlightsController` does; if Transport's
   `TransportRepository` is fixed as part of unblocking B1, Trip should share
   that fixed interface rather than a bespoke one.
2. Do not use plain single-column FKs for any Trip reference into an
   event-scoped table (Driver, Vehicle, Person, Flight) without either a
   composite `(event_id, id)` FK or an explicit, tested RPC-level event-match
   check. Silent cross-event linkage is an explicit spec violation (§7), not
   just a style preference.
3. Every Trip/TripPassenger mutation RPC must follow the established shape:
   `creation_request_id` idempotency + advisory lock on create, expected-
   version check on update, `audit_entries` insert in the same transaction,
   single `set_..._deleted(p_deleted)` RPC for both delete and restore.
4. Do not auto-mutate Trip schedule/assignments from Flight status changes;
   generate advisories only, per spec §13.
5. Capacity validation is `passenger_count > capacity` (strictly greater);
   exactly-at-capacity is valid and must not be blocked.
6. Preserve historical assignment context on Driver/Vehicle reassignment via
   the audit log (`old_value`/`new_value` on the `trips` row), not a separate
   history table, consistent with how every other slice records change
   history today.
7. Keep Logic/Structure/Visual Design boundaries intact per
   `MULTI_AGENT_PROTOCOL.md` §9 — no ad-hoc `Colors.*` literals or hardcoded
   text styles in new Trip presentation code (this was a real defect in
   TRN-01 that was separately corrected; do not reintroduce it).
8. Do not touch `STATUS.md`, `ACTIVE_WORK.md`, existing workcards, production
   Dart code, or existing migrations as part of resolving this gate review
   itself — those changes belong to the implementation task once scoped.

---

## 7. Minimum Verification Matrix

| Area | Required test(s) before TRN-02 can be considered complete |
|---|---|
| Cross-event integrity | Attempt to create a Trip/TripPassenger referencing a Driver, Vehicle, Person, or Flight from a *different* event; must fail (DB constraint or RPC check), not merely be discouraged by UI. |
| CAS / stale writes | Concurrent update from two sessions with the same `expected_version`; second write must fail with the conflict error path, not silently overwrite. |
| Concurrent passenger edits | Two sessions add/edit `TripPassenger` rows for the same Trip concurrently; verify no duplicate-active-passenger state and no capacity miscount. |
| Capacity threshold | Assign passengers up to exactly `vehicle.capacity` → must succeed; one more → must be flagged as over-capacity without being silently blocked or auto-trimmed. |
| Linked Flight change isolation | Mark a linked Flight `DELAYED`/`CANCELLED`; assert the Trip row's own schedule/assignment fields are unchanged and an advisory is recorded. |
| Realtime invalidation | Mutate a Trip from session A; session B's `TripsController` must reflect the change without a manual refresh, mirroring the Flights realtime test coverage. |
| Reconnect reconciliation | Simulate a dropped/reconnected realtime channel; verify the periodic reconciliation timer (not just the channel) brings state current, matching `FlightsController`'s poll-timer behavior. |
| Unauthorized access | Non-member (or revoked member) attempts any Trip RPC; must fail with the RLS/authorize `42501` path, not a generic error. |
| Delete/restore/history | Soft-delete a Trip, restore it, and confirm both `DELETE` and `RESTORE` audit entries exist with correct before/after payloads — this is a new capability relative to Transport's current delete-only state and must be explicitly tested, not assumed. |
| Regression: Transport's own gate | Re-run/extend `tools/db-test/transport-checks.mjs` to prove B1's realtime/restore/classification fixes (if bundled into TRN-02's dependencies) before layering Trip on top. |

Existing coverage today (`test/domain/transport_test.dart`) is limited to pure
domain-entity unit tests (enum parsing, `toJson`, `copyWith`) — no
controller, repository, or DB-level tests exist yet for realtime, restore, or
conflict handling in Transport. TRN-02 should not assume this gap is someone
else's problem if TRN-02 depends on the same repository.

---

## 8. Final Recommendation

Codex may begin `TASK-TRN-02` implementation only after, in this order:

1. A `docs/workcards/TASK-TRN-02.md` Task Brief is drafted and reviewed
   (Objective/Scope/Out of Scope/Acceptance Criteria/Verification), resolving
   Required Product Decisions #1–#3 above explicitly in writing.
2. TASK-TRN-01's five HIGH findings (`docs/workcards/TASK-TRN-01.md`) are
   either fixed and re-verified, or the TRN-02 workcard explicitly absorbs
   fixing the shared `TransportRepository`/`DriversController`/
   `VehiclesController` realtime, restore, and error-classification gaps as
   in-scope prerequisite work before Trip is layered on top. Shipping Trip on
   the current Transport foundation as-is would mean building a third
   consumer of a contract two existing consumers (Drivers, Vehicles) already
   fail to satisfy.
3. The Flight composite-FK gap (B2) is resolved one of the two ways described
   in §2, with the choice recorded in the TRN-02 workcard rather than decided
   silently inside a migration file.

Once those three conditions are met, the confirmed dependencies in §4 (event
foundation, CAS/audit pattern, RLS/RPC pattern, composite-unique readiness on
Driver/Vehicle/Person, and the Flights realtime reference implementation) are
solid enough that `TASK-TRN-02` implementation should proceed without further
architectural discovery work.
