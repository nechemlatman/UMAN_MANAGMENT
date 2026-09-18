# UMAN EVENT MANAGER — Cross-platform delivery v1.1

This delivery record supplements Master v2.6, Technical v1.2 and ADR-001. The
matching agent gate is maintained in FOR_AGENT.md. Android and iOS are mandatory;
Windows/Android development does not narrow the production targets.

## Static dependency review — 2026-09-18

- supabase_flutter 2.17.2 supports Android/iOS Auth, REST and Realtime. Password
  login is implemented; URI session detection is disabled. OAuth/deep links are
  not part of this slice.
- flutter_secure_storage 11.2.0 resolves flutter_secure_storage_darwin 0.4.3,
  whose podspec requires iOS 13. app_links 7.2.1 also requires iOS 13. The Runner
  deployment target is 13.0. Runner.entitlements is referenced once in each of
  Debug, Profile and Release configurations.
- Sessions and Event cache use device-only/unlocked Keychain with no iCloud sync.
  Android declares INTERNET and disables app backup of secure local material.
- flutter_bloc/bloc support both platforms; domain contracts remain pure Dart.
  Drift/sqlite3 dependencies and native hooks are inactive/archived. Existing KDF
  helpers are retained but not used as the cloud authentication mechanism.
- No cleartext network exception, biometric prompt or background synchronization
  entitlement was introduced. Production target support is not runtime proof.

## iOS Compatibility Gate — NOT RUN

On macOS and a physical iPhone before production handoff:

1. Resolve native packages, build debug/release, verify iOS 13 and Keychain signing.
2. Verify sign-in, token refresh, force-close/relaunch session restore, logout,
   cache deletion, account switching and locked-device behavior.
3. Verify two separate administrators on Android/iPhone: shared event, automatic
   realtime propagation, stale-write rejection and preserved drafts.
4. Verify offline cached reads, expiry, reconnect, foreground and access revocation.
5. Verify Hebrew RTL/English LTR, mixed-direction text, SafeArea, keyboard,
   scrolling, gestures, text scaling, screen reader and 48dp touch targets.
6. Archive/sign, install through TestFlight and obtain event-manager acceptance.

The foundation screen is provisional and English-only; full bilingual UI and
Breslov visual sign-off remain required. The referenced design markdown is absent,
while reference assets are preserved.

## Release path

Local tests → Android build/device → Supabase staging → two-user acceptance →
macOS/Xcode → physical iPhone → TestFlight → manager acceptance.

Executed evidence is in PHASE1_PROGRESS.md. Android debug APK compilation passed;
Android physical runtime, actual Supabase integration and iOS runtime are not yet
verified. Do not claim production readiness from local test/build success.
