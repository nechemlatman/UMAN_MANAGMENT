# TASK-TASK-01 - Tasks MVP

Status: PARTIAL - implemented and locally verified; external integration gates outstanding.
Owner: Codex implementation owner. Branch: codex/task-01-vertical-slice.
Base: exact Beta commit 2b1d43d; Draft PR #6 depends on PR #5, unchanged.

Owner decision (2026-09-30): creation starts at canonical NEW. Persisted status
is mandatory, server-defaulted and excluded from metadata writes. Subsequent
changes use explicit lifecycle commands. Priority, assignee, due date,
description and notes remain nullable. UI states the initial status explicitly.
The domain and decoder reject missing/invalid persisted lifecycle status.

Implemented: event-scoped canonical reads, audited CAS/idempotent writes,
RLS, lifecycle transitions with server timestamps, explicit reopening,
soft delete/restore, assignee history, overdue/open filters, realtime/poll
reconciliation, phone UI and production Tasks factory/navigation.
Migration: `20260930083123_tasks_vertical_slice.sql`, finalized before deployment.
No hosted migration deployment or PR merge authorized or performed.

Verification: Level 3. Targeted Flutter tests: 26 passed. Full local PostgreSQL
harness: 683 passed, including NEW creation/audit, NOT NULL enforcement,
metadata status rejection, lifecycle/CAS and existing isolation checks.
Analyzer: no issues. Full Flutter: 182 passed. Configured Android debug APK:
built successfully with production Tasks enabled. Formatter, diff checks and
changed-file credential scan: passed. SDK update check disabled after its
network fetch stalled; installed SDK/dependencies used.
Phone widget workflows cover 360x640 RTL/LTR, light/dark and keyboard behavior.

Outstanding: independent review before integration; hosted Supabase realtime
and two-user runtime verification after authorized rollout; owner phone testing.
CI workflow targets main; this stacked PR targets Beta and does not trigger it.
This remains PARTIAL until required external gates pass; not ready to merge/deploy.
The locally built Tasks APK requires the new migration before hosted Tasks use.

Next priority is the already assigned TASK-BETA-02: Event Home / Control Center
and bilingual English-LTR / Hebrew-RTL foundation. Do not start Apartment Issues.
