# Cloud foundation setup and verification

1. Create a Supabase project. Disable public signups. Create separate confirmed
   Auth accounts for Yonatan and Yosef through trusted operator tooling. Never
   place their passwords or service-role keys in source or Dart defines.
2. Install Supabase CLI and link the intended project. Apply versioned migrations
   with `supabase db push`; inspect the target before pushing. For local Docker
   testing use `supabase start` then `supabase db reset` (local data is reset).
3. Adapt `provision.example.sql` with real Auth UUIDs and approved event values,
   and execute via a trusted database connection. This is explicit, audited data
   provisioning, not an undocumented schema edit. Record the actual approving
   administrator as actor. Both memberships must reference the SAME Event ID.
   Additional event memberships/revocation remain operator-only; no public RPC.
4. Copy root `config.example.json` to ignored `config.local.json`. Supply only
   `SUPABASE_URL` (HTTPS) and `SUPABASE_PUBLISHABLE_KEY` (`sb_publishable_...`).
   Run `flutter run --dart-define-from-file=config.local.json`.

The schema publishes events and memberships to Supabase Realtime. RLS controls
reads and restricted functions control mutations; direct client DML is denied.
Clients create another event only after existing administrator approval. New
events grant only the creator membership; the operator adds additional managers.
Initial slice supports create/read/rename; archival metadata is modeled and
read-only checks enforced, but an archive/restore UI/RPC is not yet delivered.

## Local database verification

`npm ci --prefix tools/db-test` then `node tools/db-test/verify.mjs` from repository
root. The pinned PGlite package runs actual PostgreSQL SQL with emulated auth
roles/claims. Tests execute the unmodified migration and verify RLS, outsider and
anonymous denial, expected-version conflicts, audit protection, idempotency and
multi-row rollback. This is not a Supabase service or two-connection race test.

## External acceptance gate (not yet run)

- Deploy fresh migration; sign in from two separate clients as the two members.
- Create an event; operator grants second membership. Verify both see the same ID.
- Rename on A; B receives the new name automatically, without navigation reset.
- Keep B's edit form open, rename on A, save B: reject stale version and retain B's
  text. Verify one audit entry per successful change, with distinct actor IDs.
- Disable B's network, verify stale cache banner and disabled mutations, kill and
  reopen, then reconnect and verify all missed changes reconcile. Repeat websocket
  reconnect and foreground recovery. Cache expires after 24 hours.
- Revoke B's membership while connected; confirm rows disappear on reconciliation
  (at most the 20-second fallback interval), and all subsequent writes fail.
- Probe REST and RPC as anonymous/outsider; verify no data leaks or direct writes.
- Run simultaneous same-version updates using two DB sessions: exactly one wins.
- Inject a failure during event/membership creation: no partial Event or audit.
- Simulate response loss on create: retry the same request UUID, not a new one.
- Verify Android/iPhone secure session restore, local logout/cache purge and
  release builds. Configure operational backups and test isolated server restore.

Relevant official references: [Flutter initialization](https://supabase.com/docs/reference/dart/initializing),
[Realtime subscription](https://supabase.com/docs/reference/dart/subscribe),
[secure storage](https://pub.dev/packages/flutter_secure_storage).
