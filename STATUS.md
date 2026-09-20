# UMAN EVENT MANAGER — PROJECT STATUS

**Last Reconciled:** 2026-09-20  
**Current Branch:** `main`  
**Latest Baseline Commit:** `0636eb4 docs: record deployed Event increment and outstanding acceptance gates`

---

## 1. Status Summary

| Category | Status | Details |
|---|---|---|
| **Multi-Agent Control System** | **VERIFIED** | `AGENT_ENTRYPOINT.md`, `MULTI_AGENT_PROTOCOL.md`, `ACTIVE_WORK.md`, `STATUS.md`, and task templates established in root. |
| **Event Domain Vertical Slice** | **VERIFIED (Local & Staging)** | Core Event domain, explicit lifecycle transitions (`PLANNING` to `CLOSEOUT`/`ARCHIVED`), details editor, capabilities, soft-delete/restore, Supabase Auth/RLS/CAS/Audit, 58 Flutter tests, 158 WASM DB checks pass. Deployed to Supabase staging `rrgzalzaaprdsmwihqxa`. |
| **People Domain Vertical Slice** | **IMPLEMENTED BUT UNVERIFIED (Uncommitted)** | Person entity, repository, controller, event shell integration, and migration `20260920063325_people_vertical_slice.sql` implemented in local working tree. Static analysis (0 issues), 58 Flutter tests, and 158 WASM checks pass locally. Uncommitted; migration not applied to remote staging. |
| **Two-Account / Conflict Acceptance Gate** | **BLOCKED / PENDING** | Requires multi-user concurrent testing, CAS conflict validation, and realtime reconnect verification on staging with two active accounts. |
| **iOS / Physical iPhone Gate** | **BLOCKED / PENDING** | iOS build, Keychain secure storage entitlement verification, and TestFlight validation require macOS host and physical iPhone device. |
| **Docker Local Reset Environment** | **BLOCKED / PENDING** | Local Docker environment absent on host; Docker reset scripts unverified. |
| **Logistics & Finance Domains** | **NOT STARTED** | Accommodations, Transport, Meals, Equipment, and Participant Balances deferred until Event/People gates pass. |

---

## 2. Detailed Breakdown by Component

### VERIFIED
- **Core Architecture Boundaries**: Pure-Dart domain entities (`Event`, `CivilDate`, `UuidValue`), controllers, repositories, isolated Supabase infrastructure layer.
- **Event Lifecycle & Persistence**: Event creation, detail page/editor, explicit state transitions (`PLANNING` → `SETUP` → `ACTIVE` → `IN_UMAN` → `DEPARTURE` → `CLOSEOUT`), `ARCHIVED` immutability, tombstone soft-delete and restore RPCs.
- **Authentication & Security**: Supabase password auth adapter, secure Keychain/keystore token storage, project/user-isolated read cache, 24h cache expiration, cache wipe on logout/access denial.
- **Database & Staging**: Applied migrations (`202609170001 cloud_foundation`, `20260919201737 event_management`, `20260919202929 event_currency_codes`). Remote RLS, CAS expected-version enforcement, and restricted SECURITY DEFINER RPC audit logging active on staging project `rrgzalzaaprdsmwihqxa`.
- **Local Testing**:
  - `flutter analyze --no-pub`: 0 issues
  - `flutter test --no-pub`: 58 tests passing
  - `node tools/db-test/verify.mjs`: 158 PostgreSQL/PGlite WASM checks passing
- **Single-Device Android Flow**: Auth sign-in, Event creation, editing, and realtime sync observed by owner on Samsung Android device (2026-09-19).

### IMPLEMENTED BUT UNVERIFIED
- **People Vertical Slice (Working Tree)**:
  - `Person` domain entity, repository contract, Supabase repository implementation, codec, and `PeopleController`.
  - UI: `EventShell` tabbed navigation, `PeopleListPage`, `PersonEditorPage`.
  - Migration `20260920063325_people_vertical_slice.sql` (creates `people` table, RLS policies, `create_person`, `update_person_cas` RPCs, audit integration).
  - Tests: `test/people_*_test.dart` and `tools/db-test/people-checks.mjs`.
  - *Verification Status*: All 58 Flutter unit/widget tests and 158 WASM checks pass locally, but the slice remains uncommitted in the working tree and undeployed on staging Supabase.

### IN PROGRESS
- **Multi-Agent Control System Initialization**: Reconciliation of git working tree, task ledger (`ACTIVE_WORK.md`), status ledger (`STATUS.md`), and entrypoint protocols.

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
