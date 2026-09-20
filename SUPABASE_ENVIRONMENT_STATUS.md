# Supabase staging verification — 2026-09-19

Status: **PARTIALLY ACCEPTED — Android Auth/Event/Realtime success reported by owner; independent-session acceptance and Docker reset pending.**

The owner explicitly deferred Yonatan/Yosef onboarding and approved owner-only testing.
Two-manager and independent-session acceptance are NOT complete. Realtime synchronization has been observed, as reported by the owner; the full propagation/reconnect/conflict matrix remains pending.

## Target and tooling

- Project `rrgzalzaaprdsmwihqxa`, URL `https://rrgzalzaaprdsmwihqxa.supabase.co`.
- Project name `nechem.latman@gmail.com's Project`; region `ap-southeast-2`;
  PostgreSQL `17.6.1.166`; target inspected as active/healthy before modification.
- Supabase CLI **2.117.0**, exact npm devDependency under `tools/supabase-cli`,
  committed lockfile; Node **v22.16.0**. Official CLI interactive login completed.
- Link succeeded and ignored `supabase/.temp/project-ref` matched the intended target.
- Remote migration history/public schema were empty before push. CLI dry-run listed
  only `202609170001_cloud_foundation.sql`. Real CLI push succeeded; remote history
  subsequently confirmed `202609170001` / `cloud_foundation`.
- No ad hoc schema changes or remote reset were performed.

## Approved provisioning

- Confirmed, non-anonymous owner: `nechem.latman@gmail.com`.
- Auth UUID and real approving/audit actor: `892c4763-9309-4a90-9ea1-7f876c90fb2f`.
- Event: `6ce1dd46-1cb0-4001-a158-9fe7f79d140a`, `Uman — בדיקות`, year 2026,
  dates 2026-09-18 through 2026-09-20, USD, explicitly approved by the owner.
- Initially one administrator membership joined that Auth UUID to that Event.
- Operator transaction created Event and membership; two CREATE audit entries
  record the actual actor above. At initial provisioning, Event was version 1 with two audit entries. This is historical; later app writes have occurred.
- Yonatan and Yosef: not provisioned, deliberately deferred by owner; no substitutes.

### Additional owner account approved on 2026-09-19

The owner explicitly requested administrator access for `avoda.latman@gmail.com`
after confirming that this was the account used in the app screenshots.
Its real confirmed, non-anonymous Auth UUID is
`f7cc8b77-e115-4f5a-8949-45d117327c40`. Operator provisioning added an
`administrator` membership to the SAME Event above, with the original owner
`892c4763-9309-4a90-9ea1-7f876c90fb2f` as approving/audit actor.
Both memberships now exist. The schema has one administrator role, not a separate
global super-admin role. A transaction under the additional account's authenticated
database role verified Event read, update RPC and provisioning audit attribution;
the test update was rolled back. This is not independent-device acceptance.

## Verified security boundaries

- Auth settings API: public signup disabled, anonymous users disabled, email login
  enabled. Existing owner email is confirmed. No Auth settings change was needed.
- All three public tables have RLS; six indexes, twenty constraints, four functions,
  and two audit triggers inspected. Events/memberships are in Realtime publication.
- SELECT policies scope events/audit to membership and memberships to auth.uid().
  No unrestricted write policy. Direct authenticated DML is revoked.
- SECURITY DEFINER functions have empty search_path, explicit grants and actor/
  membership checks. Audit trigger function is not client executable. Existing
  approved administrators can create a new Event and its creator membership;
  clients cannot add/revoke membership in an existing protected Event.
- Publishable-key anonymous REST read, membership insertion and create_event RPC
  probes returned HTTP 401 / SQL 42501.
- Remote transaction under `authenticated` role passed owner read/RPC update,
  version attribution, stale version rejection, direct-write denial, membership
  insertion denial and audit deletion denial. Synthetic non-member claims could
  neither read protected data nor update/create an Event. Transaction rolled back.
  These are database-role tests, NOT actual second-user Auth/session acceptance.
- Security Advisor reports intentional authenticated SECURITY DEFINER exposure for
  create_event, update_event and is_event_admin; authorization reviewed/tested above.
  [Advisor explanation](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable).
