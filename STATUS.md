# UMAN EVENT MANAGER — PROJECT STATUS

**Last Reconciled:** 2026-09-20  
**Current Branch:** `main`  
**Latest Main Commit:** `4f0c7cb`

### Latest Codex continuation evidence (2026-09-20)

People implementation/deployment evidence is recorded in
[`docs/workcards/PEOPLE.md`](docs/workcards/PEOPLE.md). Earlier clean analysis,
58 Flutter tests, 158 PGlite checks and a configured Android APK build passed
before concurrent Flights edits. The latest combined checkout run is **not
green**: Flights fake-repository signature and passenger-fixture errors prevent
full-suite success; Flights lint notices also remain. Gemini owns that active
work; Codex did not modify it. Do not treat historical test counts below as a
fresh verification of the moving checkout.

Final scoped People run passed 19/19 controller/domain/SDK tests, including two
new authorization-race regressions. Follow-up `TASK-PEOPLE-VERIFY-02` is ready
for integration; its tests and evidence changes are uncommitted.

Corrections to summaries below: PLANNING → READY is still blocked pending
minimum setup; SETUP/ACTIVE are not Event lifecycle stages. People shell uses
drawer navigation. Actual People RPCs are `list_people`, `read_person`,
`person_duplicates`, `save_person`, and `set_person_deleted`.
Passport separation/redacted audit are implemented; the owner approved
preservation until an explicit removal policy exists. Two-session Realtime and
physical-device acceptance remain pending by owner direction, so integrated
People code is not a claim of full production acceptance.

---

## 1. Status Summary

| Category | Status | Details |
|---|---|---|
| **Multi-Agent Control System** | **VERIFIED** | `AGENT_ENTRYPOINT.md`, `MULTI_AGENT_PROTOCOL.md`, `ACTIVE_WORK.md`, `STATUS.md`, and task templates established in root and committed to `main`. |
| **Event Domain Vertical Slice** | **VERIFIED (Local & Staging)** | Core Event domain, explicit lifecycle transitions (`PLANNING` to `CLOSEOUT`/`ARCHIVED`), details editor, capabilities, soft-delete/restore, Supabase Auth/RLS/CAS/Audit, 58 Flutter tests, 158 WASM DB checks pass. Deployed to Supabase staging `rrgzalzaaprdsmwihqxa`. |
| **People Domain Vertical Slice (`TASK-PEOPLE-01`)** | **VERIFIED & INTEGRATED (`DONE`)** | Person entity, repository, controller, event shell integration, unit tests, and DB migration `20260920063325_people_vertical_slice.sql` reviewed, stabilized, and verified on local & remote staging. 58 Flutter tests, 158 WASM checks, and 17 remote staging DB checks passed. Merged into `main`. |
| **Flights Domain Vertical Slice (`TASK-FLT-01`)** | **ACTIVE (REVIEW/FIX)** | Flight and FlightPassenger entities, repositories, controller, UI pages, and DB migration `20260920090000_flights.sql`. 62 Flutter tests pass. Review identified defects in DB integrity and missing search logic. |
| **Two-Account / Conflict Acceptance Gate** | **BLOCKED / PENDING** | Requires multi-user concurrent testing, CAS conflict validation, and realtime reconnect verification on staging with two active accounts. |
| **iOS / Physical iPhone Gate** | **BLOCKED / PENDING** | iOS build, Keychain secure storage entitlement verification, and TestFlight validation require macOS host and physical iPhone device. |
| **Docker Local Reset Environment** | **BLOCKED / PENDING** | Local Docker environment absent on host; Docker reset scripts unverified. |
| **Logistics & Finance Domains** | **NOT STARTED** | Accommodations, Transport, Meals, Equipment, and Participant Balances deferred until Event/People gates pass. |

---

## 2. Detailed Breakdown by Component

### VERIFIED
- **Core Architecture Boundaries**: Pure-Dart domain entities (`Event`, `Person`, `CivilDate`, `UuidValue`), controllers, repositories, isolated Supabase infrastructure layer.
- **Event Lifecycle & Persistence**: Event creation, detail page/editor, explicit state transitions (`PLANNING` → `SETUP` → `ACTIVE` → `IN_UMAN` → `DEPARTURE` → `CLOSEOUT`), `ARCHIVED` immutability, tombstone soft-delete and restore RPCs.
- **People Vertical Slice (`TASK-PEOPLE-01`)**:
  - Domain & Codec: `Person` entity, `PersonInput`, `PersonSummary`, `PersonCodec`, `SupabasePeopleRepository`.
  - Application & Navigation: `PeopleController`, `EventShell` tabbed module navigation.
  - UI: `PeoplePage`, `PersonDetailsPage`, `PersonEditorPage`.
  - Staging Migration & DB: Migration `20260920063325_people_vertical_slice.sql` applied on staging project `rrgzalzaaprdsmwihqxa`. Passed all 17 remote RPC, RLS, CAS, search, audit, and isolation checks in `remote_people.sql`.
- **Authentication & Security**: Supabase password auth adapter, secure Keychain/keystore token storage, project/user-isolated read cache, 24h cache expiration, cache wipe on logout/access denial.
- **Database & Staging**: Applied migrations (`202609170001 cloud_foundation`, `20260919201737 event_management`, `20260919202929 event_currency_codes`, `20260920063325 people_vertical_slice`). Remote RLS, CAS expected-version enforcement, and restricted SECURITY DEFINER RPC audit logging active on staging project `rrgzalzaaprdsmwihqxa`.
- **Testing Verification**:
  - `flutter analyze --no-pub`: 0 issues
  - `flutter test --no-pub`: 58 tests passing
  - `node tools/db-test/verify.mjs`: 158 PostgreSQL/PGlite WASM checks passing
  - `npx supabase db query --linked -f supabase/tests/remote_people.sql`: 17 remote checks passing
- **Single-Device Android Flow**: Auth sign-in, Event creation, editing, and realtime sync observed by owner on Samsung Android device (2026-09-19).

### BLOCKED / EXTERNAL GATES
- **Two-Account Independent-Session Realtime Gate**: Needs concurrent pair-device or pair-session verification for state synchronization, stale update rejections, and websocket reconnects.
- **iOS / TestFlight Delivery Gate**: Windows development host cannot execute Xcode builds or Keychain entitlement checks on physical iPhones.
- **Docker Local Environment Gate**: Docker desktop is not installed on host machine.

### NOT STARTED
- **Logistics Entities**: Accommodations, Transport, Meals, Equipment allocation.
- **Finance & Participant Balances**: Deferred under OPD-002/003 (no automatic balance formulas or unapproved financial thresholds).
- **Passport Data Minimization & Retention**: Person entity passport field is currently nullable; full passport collection/retention/redaction workflows deferred.
- **Full Bilingual UI / RTL Layout**: Hebrew/English complete design system integration (`docs/DESIGN_SYSTEM.md`).

---

## 3. History of Reconciled Progress Documents

This document (`STATUS.md`) replaces `PHASE1_PROGRESS.md` as the primary project status ledger in accordance with `MULTI_AGENT_PROTOCOL.md` v1.1. `PHASE1_PROGRESS.md` remains preserved for historical reference.
