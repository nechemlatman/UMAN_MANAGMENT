# ADR-001 — Cloud-first realtime multi-user

Status: Accepted, 2026-09-17. Supersedes all local-authoritative architecture decisions.

Yonatan and Yosef require separate accounts on independent Android/iOS phones,
editing one shared event without refresh. The former planned encrypted Drift
database cannot be authoritative on each phone without conflicting state.

PostgreSQL in Supabase is the only source of truth. Supabase Auth identifies each
actor; explicit event membership grants administrator access. RLS protects reads,
and restricted transactional RPCs protect writes. Client UI checks are advisory.
No service-role key belongs in Flutter. Initial accounts and memberships are
provisioned by the backend operator, never by public signup metadata.

Realtime notifications invalidate repository state; clients fetch canonical data
on subscription, reconnection, foreground, login, mutation and conflict. Periodic
reconciliation covers missed events and membership revocation. Every update uses
an expected integer version; stale writes fail without changing data or audit.
Draft text survives conflict and requires deliberate reopening against fresh data.

Every material write produces a server-side audit entry in the same transaction.
Event creation plus initial membership is the first multi-row integrity operation.
Subsequent logistics and finance RPCs must lock the relevant scope and commit
source changes and derived alerts atomically. Existing capacity/overlap warnings
and explicit manager overrides remain product requirements, not blanket rejection.

Offline operation is cached reading only. No mutation queue, automatic merge,
peer-to-peer synchronization or optimistic success. An encrypted platform-secure
small Event snapshot is sufficient for the foundation; no released local
dataset exists to migrate. Local Drift code arrived during migration from concurrent work; it is preserved
as inactive .dart.txt history under docs/history/local-foundation. Existing KDF
utilities remain reusable; Drift dependencies and native hooks are superseded.
Cache is scoped by project/user, timestamped, cleared on logout and replaced only
from server reads. Remote revocation cannot erase an already offline device;
short cache expiry and device locking bound this risk.

Alternatives: retaining separate local masters fails the requirement; custom sync
or CRDTs adds unnecessary conflict complexity; a custom API adds operational work;
Firebase would require different relational integrity tooling. Supabase combines
transactions, constraints, identity, RLS and realtime in one service.

Security: TLS, platform-secure session storage, no raw exceptions/PII in logs,
least-privilege grants, protected audit and event isolation. Passport data is not
cached or implemented in this slice. Before Person delivery, isolate passport
fields from ordinary list/realtime payloads, define retention and access, and
review managed encryption; do not invent client cryptography. Backend privileged
operators remain trusted and require operational access controls and backups.

Tradeoffs: writes require connectivity, server availability and hosting cost;
realtime is eventually visible, not a commit protocol. External cloud testing and
macOS/iPhone validation remain release gates. There is no fabricated deployment.

Authority: Master v2.6, Technical v1.2 and CROSS_PLATFORM_DELIVERY.md. All domain
semantics and deferred finance allocation decisions survive this migration.
