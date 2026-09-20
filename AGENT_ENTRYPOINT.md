# UMAN EVENT MANAGER — AGENT ENTRYPOINT

This file is the short mandatory entrypoint for every coding agent.

## Before You Touch Code

Read in this order:

1. `STATUS.md`
2. `MULTI_AGENT_PROTOCOL.md`
3. `ACTIVE_WORK.md`
4. The Task Brief assigned to you
5. Relevant authoritative specifications
6. Current Git state and relevant implementation/tests/migrations

## Non-Negotiable Rules

- The repository is the source of truth; chat history is secondary.
- One implementation owner per active task.
- Do not edit work that may overlap another active task until ownership is clear.
- Stay inside the Task Brief scope.
- Do not perform unrelated cleanup/refactoring.
- Coordinate high-impact shared resources, especially Supabase schema/migrations, RLS/auth, realtime contracts, routing, and core domain contracts.
- Never expose secrets.
- Distinguish VERIFIED from IMPLEMENTED BUT UNVERIFIED.
- Significant work must pass the integration gate in `MULTI_AGENT_PROTOCOL.md`.
- Update `ACTIVE_WORK.md` and the established project status documentation before handoff.
- If interrupted or approaching quota/tool limits, leave a recoverable handoff whenever possible.

If instructions conflict with the repository or authoritative specifications, stop and report the conflict rather than improvising.
