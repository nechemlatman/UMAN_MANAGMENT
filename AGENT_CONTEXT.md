# UMAN EVENT MANAGER — AGENT CONTEXT

**Operating mode:** Product Delivery Mode  
**Updated:** 2026-09-29

## Mission

Deliver a usable, reliable mobile event-management product quickly enough for the owner to use it, critique it, and iterate from real usage.

Progress is measured primarily by **new usable capability on the phone**, not documentation volume or repeated re-validation of settled architecture. Quality remains mandatory; the process is becoming leaner, not less rigorous.

## Current verified baseline

Implemented and integrated on `main`:
- Event/Auth foundation
- People
- Flights + passengers
- Drivers + Vehicles
- Ground Transport Trips + passengers
- Accommodation: Apartments → Rooms → Sleeping Places → Assignments

Cloud foundation:
- Flutter mobile client
- Supabase/PostgreSQL canonical data
- authenticated multi-user access
- event-scoped RLS/authorization
- server-side mutation RPCs, CAS/version checks and audit
- realtime invalidation + reconciliation

Visible but not yet implemented as product modules:
- Control Center / Dashboard
- Tasks
- Apartment Issues
- Finance
- Unresolved Items

## Settled architecture — use, do not reopen

Unless the assigned task exposes a real blocker, follow existing patterns rather than redesigning them.

- PostgreSQL/Supabase is canonical.
- Cloud-first, multi-user, server-authoritative.
- Every record/query/action is scoped to one event.
- Manager-entered source data is never silently changed.
- Concurrent writes use established version/CAS patterns.
- RLS controls reads; restricted server RPCs authorize writes.
- Realtime triggers reconciliation; it does not replace authorization or canonical reloads.
- Domain stays pure Dart; Supabase implementation stays in infrastructure/composition.
- Preserve Logic / Structure / Visual Design separation.
- Android and iOS remain required targets.
- Never expose secrets or sensitive values.

For normal work, copy the nearest established implementation pattern before inventing a new abstraction.

## Change-friendly rules

- Prefer small, modular changes.
- Keep business rules out of widgets.
- Keep styling centralized.
- Reuse shared controls/components.
- Save protects minimum identity/integrity; operational actions validate operational completeness.
- Unknown data stays unknown/null; never invent values.
- Add persistence only when the product requirement needs persisted state.
- Do not perform unrelated refactors or cleanup.

## Mandatory reading before a normal task

Read only:
1. this file;
2. `ACTIVE_WORK.md`;
3. the assigned task instruction/workcard;
4. the relevant implementation files and tests.

Then start.

Read extra documents only when the task touches their subject:
- product/domain ambiguity → `UMAN_EVENT_MANAGER_SPEC_v2.6.md`
- Supabase/realtime/security/shared architecture → `UMAN_EVENT_MANAGER_TECH_SPEC_v1.2.md` and ADR
- visual implementation → `UMAN_EVENT_MANAGER_VISUAL_DESIGN_SYSTEM.md`
- release/cross-platform gate → `CROSS_PLATFORM_DELIVERY.md`
- multi-agent collision/takeover → `MULTI_AGENT_PROTOCOL.md`

Do not reread the whole repository or all specifications merely because a new task started.

## Work discipline

Before editing:
- inspect current branch/status;
- confirm no active overlap in `ACTIVE_WORK.md`;
- inspect the files actually being changed.

During implementation:
- stay inside scope;
- preserve existing architecture;
- keep diffs focused;
- avoid unrelated code, migration or documentation changes.

After implementation:
- verify according to `TEST_MATRIX.md`;
- record only material state changes;
- leave the repository recoverable.

## Independent review

Use risk-based review, not automatic review for every task.

Normally review independently when changing schema/migrations, RLS/Auth/security, shared realtime/synchronization, broad shared architecture, destructive data behavior, or milestone/release integration.

Contained UI/UX and low-risk changes that follow an established pattern normally require targeted verification and clean self-review, not a separate inspector.

## Current priority

The next milestone is **Usable Beta 0.1**: make the already-implemented People, Flights, Transport and Accommodation modules coherent and usable on a physical Android phone before another large domain slice.

See `PRODUCT_DELIVERY_MODE.md` and `TEST_MATRIX.md`.
