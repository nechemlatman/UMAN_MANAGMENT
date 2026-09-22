# UMAN EVENT MANAGER

Cloud-first Android/iOS event management for Yonatan and Yosef, using separate
Supabase Auth identities and one canonical PostgreSQL event state. Local storage
is a secure read cache; all edits require server confirmation.

Authoritative documents: [Master v2.6](UMAN_EVENT_MANAGER_SPEC_v2.6.md),
[Technical v1.2](UMAN_EVENT_MANAGER_TECH_SPEC_v1.2.md),
[ADR-001](ADR-001-CLOUD-FIRST-REALTIME-MULTIUSER.md),
[agent instructions](FOR_AGENT.md), [current status](STATUS.md), [active work](ACTIVE_WORK.md), and [visual design system](UMAN_EVENT_MANAGER_VISUAL_DESIGN_SYSTEM.md).
Historical versions are archived in [docs/history/](docs/history/).

Product intent and the working sequence are mapped in the English
[Product Compass and Build Workbook](docs/PRODUCT_COMPASS_AND_BUILD_WORKBOOK.md).
The first workbook execution is recorded in the
[Foundation resilience work card](docs/workcards/FOUNDATION_RESILIENCE.md).

## Setup

Follow [Supabase setup](supabase/README.md) to deploy migrations, provision separate
accounts and shared event membership. Copy config.example.json to ignored
config.local.json with the HTTPS URL and publishable client key, then run:

```
flutter pub get
flutter run --dart-define-from-file=config.local.json
```

Never supply backend service keys. Without configuration the app shows a setup
message and does not enable a local writable mode. Event supports creation,
details/editing, explicit lifecycle operations, final archive and soft-delete/restore.
The Event slice is not yet fully accepted; see the [Event workcard](docs/workcards/EVENT_MANAGEMENT.md)
and [acceptance ledger](docs/FOUNDATION_ACCEPTANCE.md).
The [Visual Design System](UMAN_EVENT_MANAGER_VISUAL_DESIGN_SYSTEM.md) governs the classic, clean, modern UI.

## Verification

```
flutter analyze
flutter test
npm ci --prefix tools/db-test
node tools/db-test/verify.mjs
flutter build apk --debug
```

The local PostgreSQL harness does not verify actual Supabase Auth/Realtime or
simultaneous connections. See the external acceptance gate in supabase/README.md.
iOS requires macOS and a real iPhone. Historical local persistence is preserved
under docs/history/local-foundation as inactive text, not production source.


## Continuous Integration

GitHub Actions runs the core non-destructive verification gate automatically on pushes and pull requests targeting `main`:

- `flutter analyze --no-pub`
- `flutter test --no-pub`
- `node tools/db-test/verify.mjs`

This CI gate is intentionally lightweight. It does not replace Android/iPhone device testing, live Supabase Auth/Realtime acceptance, two-account concurrency testing, or other task-specific verification.
