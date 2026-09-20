# TASK-PEOPLE-VERIFY-02 — final People verification handoff

Owner: Codex. Status: READY_TO_MERGE (scoped tests and evidence only).
Checkout: main, observed HEAD 4f0c7cb; concurrent Flights work is owned by Gemini.

Objective: finish the original People task's evidence and verify authorization
failure/race handling without modifying the concurrently active Flights task.
Scope: test/people_controller_test.dart; People formatting; People workcard;
STATUS.md and ACTIVE_WORK.md evidence notes.
Out of scope: Flights, shared routing, database changes, visual redesign.
Sources: Master §§9/24/26–30, Technical v1.2, ADR-001, MULTI_AGENT_PROTOCOL.md.
Dependencies: existing People implementation; full suite depends on Flights fake
repository and fixture repairs by its owner.

Acceptance/evidence: added mutation-denial and in-flight-revocation tests;
19 scoped People controller/domain/SDK transport tests passed. Earlier integrated
People run passed 58 Flutter tests, 158 PostgreSQL checks, clean analysis and
configured Android build; hosted rollback probes passed. Latest combined suite
is failing in concurrent Flights work, including its import into the shell test.
No tests removed or weakened. Changes remain uncommitted for integration.

Remaining: full combined verification after Flights stabilizes; independent
sessions and physical-device checks remain pending by explicit owner direction.
Detailed implementation, deployed migration, privacy/retention decisions, advisor
review and limitations: [PEOPLE.md](PEOPLE.md).
