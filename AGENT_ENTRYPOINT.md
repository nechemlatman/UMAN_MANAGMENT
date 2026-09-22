# UMAN EVENT MANAGER — AGENT ENTRYPOINT

This file is the mandatory entrypoint for every implementation or review agent.

## Canonical repository documents

Read these exact files in this order before consequential work:

1. `STATUS.md` — current verified project state and unresolved gates.
2. `MULTI_AGENT_PROTOCOL.md` — mandatory multi-agent operating rules.
3. `ACTIVE_WORK.md` — live task ownership and coordination ledger.
4. The assigned task brief under `docs/workcards/`.
5. `UMAN_EVENT_MANAGER_SPEC_v2.6.md` — authoritative product/domain specification.
6. `UMAN_EVENT_MANAGER_TECH_SPEC_v1.2.md` — authoritative technical architecture.
7. `ADR-001-CLOUD-FIRST-REALTIME-MULTIUSER.md` — accepted cloud-first realtime multi-user architecture decision.
8. `CROSS_PLATFORM_DELIVERY.md` — Android/iOS delivery and verification gates.
9. `UMAN_EVENT_MANAGER_VISUAL_DESIGN_SYSTEM.md` — sole authoritative visual-design instruction.
10. Current Git state, relevant implementation, migrations, tests, and recent commits.

Use `FOR_AGENT.md` for the fuller engineering rules and handoff expectations.

## Documentation authority

- The repository is the source of truth; chat history is secondary.
- Historical specifications under `docs/history/` are reference only and never implementation authority.
- `PHASE1_PROGRESS.md` is historical progress evidence only. It is not the active status ledger.
- There is no active root `TODO.md`. Work tracking belongs in `ACTIVE_WORK.md`, `STATUS.md`, and task briefs under `docs/workcards/`.
- Do not substitute similarly named or older files for the canonical documents above.

## Non-negotiable operating rules

- One implementation owner per active task.
- Do not edit overlapping active work until ownership is clear.
- Stay inside the assigned task brief.
- Do not perform unrelated cleanup or redesign.
- Coordinate high-impact shared resources: Supabase schema/migrations, RLS/auth, realtime contracts, routing, core domain contracts, and shared platform configuration.
- Never expose secrets.
- Distinguish VERIFIED from IMPLEMENTED BUT UNVERIFIED.
- Significant work must pass the integration gate in `MULTI_AGENT_PROTOCOL.md`.
- Update `ACTIVE_WORK.md` and `STATUS.md` before handoff when the actual project state changed.
- If documentation, code, migrations, or tests disagree, stop and report the discrepancy rather than improvising.
