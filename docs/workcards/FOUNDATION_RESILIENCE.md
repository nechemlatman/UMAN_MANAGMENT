# Work card — Event cache resilience

Date: 2026-09-18.
Progress: implementation complete; targeted regression tests passed; final validation recorded below.

## Requirement and scope

- Workbook: V-03, V-19; VC-02 and VC-03 foundation prerequisites.
- Specification: Master v2.6 sections 26–29 and AC-08; Technical v1.2, Realtime and cache; ADR-001.
- Requirement status: already specified. No new product decision is required.
- Problem: a cache must not prevent Yonatan or Yosef from reaching authorized server data, display expired information, or leave data visible after an authorization failure.
- Scenario: when cached information is unusable or access is denied, the administrator sees a safe read-only state and the application can still reconcile with the server.

## Data, authorization, and behavior

The Event snapshot remains partitioned by authenticated user and project in infrastructure. Server reads remain subject to membership RLS. Cache failures do not grant access or enable writes. Only snapshots from confirmed server reads are persisted locally. This change does not alter server source data, audit records, shared event settings, or personal preferences.

The 24-hour maximum cache age is now defined once in EventSnapshot and used by both secure storage and the application controller. Future timestamps are invalid. The controller validates a snapshot before emitting it to the UI, independently of storage validation.

Failed cache reads no longer abort startup. Unknown read failures follow the same age policy as known connectivity failures. An authorization failure removes visible rows, edit access, and the previous synchronization timestamp before awaiting cache deletion. A disconnected signal also checks whether visible data has expired.

This work does not implement change-view receipts, a change inbox, Push, additional memberships, offline writes, or new business entities. Those remain separately tracked requirements or proposals.

## Acceptance evidence

Five regression scenarios were first run against the existing implementation: all five failed. After the fix, all five passed alongside the nine existing controller tests:

1. A cache read failure does not stop authenticated server loading.
2. An expired snapshot is never emitted while waiting for a server response.
3. A future-dated snapshot is never emitted while waiting for a server response.
4. An unexpected read failure cannot expose an expired initial snapshot.
5. An authorization failure hides data and disables editing before slow cache deletion completes.

Test: [event_cache_resilience_test.dart](../../test/application/event_cache_resilience_test.dart).
Implementation: [EventController](../../lib/application/event_controller.dart), [EventSnapshot](../../lib/domain/repositories/event_repository.dart), [SecureEventCache](../../lib/infrastructure/cloud/secure_cloud_storage.dart).

Final validation is appended after execution. These local tests are not evidence of deployed Supabase, real websocket delivery, OS secure-storage behavior, or Android/iPhone runtime acceptance.

## Workbook execution and follow-up

- Translated the entire Product Compass and Build Workbook into English, retaining requirement IDs, proposals, open decisions, and original review findings.
- Linked the workbook from the project README and agent instructions.
- Reviewed the cloud foundation already being updated by the concurrent task `Migrate to cloud-first realtime`; retained its changes and added narrowly scoped resilience corrections.
- Documentation alignment by that task must be assessed from the current files, not the historical findings in the workbook.
- Next gate: complete the documented live-cloud/two-device acceptance and platform checks. Do not mark the entire foundation complete based on local test counts.
- Next product preparation: specify the welcome/tour and event-selection flow (V-14/V-15) and the change-awareness workflow (V-05), retaining explicit decisions about login naming, shared membership, and acknowledgment behavior.
