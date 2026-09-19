# Work card — Welcome, tour, and event selection

Date: 2026-09-18. Progress: specified for the next product slice; not implemented.

## Sources and boundaries

Workbook V-03, V-04, V-14, V-15 and VC-01/02/06; Master sections 7, 22, 26–29; Technical v1.2. An optional introductory tour and annual event creation are explicit owner requirements. The proposed screen details below are implementation guidance, not evidence of completion.

The current foundation uses email/password and operator-provisioned memberships. Retain those behaviors until product decisions change them. Do not add public registration, an alias authentication service, automatic membership grants, Hebrew calendar dependencies, or demo records in the production database as part of the tour.

## User problem and flow

Yonatan and Yosef need to understand the application briefly, enter their own accounts, and identify the correct annual event without accidentally creating separate copies.

1. An unauthenticated welcome screen offers Sign in and Take a tour.
2. The tour explains the command center, domain navigation, and working together. Next, Back, and Skip remain clear. Explanations describe planned capabilities honestly until those capabilities exist.
3. Completing or skipping the tour leads to sign-in. The tour does not access repositories, request permissions, or show real people/events before authentication.
4. A restored authenticated session opens the authorized event list directly. Help can reopen the tour at any time.
5. Existing events appear before the create action. The screen shows the event name, date range, and stage; selecting an event establishes the active event scope for later domain screens.
6. If no events are authorized, explain that access has not yet been granted. Do not imply that an outsider can create an event: the current server permits creation only for an existing administrator.
7. The create flow collects a name, stay dates, and base currency. Validate real civil dates and an ordered date range before submission. The server remains authoritative and enforces its own validation.
8. A new event appears only after server confirmation. Reuse the request UUID on an uncertain retry. Explain that the other administrator's membership still requires operator provisioning under the current model.

## State and failure behavior

- Tour progress is navigation state; it is not a business entity or an auditable operational change.
- Tour replay must work even if persistence of a first-visit preference is unavailable. No new storage dependency is required merely to display help.
- Login fields are not overwritten by background UI updates. Passwords are cleared safely and never logged.
- Offline event views display the last confirmed synchronization time. Expired or unauthorized snapshots are not exposed; writes stay disabled.
- Authentication and membership errors use understandable language without exposing backend error text.
- Realtime events must not replace an open form's text. A stale save preserves the draft and asks for deliberate reopening against current data.
- An annual event is identified by server ID. Similar names or dates may prompt a review, but are not a reason to invent a unique-year constraint: the specification permits multiple independent events.

## Presentation constraints

Use the project's shared theme/components and logical Start/End layout. Hebrew RTL, English LTR, mixed-direction strings, text scaling, SafeArea, scrolling, and at least 48dp interaction targets are required. Follow ../DESIGN_SYSTEM.md; historical Breslov references are not active visual authority.

## Acceptance checks

1. Tour, skip, back, completion, and replay work without signing in and without querying private event data.
2. Restored authenticated users reach existing events without a mandatory tour or new-event form.
3. The two authorized identities see the same event ID after explicit membership provisioning.
4. Selecting another event changes the active scope; no domain data is carried from the previous event.
5. An empty authorized list is distinct from a loading failure; unknown information is not presented as confirmed absence.
6. Invalid dates, an end before the start, and empty required fields produce actionable errors without submitting a mutation.
7. Offline creation is unavailable; uncertain online creation retries use the same request ID.
8. Tour and event selection remain usable with Hebrew RTL, English LTR, enlarged text, and the phone keyboard.

## Decisions before dependent implementation

- Hebrew-year naming and the meaning of the stored year field: the current foundation uses a Gregorian year. Do not relabel it as a Hebrew year.
- A user alias instead of email requires a separate authentication decision; it is not needed for the tour.
- Automatic inclusion of the second administrator requires a server authorization design. Keep explicit operator membership until that change is defined.
- Event-specific “what changed” and read receipts belong to V-05, not to tour progress.

## Dependencies and completion evidence

Integrate with the authenticated Event foundation after its local verification is stable. Track live Supabase and two-device acceptance separately. This card becomes complete only when implemented screens, automated behavior tests, and a recorded user walkthrough demonstrate the checks above; no completion is claimed here.
