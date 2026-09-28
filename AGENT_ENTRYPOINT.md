# UMAN EVENT MANAGER — AGENT ENTRYPOINT

**Operating mode:** Product Delivery Mode

This is the mandatory entrypoint for implementation and review agents.

## Normal task — required reading

Read only:

1. `AGENT_CONTEXT.md`
2. `ACTIVE_WORK.md`
3. the assigned task instruction/workcard
4. the relevant implementation files and tests

Then begin the task.

Do **not** reread every specification, historical status note, completed workcard, migration or previous handoff merely because a new task started.

## Read more only when relevant

- product/domain ambiguity → `UMAN_EVENT_MANAGER_SPEC_v2.6.md`
- Supabase, schema, RLS, Auth, realtime or shared architecture → `UMAN_EVENT_MANAGER_TECH_SPEC_v1.2.md` and `ADR-001-CLOUD-FIRST-REALTIME-MULTIUSER.md`
- visual design → `UMAN_EVENT_MANAGER_VISUAL_DESIGN_SYSTEM.md`
- release/iOS/platform gate → `CROSS_PLATFORM_DELIVERY.md`
- ownership collision, parallel work or takeover → `MULTI_AGENT_PROTOCOL.md`
- verification scope → `TEST_MATRIX.md`
- current delivery strategy → `PRODUCT_DELIVERY_MODE.md`

The repository is authoritative; chat history is secondary. Historical files under `docs/history/` are evidence, not required implementation context.

## Before editing

- inspect branch and Git status;
- confirm the task does not overlap an active task in `ACTIVE_WORK.md`;
- inspect the files you will actually change;
- reuse the nearest established implementation pattern.

## Operating rules

- preserve settled architecture unless a real blocker is discovered;
- stay within assigned scope;
- no unrelated cleanup/refactor/redesign;
- never expose secrets;
- preserve Logic / Structure / Visual Design separation;
- verify according to actual blast radius using `TEST_MATRIX.md`;
- independent inspection is risk-based, not automatic;
- update live documentation only when material project state changed.

If code and an authoritative requirement genuinely conflict, stop that consequential change and report the specific conflict. Do not manufacture a broad audit first.
