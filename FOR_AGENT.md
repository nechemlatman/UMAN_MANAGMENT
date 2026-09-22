# UMAN EVENT MANAGER — Agent instructions

## Mandatory Reading Order

Before making any changes, every agent must read in this order:

1. `STATUS.md`
2. `AGENT_ENTRYPOINT.md`
3. `MULTI_AGENT_PROTOCOL.md`
4. `ACTIVE_WORK.md`
5. The assigned Task Brief (under `docs/workcards/`)
6. Relevant authoritative specifications: Master `UMAN_EVENT_MANAGER_SPEC_v2.6.md`, Technical `UMAN_EVENT_MANAGER_TECH_SPEC_v1.2.md`, `ADR-001-CLOUD-FIRST-REALTIME-MULTIUSER.md`, and `CROSS_PLATFORM_DELIVERY.md`.
7. Current Git state, relevant implementation, migrations, tests, and recent commits.

*Note:* `STATUS.md` and `ACTIVE_WORK.md` supersede `PHASE1_PROGRESS.md` as the active status and coordination ledger. `PHASE1_PROGRESS.md` is preserved as historical progress evidence only and is not an active status ledger. Older specs are archived under `docs/history/`, never implementation authority.

Use `docs/PRODUCT_COMPASS_AND_BUILD_WORKBOOK.md` for the owner's vision, coverage map, work-card template, and additional acceptance scenarios. It is a supplement: unresolved product choices are not implicitly approved by a proposal.
Active visual authority: `UMAN_EVENT_MANAGER_VISUAL_DESIGN_SYSTEM.md` — the sole visual-design authority. Implementation tokens live in `lib/presentation/design_system.dart`.

## Non-negotiable architecture

- Supabase PostgreSQL is the canonical source of truth. The app is cloud-first, server-authoritative and multi-user, with local read resilience.
- Yonatan and Yosef use separate Auth accounts and explicit event memberships. Authentication, server authorization and actor attribution are mandatory.
- Every write may race with another administrator. Expected integer versions must reject stale updates. Never silently use last-write-wins on important data.
- Realtime changes can arrive anytime. Preserve drafts/navigation; reconcile after login, subscription/reconnect, foreground, writes and conflicts. Notifications are not a replacement for PostgreSQL integrity or missed-event recovery.
- RLS scopes reads; restricted transactional RPCs authorize and validate writes. Client validation alone is insufficient. Audit entries are generated server-side.
- Integrity-sensitive multi-row operations are atomic. Locks/constraints must preserve product semantics: capacity/overlap alerts and deliberate manager overrides must not become accidental blanket prohibitions.
- Local storage is disposable, user/project-scoped cache, never another master. Offline reads show age; writes require server connectivity and confirmation. No offline write queue, silent merging or peer-to-peer sync.
- No service-role key, password, passport data, raw exception or token in source, UI errors or logs. Client config contains only HTTPS URL and publishable key.
- Domain stays pure Dart. Presentation uses controllers/repositories; Supabase SDK lives in infrastructure and the composition root, never feature widgets.
- Android and iOS are mandatory. Windows cannot certify Xcode/iPhone behavior.

## Cross-Platform Delivery & Verification Gates

- Mandatory targets: Android and iOS. Windows/Android daily development does not imply an Android-only product.
- iOS compatibility gate requires macOS and a real iPhone before production handoff:
  - Validate iOS 13 minimum and entitlements (Keychain secure storage via `flutter_secure_storage`).
  - Confirm sign-in, token refresh, session restore on force-close/relaunch, logout, cache erasure, account switching, and keychain accessibility while locked.
  - Test two accounts on Android/iPhone: realtime updates, stale edit rejection, websocket/network reconnect, and foreground reconciliation.
  - Verify offline restart/read-only cache, expiry and revocation behavior.
  - Verify Hebrew RTL/English LTR, mixed-direction text, SafeArea, keyboard, gestures, scrolling, text scaling, screen reader, and 48dp touch targets.
  - Validate signing/archive, install through TestFlight, and obtain event-manager acceptance on a physical iPhone.
- Release path: Local tests → Android build/device → fresh Supabase staging deployment → two-user acceptance → macOS/Xcode → physical iPhone → TestFlight → manager acceptance.

## Foundation scope and preserved semantics

Phase 1 is **Authenticated Cloud Persistence & Realtime Foundation**. Verify the Event slice before bulk business implementation. Initial Event and memberships are operator provisioned. Additional members remain an operator action. Explicit field editing, archive and soft-delete/restore RPCs/UI are now implemented; see docs/workcards/EVENT_MANAGEMENT.md for remaining decisions and acceptance.
PLANNING → READY is blocked until minimum setup is defined. Never reopen an ARCHIVED Event operationally. Person is next only after the Event gate.

Preserve all 19 domain entities and business rules. UUIDv4 for source records; UnresolvedItem uses SHA256(ruleCode|entityType|entityId|scopeKey), sorted pair IDs. Keep acknowledgments and first detection timestamps. Rules do not mutate source facts. Person.passport_expiration_date remains nullable; Driver is separate; SleepingPlace has no occupant_id; accommodation intervals are [start,end). Use ACCOMMODATION_OVERLAP, not aliases. Exactly-at-capacity is valid.
OPD-002/003 remain open: no invented allocation, participant share, final balance or UNPAID_BALANCE evaluation. No invented automatic lifecycle thresholds.

## Validation and handoff

Run `flutter analyze`, `flutter test`, `node tools/db-test/verify.mjs` and Android build for applicable changes. The PostgreSQL harness emulates Auth roles, not Supabase service behavior or simultaneous sessions. External acceptance steps are in supabase/README.md. Never claim cloud deployment, two-device realtime or real iPhone validation without execution evidence. Update `STATUS.md` and `ACTIVE_WORK.md` before handoff.

Historical local Drift code/tests are preserved as .dart.txt under `docs/history/local-foundation/`; they are not active imports or canonical stores. Existing KDF utilities remain inactive reusable infrastructure. Do not reconnect legacy local save/upsert methods to the production cloud repository.
