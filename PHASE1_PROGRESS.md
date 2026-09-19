# Phase 1 — Authenticated Cloud Persistence & Realtime Foundation

Updated: 2026-09-18. Status: **Local foundation implemented and tested; external
cloud/device acceptance pending.** Do not mark the architecture migration fully
accepted before the two-account cloud and iPhone gates pass.

Authority: Master v2.6, Technical v1.2, ADR-001 and CROSS_PLATFORM_DELIVERY.md.

## Completed

- Reconciled current specifications and sectional copies with cloud-first,
  server-authoritative, realtime multi-user architecture. Older versions are archived under docs/history; only the current root versions
  are authoritative.
- Preserved business semantics, all 19 entity definitions and finance deferrals.
  Reviewed event scoping, metadata, composite FKs, indexes and transactional
  operations for later entity implementation in Technical v1.2.
- Supabase migration: events, event_members, audit_entries, RLS, grants, indexes,
  constraints, restricted create/rename RPCs and Realtime publication.
- Event creation + creator membership + audit are one transaction. Creation retry
  uses a unique request UUID; changed retry payload or revoked membership fails.
- Expected-version updates reject stale writes. Audit captures authenticated actor,
  before/after snapshots and operation; application roles cannot alter the log.
- Supabase Auth adapter: password login, restoration through secure session
  storage, local logout, project-scoped session keys and safe failures.
- Pure-Dart repository contracts; Supabase implementation isolated from widgets.
- Cubit/controller and provisional Event UI: create/read/rename, Saving/Synced/
  Offline/Failed/Conflict, retained draft on conflict and deliberate reopen flow.
- Realtime invalidation, subscribe/reconnect refresh, foreground reconciliation,
  serialized refreshes and 20-second recovery polling. Disposal stops late writes.
- User/project-scoped secure Event cache, 24-hour expiry, offline reads only,
  clearing on logout and access rejection. Cache failure does not block server
  loading; future-dated/expired snapshots are never shown as valid.
- Public client configuration example, ignore rules, setup/provision template and
  external acceptance runbook. No real credentials or backend keys were added.
- Android INTERNET permission and disabled app backup. iOS 13-compatible resolved
  dependencies and Keychain entitlement references reviewed statically.

## Validation executed

| Check | Result |
|---|---|
| flutter analyze --no-pub | PASS — no issues |
| flutter test --no-pub | PASS — 31 tests |
| node tools/db-test/verify.mjs | PASS — 41 PostgreSQL checks |
| flutter build apk --debug | PASS — final rebuild completed, exit 0, 24.8 seconds |
| Supabase deployed Auth/REST/Realtime integration | NOT RUN — no project configured |
| Two independent DB sessions racing / two phones | NOT RUN |
| Android physical-device runtime | NOT RUN |
| Xcode build / real iPhone / TestFlight | NOT RUN — Windows host |

Flutter tests cover domain invariants, architecture boundaries, offline/read cache,
realtime invalidation, reconnect, concurrent draft conflict, server acknowledgment,
refresh coalescing, expiry, account/project isolation, logout, secure session storage
and retained reusable KDF utilities. PostgreSQL tests run the complete migration
in PGlite with emulated Supabase roles/claims: anonymous/outsider denial, scoped
reads, CAS conflict, audit attribution/protection, idempotent create, changed retry
rejection, revocation and injected multi-row rollback. This does not substitute
for actual GoTrue, PostgREST, websocket or simultaneous-connection testing.

An initial Android build failed due to a duplicated allowBackup manifest attribute;
it was corrected and the next build passed. A widget-test asynchronous cancellation
wait was corrected; the final full suite passes. Node/Flutter required SDK/runtime
access outside the sandbox. An initial automatic approval attempt hit a usage
limit; later approved execution succeeded. No deployment was performed.

## In Progress

- External acceptance remains the active Phase 1 gate. Supabase staging is deployed;
  see [verified environment status](SUPABASE_ENVIRONMENT_STATUS.md). Docker local
  reset remains unverified because Docker is absent.

## Blocked / External setup

- Project, public configuration, baseline migration and approved owner test Event
  are provisioned and verified. Actual owner app sign-in remains to be tested.
- Yonatan/Yosef onboarding and shared-session acceptance are deferred by the owner.
- Run cloud two-client acceptance and simultaneous-session CAS test.
- Validate on Android hardware and macOS/physical iPhone; complete TestFlight gate.
- Referenced UMAN_EVENT_MANAGER_DESIGN_SPEC_v1.0.md is absent from this checkout.
  Existing Breslov reference assets remain preserved; visual sign-off is pending.

## Remaining

- Verify the external gates in supabase/README.md; measure realtime propagation.
- Complete bilingual design-system UI; the current English foundation screen is
  provisional and not the finished product design.
- Add archive/restore and broader Event field editing with versioned RPCs before
  claiming full Event management. Current mutation surface is create/rename.
- Implement later domain entities, transactional source/alert consistency and
  finance/logistics features only after foundation acceptance. No balance formulas
  or automatic lifecycle thresholds have been invented.
- Configure operator backups, retention and recovery drills. Review passport field
  access/minimization before implementing Person; no passport feature is shipped.

## Deprecated / Superseded

- Local encrypted DB as canonical source, optional Auth, single-device Phase 1,
  local upsert mutation flow, offline editing and local-file restore to live state.
- Local Drift code/tests appeared during concurrent work in this workspace. They
  are preserved under docs/history/local-foundation as inactive .dart.txt files;
  they are not deleted design evidence or active production code. Drift/sqlite3
  dependencies and build hooks are removed. KDF utilities remain reusable but
  unused by the cloud session/cache path. No released local data was migrated.
- Original progress record is preserved in docs/history. Old ZIPs are historical.
- Concurrent Product Compass/Build Workbook and resilience work-card additions
  were preserved. Their five cache regression tests are included in the 31-test
  result above; proposed future product flows were not implemented here.

## Next recommended phase

Workbook execution on 2026-09-18: the English
[Product Compass](docs/PRODUCT_COMPASS_AND_BUILD_WORKBOOK.md) is linked from the
README and agent instructions. The
[cache-resilience work card](docs/workcards/FOUNDATION_RESILIENCE.md) records five
reproduced and fixed regression cases and the same passing integrated validation.
The [entry and event-selection card](docs/workcards/ENTRY_AND_EVENT_SELECTION.md)
specifies the next UX slice; it is not a claim of implemented tour screens.
Master section 7 and its copy now consistently require explicit manager lifecycle
transitions. All 40 sectional copies were checked against the Master.

Cloud/device acceptance of this Event slice first. Then implement event-scoped
Person and the first logistics transaction with server-side rules/audit, preserving
existing warning/override semantics and the iOS gate.
