# UMAN EVENT MANAGER — PROJECT STATUS

**Last reconciled:** 2026-09-27
**Authoritative main:** `d2536959bb8ab776176ce0cb532bcd00beb001f3`
**Implementation branch:** `codex/trn-02-vertical-slice`
**Owner:** Codex Lead Builder

## Current state

| Task | State | Verified reality |
|---|---|---|
| Event foundation | VERIFIED locally and staging | Auth, membership, RLS, CAS, audit, lifecycle and restore remain intact. |
| TASK-PEOPLE-01 | DONE | Previously integrated and deployed; full regression suite remains green. |
| TASK-FLT-01 | DONE | Previously integrated; both pending migrations now deployed. Forward RPC privilege repair removes anonymous EXECUTE without changing authorization semantics. |
| TASK-TRN-01 | DONE | `d253695` closure verified: clean analyzer, 88 Flutter tests, 304 PostgreSQL checks, 21 Transport files formatting clean. Hosted schema/security/CAS/restore/audit smoke passed. |
| TASK-TRN-02 | REVIEW — IMPLEMENTED AND VERIFIED | Trip/TripPassenger schema and full Flutter workflow on implementation branch; deployed to staging. Integration/review is pending; not yet in main. |
| TASK-ACC-01 | PLANNED | No accommodation implementation performed. |

## Trip slice

- Pure Dart Trip and TripPassenger entities/inputs, codecs, repository contract,
  scoped Supabase implementation, controller and EventShell/Transport integration.
- Trip list/search, details, editor, Driver/Vehicle/Flight assignments, passenger
  assignment/status/pickup editor, tombstones and restore.
- All five relationships enforce same-event composite FKs. RLS protects reads;
  ten explicit authenticated RPCs use authorization, CAS and atomic audit.
- Six event-filtered realtime dependencies, reconnect/foreground refresh,
  serialized reads, 20-second reconciliation and resource disposal.
- Capacity excludes cancelled/tombstoned passengers. Exact capacity is valid;
  overflow warns without rejecting or removing manager assignments.
- Material Flight changes raise persistent Trip list/detail advisories against
  the saved link snapshot. Trip times remain unchanged. Actual arrival does not
  change status. Pickup location stays explicit and nullable.
- No general Control Center/rules-engine expansion or unrelated visual redesign.

## Staging reconciliation

Project `rrgzalzaaprdsmwihqxa` inspected ACTIVE_HEALTHY. History increased from four
migrations (through People) to ten, matching this branch. Applied using pinned
CLI 2.117.0 with reviewed dry-runs and `--skip-vault`; no reset, seed, history
fabrication or committed smoke data.

Applied existing migrations, in order:
1. `20260920090000_flights.sql`
2. `20260920110000_flights_integrity_repair.sql`
3. `20260920120000_drivers_and_vehicles.sql`
4. `20260924092718_transport_foundation_repair.sql`

Added/applied:
- `20260926201052_flights_rpc_privileges.sql`
- `20260926201434_trips_vertical_slice.sql`

Transport tables were absent before deployment; the fresh-install path required
no legacy-row actor. No previous editor was substituted as approving actor.
Hosted rollback tests use the previously approved actual Auth administrator.

## Verification

- Analyzer: clean.
- Full Flutter gate: 111 passed, including the empty-form regression.
- PostgreSQL/PGlite: 370 checks passed; all migrations exercised unmodified.
- Changed Dart files: formatter clean; `git diff --check` clean.
- Android debug APK rebuilt successfully with the final form guards.
- Hosted `remote_transport.sql` and `remote_trips.sql`: passed inside BEGIN/ROLLBACK.
  Covers domain writes, composite isolation, CAS, tombstones/restore, audit,
  capacity, manager sovereignty, outsider RLS and anonymous denial.
- Remote catalog confirms tables, constraints, RLS, denied direct DML, all ten
  Trip RPC grants/search paths, and both Realtime publication entries.
- Real anonymous HTTPS probes: Trip table, passenger table and list RPC all 401.
- SDK HTTP/WebSocket fixture validates event filters, change invalidation and
  channel removal. This is not independent-client staging websocket acceptance.
- Advisors: ten new intentional authenticated SECURITY DEFINER endpoints, all
  checked for explicit authorization/restricted grants. No new uncovered Trip FK
  indexes. Four existing FlightPassenger FK index gaps remain non-blocking;
  existing leaked-password protection warning remains. See environment ledger.

## Remaining external gates

- Review/CI and integration of this branch into main; no unexecuted CI claim.
- Independent authenticated two-client realtime/reconnect/concurrent-save and
  physical Android acceptance; rollback role tests do not replace these.
- macOS/Xcode, physical iPhone, secure storage runtime, TestFlight acceptance.
- Docker-based local service/reset verification (Docker unavailable previously).
- Existing operator backup/restore and Auth hardening acceptance.

`PHASE1_PROGRESS.md` is historical evidence. ACTIVE_WORK.md and workcards hold
current ownership and scope; prior 2026-09-24 REVIEW gates are superseded here.
