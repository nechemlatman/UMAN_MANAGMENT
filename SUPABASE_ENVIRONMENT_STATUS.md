# Supabase staging verification — 2026-09-19

Status: **PARTIALLY READY — Docker local reset and authenticated app acceptance pending.**

The owner explicitly deferred Yonatan/Yosef onboarding and approved owner-only testing.
Two-manager, independent-session and realtime propagation acceptance are NOT complete.

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
  record the actual actor above. After rolled-back security probes, Event remains
  version 1 with its approved name and those two audit entries.
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
  launched on SM S918B / Android 16. Actual password sign-in, shared data visibility,
  sign-out isolation and independent-session propagation remain unverified.
- Ignored config.local.json contains ONLY URL and modern publishable key.
  Git check-ignore confirms exclusion; git ls-files confirms it is untracked.
- Pattern-based current tracked tree/reachable-history scanner found no recognized
  privileged keys, tokens, private keys or credential-bearing database URLs.
  This is not an exhaustive detector of arbitrary passwords. No passwords or
  privileged keys were placed in application configuration or task documentation.

## Next acceptance actions

1. Owner signs into the installed Android app; verify Event visibility, update and
   sign-out/session clearing. Do not send passwords to the agent.
2. Make Docker available and run pinned CLI start then db reset --local; repair
   failures only through versioned migrations and rerun to deterministic success.
3. When owner resumes two-manager scope, create/confirm real distinct accounts,
   provision both to the approved SAME Event with real actor, then run all
   independent-session/realtime/revocation tests in supabase/README.md.
