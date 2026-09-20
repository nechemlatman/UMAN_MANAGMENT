# Phase 1 — Authenticated Cloud Persistence & Realtime Foundation

Updated: 2026-09-20. Status: **Deployed foundation working; owner reports physical Android login, Event creation/editing and observed Realtime synchronization. Full independent-session acceptance remains pending.** Do not mark the architecture migration fully
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

## Historical local foundation validation — 2026-09-18

| Check | Result |
|---|---|
| flutter analyze --no-pub | PASS — no issues |
| flutter test --no-pub | PASS — 31 tests |
| node tools/db-test/verify.mjs | PASS — 41 PostgreSQL checks |
| flutter build apk --debug | PASS — final rebuild completed, exit 0, 24.8 seconds |
| Supabase deployed Auth/REST/Realtime integration | Owner reports app Auth/Event/Realtime success; live database-role checks passed 2026-09-19; full service acceptance pending |
| Two independent DB sessions racing / two phones | NOT RUN |
| Android physical-device runtime | Launch, sign-in, Event create/edit and observed sync reported by owner on 2026-09-19; new feature acceptance remains separate |
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
limit; later approved execution succeeded. No deployment was performed during that historical local validation run. The later staging deployment is recorded below.

## In Progress

- External acceptance remains the active Phase 1 gate. Supabase staging is deployed;
  see [verified environment status](SUPABASE_ENVIRONMENT_STATUS.md). Docker local
  reset remains unverified because Docker is absent.

## Blocked / External setup

- Project, public configuration, baseline migration and approved owner test Event
  are provisioned and verified. Owner confirms actual Android app sign-in and Event create/edit; independent-session acceptance remains pending.
- Yonatan/Yosef onboarding and shared-session acceptance are deferred by the owner.
- Run cloud two-client acceptance and simultaneous-session CAS test.
- Complete remaining Android acceptance scenarios and macOS/physical iPhone/TestFlight gates.
- Active design authority: docs/DESIGN_SYSTEM.md. Historical Breslov assets are reference only.

## Remaining

- Verify the external gates in supabase/README.md; measure realtime propagation.
- Complete bilingual design-system UI; the current English foundation screen is
  provisional and not the finished product design.
- Event details editing, explicit later transitions, archive and soft-delete/restore
  are implemented and locally/live-role tested. Full Event acceptance is still
  pending: readiness definition, settings/correction semantics, bilingual UX,
  independent sessions and new physical-device workflows. See the Event workcard.
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

## Foundation closure audit — 2026-09-19

Starting Git HEAD: `f1d15b1143c7ff9b71c8e63e43b710e214cccf94`; working tree was clean.
Live project `rrgzalzaaprdsmwihqxa` was ACTIVE_HEALTHY; migration history contains
`202609170001 / cloud_foundation`. Three RLS tables, membership policies, empty
function search paths, restricted grants and events/event_members publication
were inspected. At audit time: 2 Events, 3 memberships, 8 audit entries.
The old provisioned Event version/count description is historical, not current.

Owner evidence supplied in this task: physical Android launch, authenticated
sign-in, Event creation/editing, observed Realtime synchronization. No client
pair, latency measurement or independent-session conflict evidence was supplied.
Do not infer two-manager, iPhone, TestFlight or production acceptance.

This session reran 41 local PGlite checks and the rollback-only live
`supabase/tests/remote_role_security.sql` under the additional approved owner
identity. Live checks cover member update/audit/version, stale rejection, direct
DML denial and synthetic outsider isolation. Claims are set by operator tooling;
these are not real Auth login or concurrent-connection tests.

Event completion and pending product decisions: docs/workcards/EVENT_MANAGEMENT.md.
Person remains the next domain only after Event acceptance.

## Event increment handoff — 2026-09-20

**Event vertical slice is NOT complete; Phase 1 is NOT production-ready.**
Exact verified implementation HEAD: `aee65054869e64623da1cb2cd718f5c2d3a46e2f`.
Documentation closure follows that implementation in a separate commit.
The [acceptance ledger](docs/FOUNDATION_ACCEPTANCE.md) is the current test matrix;
the earlier 31-test/41-check table above is historical.

Implemented: explicit Event details editor, separate details/editor pages,
capabilities, archive, soft-delete/restore and defined later lifecycle transitions;
central theme/spacing/BIDI tokens; ISO currency validation; four FK indexes.
Old create/rename API remains compatible. No new business domain was added.

Locally tested on 2026-09-20: clean Flutter analyze; 38 Flutter tests; 80 PostgreSQL
checks. Configured Android debug APK rebuilt successfully. On 2026-09-19 APK
installation and launch on Samsung succeeded; new UI mutation walkthrough was
not completed. Phone was disconnected when work resumed on 2026-09-20.
Owner's earlier Android/login/create/edit/observed-sync evidence remains valid,
but does not certify new features. Independent sessions are unavailable per owner.

Live tested: rolled-back field/CAS/audit/archive/soft-delete/restore/revocation
checks; invalid currency rejected; anonymous REST/RPC returned HTTP 401.
Nine hosted function bodies match source. Exact local/remote migration history:
`202609170001 cloud_foundation`, `20260919201737 event_management`,
`20260919202929 event_currency_codes`. No manual schema edits or test data commits.

Advisor: eight intentional restricted SECURITY DEFINER notices, leaked-password
protection disabled, four unused newly added FK indexes. Missing-FK-index notices
resolved; audit_event_time retained. No Auth configuration change.

Remaining Event work: minimum setup for READY (owner confirmed undefined),
settings semantics, archived correction policy, bilingual runtime UI and
accessibility/device acceptance, independent-session conflict/Realtime/recovery.
No archive reopening. iOS/Xcode/iPhone/TestFlight, Docker reset, operator backup
and isolated restore remain pending. OPD-002/003 remain open.

Next task: resolve the Event product decisions and complete the Event acceptance
matrix; only then start event-scoped Person with passport minimization/access/
retention/audit-redaction review. No passport data in the generic Event cache.

Execution interruption: automatic approval review hit a usage limit on one live
currency probe; it did not execute then. After the owner requested continuation,
the same rollback-only probe passed. This is not an unresolved security rejection.
