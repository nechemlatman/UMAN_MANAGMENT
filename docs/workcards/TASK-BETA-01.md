# TASK-BETA-01 — Usable Beta 0.1 Productization

**State:** IMPLEMENTED - REVIEW / OWNER ACCEPTANCE PENDING
**Operating mode:** Product Delivery Mode  
**Risk baseline:** Level 2 unless implementation discovers Level 3 changes

## Objective

Turn the already-implemented product into a coherent Android beta that the owner can use end-to-end and critique from real usage.

This is a **productization task**, not a new domain vertical slice.

## Existing domains to use

- Event/Auth
- People
- Flights + passengers
- Transport: Drivers, Vehicles, Trips + passengers
- Accommodation: Apartments, Rooms, Sleeping Places, Assignments

## Required outcome

The owner can open an event on a physical Android phone and move through the implemented modules without encountering misleading unfinished destinations in the normal path.

The existing capabilities should feel like one usable application rather than separate engineering slices.

## Scope

Inspect and improve only what is necessary for Beta 0.1:

- active-event navigation and module discoverability;
- hide/remove normal-path access to placeholder-only modules without deleting future enum/domain intent unnecessarily;
- coherent implemented-module entry points;
- obvious loading, empty and error states where current behavior is confusing;
- discoverability of already-supported create/edit/archive-or-delete/restore actions;
- contained UX corrections needed for a realistic walkthrough;
- RTL/LTR and phone-layout corrections exposed by this work;
- use the approved visual design system and existing shared presentation primitives.

## Out of scope

Do not implement:
- Tasks;
- Apartment Issues;
- Finance;
- Control Center business logic;
- Unresolved Items/rules engine;
- new major domain entities;
- speculative architecture;
- unrelated refactors;
- schema migrations unless a genuine Beta blocker is discovered and explicitly escalated.

Do not merge or revive unrelated historical UI branches automatically. Use current `main` as the baseline and reuse approved design-system rules/components intentionally.

## Architecture

Follow `AGENT_CONTEXT.md`.

Established architecture is not under review. Reuse existing patterns.

Preserve:
- event isolation;
- manager sovereignty;
- CAS/audit/security behavior;
- realtime/reconciliation;
- Logic / Structure / Visual Design separation.

## Product walkthrough acceptance

At minimum, the beta should support a realistic owner walkthrough such as:

1. sign in and select/open an event;
2. open People and inspect/create/edit a person using currently supported behavior;
3. open Flights and inspect/manage flight/passenger behavior currently implemented;
4. open Transport and reach Drivers, Vehicles and Trips;
5. open Accommodation and reach apartment/room/bed/assignment workflows;
6. navigate between these areas without dead placeholder destinations interrupting the normal flow;
7. return to event selection/settings through intentional navigation;
8. experience understandable empty/loading/error feedback for the paths touched.

Do not invent unsupported CRUD actions merely to satisfy this checklist. If an expected action is intentionally unsupported, make the current capability clear rather than fabricating behavior.

## Verification

Start at `TEST_MATRIX.md` Level 2.

Expected:
- format changed Dart;
- analyzer;
- targeted tests for changed navigation/presentation/controller behavior;
- relevant adjacent regressions;
- phone-sized RTL/LTR review for changed UI.

Escalate only if the actual diff crosses a Level 3 boundary.

Before owner handoff of Beta 0.1, run Level 4 milestone verification and produce a configured Android build.

## Completion evidence

A concise handoff should contain:
- changed user-visible behavior;
- files/areas materially changed;
- verification actually run;
- Android build result;
- any remaining Beta blocker;
- no long historical recap.

## Constraint

This workcard authorizes nothing by itself. Implementation begins only when the owner assigns it to an agent.

## Beta implementation handoff - 2026-09-30

Branch: `codex/beta-01-productization`, based on current main `f413741`.

- Events open in People. The drawer exposes People, Flights, Transport,
  Accommodation when configured, Event Settings, and Return to Events. Future
  module enum values remain intact but outside normal navigation.
- People/Flights controls scroll with results and dismiss the keyboard on drag.
  Driver/Vehicle tabs no longer show an accidental event-exit back button;
  final rows can scroll clear of the creation button.
- Flight details offer recovery after load failures and label icon actions.
  Flight/apartment search states distinguish no matches from no records.
  Short/empty Trip and Accommodation lists support pull-to-refresh.
- Presentation/structure only: no domain, schema, security, migration, or realtime
  changes. Existing forms and supported actions remain the baseline.

Executed local gate: changed-Dart formatter, diff checks, analyzer (clean), full
Flutter suite (156 passing), PostgreSQL WASM harness (599 passing), and configured
Android debug APK. Phone widget checks cover 360x640, RTL/LTR, light/dark, and
300px keyboard insets. Rendered fake-data screens were visually inspected using
local fonts; this is not Android runtime or Hebrew localization acceptance.

APK: `build/app/outputs/flutter-apk/app-debug.apk` (ignored local output).
CI: pending draft PR verification. No Android device was connected. Independent
milestone integration review, physical Android, two-user staging, and all iOS /
TestFlight gates remain unexecuted for this change.

Owner phone walkthrough: sign in, select event, People (create/edit/delete and
restore through the deleted filter), Flights (edit and passenger workflows),
Transport tabs (Trips, Drivers, Vehicles), Accommodation (apartment, expand room,
sleeping place, assignment; drafts under Drafts and unplaced records), Event
Settings, back to module, Return to Events. Check keyboard, mixed Hebrew/English
input, error/reconnect behavior and realistic record volumes. Use only the actions
shown; this beta adds neither unfinished domains nor full Hebrew interface copy.
