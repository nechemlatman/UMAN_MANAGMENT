# Foundation and Event acceptance ledger

Updated 2026-09-20. **Partial acceptance; Event and Phase 1 are not complete.**
Verified implementation HEAD: `aee65054869e64623da1cb2cd718f5c2d3a46e2f`.
This ledger is a subsequent documentation commit, not a claim that its own hash
is the tested implementation hash. Use `git rev-parse HEAD` for checkout identity.

## Evidence classes

| Check | Executed evidence | Remaining |
|---|---|---|
| Physical Android launch/login/create/edit | Owner reported performed on 2026-09-19; agent observed signed-in existing list | New Event flow walkthrough |
| Realtime propagation | Owner reports observed sync; controller notification test passes | Measured propagation across independent authenticated clients |
| Two identities see same Event | Existing memberships and live role probe | Two real Auth sessions; owner says unavailable |
| Open draft survives remote change | Flutter widget test, including optional fields | Independent-client runtime test |
| Stale update rejection | Local PostgreSQL and live rollback-only role tests | Simultaneous same-version requests on independent connections |
| Explicit conflict/reapply | Widget test retains draft, shows conflict and requires reopen | Physical-device conflict workflow |
| Audit successful changes only/correct actor | Local and live rollback assertions | Distinct real-session actors in committed acceptance scenario |
| Membership revocation | Local controller/cache tests; live fixture membership revoked within rollback transaction | Connected-client disappearance/recovery latency |
| Anonymous read/mutation denial | Real HTTPS GET events / POST archive_event: HTTP 401 on 2026-09-20 | None for these probes; other endpoints remain covered by SQL grants |
| Unrelated-user isolation | Local and live synthetic-claim role tests | Actual unrelated Auth session |
| Missed notification/reconnect/foreground | Controller tests; implemented polling/foreground hook | Live network/websocket interruption and physical restart |
| Atomic create/injected failure | Local PostgreSQL harness | Live injected-failure/response-loss test |
| Archive/delete/restore | Local and live rollback tests, including stale and archived rejection | Physical UI confirmation and committed end-to-end test |
| ISO currency | Local harness and live invalid-currency rollback rejection | Device field walkthrough |
| Migration verification | CLI dry-runs/push/history; nine deployed bodies match migration source | Docker clean reset (Docker unavailable) |
| Android artifact | Configured debug build; prior install/launch succeeded | Final feature acceptance on reconnected phone |
| iOS/Xcode/iPhone/TestFlight | Static baseline only | All runtime/release gates pending; Windows cannot certify them |
| Backups/restore | Runbook requirement only | Operator backup policy and isolated restore drill |

Live SQL used `remote_role_security.sql` and `remote_event_management.sql` inside
explicit BEGIN/ROLLBACK wrappers with approved operator-selected actor claims.
No test fixture or test mutation from those probes was committed. This exercises
real hosted PostgreSQL, not GoTrue sign-in, PostgREST JWT issuance or websocket
delivery. Do not rename it “two-session tested”. Counts before/after management
probes remained 2 Events / 3 memberships / 8 audit rows.

Final local results: clean `flutter analyze --no-pub`; 38 passing Flutter tests;
80 passing PGlite checks across all source migrations. Earlier widget-test failures
were scroll-target/visibility assertions from the old dialog flow and were fixed;
final full suite passed. The two new editor regressions also passed.

## Exact deployed migration history

Project `rrgzalzaaprdsmwihqxa`:

1. `202609170001` — `cloud_foundation`
2. `20260919201737` — `event_management`
3. `20260919202929` — `event_currency_codes`

Applied through the pinned CLI after linked-target/history/dry-run checks.
Existing APIs remain compatible. No manual schema edits, reset, signup change or
new Person/domain table. RLS remains enabled on all three tables; authenticated
table privileges remain SELECT-only; audit is inaccessible for client execution.
Events and event_members remain published. Function bodies were compared against
source after whitespace normalization; this is not a full schema-diff assertion.

## Advisor state and decisions

- Eight intentional authenticated SECURITY DEFINER warnings: create_event,
  update_event, is_event_admin, edit_event_details, transition_event,
  archive_event, soft_delete_event, restore_event. Empty search_path and restricted
  grants checked; each mutation validates membership with locking and uses CAS.
  Audit trigger is not client executable. [Advisor explanation](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable).
- Leaked-password protection remains disabled. Official guidance reviewed; no
  account/security behavior was changed. Plan availability and weak-password
  handling require review before enabling. [Password guidance](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection).
- Four uncovered FK indexes were added. Latest performance Advisor reports four
  unused new indexes; retain them and audit_event_time. Tiny-dataset usage is not
  grounds for removal. [Index guidance](https://supabase.com/docs/guides/database/database-linter?lint=0001_unindexed_foreign_keys).
- Official changelog reviewed, including Realtime schema lockdown; this project
  does not modify service-owned realtime schema objects. [Changelog](https://supabase.com/changelog/realtime-schema-locked-down-against-modification).

## Clean gate and next task

Do not start Person yet. Define minimum setup for READY (owner explicitly says
undefined), settings values/shared semantics and scope of archived corrections.
Finish bilingual Event UX and device/independent-session acceptance. Archive
reopening remains forbidden. Finance OPD-002/003 remain unresolved; no balances.
Person privacy/access/cache review is mandatory before passport implementation;
the generic Event cache must never contain passport data.