- Advisor also reports leaked-password protection disabled; this remains an open
  hardening item, not a claim of a clean advisor report.
  [Password protection](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection).

## Local/application evidence and limits

- Docker executable/service absent. `supabase start` failed because Docker/Podman
  is missing; `supabase db reset --local` failed because no local service exists.
  Full local migration reset is NOT verified. No remote reset was attempted.
- PGlite migration/security harness: 41 checks passed, with emulated Auth roles.
  This does not replace Docker/GoTrue/PostgREST/realtime testing.
- Flutter run with `--dart-define-from-file=config.local.json` built, installed and
  launched on SM S918B / Android 16. Owner now confirms password sign-in, Event visibility, creation/editing and observed Realtime sync. Sign-out isolation and independent-session propagation/conflict acceptance remain pending.
- Ignored config.local.json contains ONLY URL and modern publishable key.
  Git check-ignore confirms exclusion; git ls-files confirms it is untracked.
- Pattern-based current tracked tree/reachable-history scanner found no recognized
  privileged keys, tokens, private keys or credential-bearing database URLs.
  This is not an exhaustive detector of arbitrary passwords. No passwords or
  privileged keys were placed in application configuration or task documentation.

## Next acceptance actions

1. Complete remaining Android sign-out/session clearing, reconnect, offline and
   conflict acceptance. Launch/login/create/edit/observed sync are owner-confirmed.
2. Make Docker available and run pinned CLI start then db reset --local; repair
   failures only through versioned migrations and rerun to deterministic success.
3. When owner resumes two-manager scope, create/confirm real distinct accounts,
   provision both to the approved SAME Event with real actor, then run all
   independent-session/realtime/revocation tests in supabase/README.md.

## Current audit — 2026-09-19

Target and baseline migration rechecked through Supabase MCP. Live catalog agrees
with source foundation functions/policies/publication; 2 Events, 3 memberships,
8 audit entries observed before rollback-only role tests. Tests completed without
committing probes. See PHASE1_PROGRESS.md for evidence boundaries.

Security Advisor: three intentional authenticated SECURITY DEFINER warnings
(create_event, update_event, is_event_admin). Each has empty search_path and
auth.uid-based authorization; mutations lock membership. is_event_admin returns
only the caller’s membership predicate. Audit trigger is not client executable.
No rewrite merely to clear warnings. Leaked-password protection remains disabled.
Official password-security guidance was reviewed: protection uses HaveIBeenPwned;
plan availability and existing-user weak-password handling must be checked before
enabling. No Auth behavior was changed.

Performance Advisor: uncovered FK indexes on audit_entries.actor_user_id,
event_members.created_by, events.created_by, events.updated_by; informational at
this scale. Preserve audit_event_time despite its unused-index notice.
[FK index guidance](https://supabase.com/docs/guides/database/database-linter?lint=0001_unindexed_foreign_keys).

## Latest deployed state — 2026-09-20 (supersedes initial counts/status above)

Migration history matches local files exactly by version/name:
`202609170001 cloud_foundation`, `20260919201737 event_management`,
`20260919202929 event_currency_codes`.
The new migrations were applied via pinned CLI after dry-run, without seeds or
vault changes. Nine deployed function bodies match source after whitespace
normalization; empty search_path, grants, RLS, triggers and SELECT-only client
privileges were checked. Three public tables remain; no Person schema.

Security Advisor now lists eight intentional restricted client-executable
SECURITY DEFINER functions, plus leaked-password protection disabled. Performance
Advisor no longer reports uncovered foreign keys; four new indexes are currently
unused. Retain them and audit_event_time. See the current
[acceptance ledger](docs/FOUNDATION_ACCEPTANCE.md) for test results and limits.

Live Event management rollback test passed: fields, version/actor, stale failure,
no failure audit, tombstone restore, final archive and revoked access. A separate
invalid ISO code probe passed on 2026-09-20. Real anonymous HTTPS read and archive
RPC probes returned 401. No independent authenticated sessions were available;
owner confirmed that gate must remain pending. Phone disconnected on resume;
new-feature physical acceptance is pending, despite prior successful install/launch.
