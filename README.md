# HW02: Message Board Vault Hunt (CSC 4360)

Flutter message board backed by Firebase Authentication and Cloud Firestore. A splash screen opens the app, users register and sign in with email/password, each registration writes a Firestore user record, and signed-in users create, read (live stream), update, and delete messages. Security rules enforce ownership.

## Setup
1. Install Flutter and Android tooling, then run `flutter doctor`.
2. Create a Firebase project, enable Email/Password sign-in, and create a Cloud Firestore database.
3. Run `flutterfire configure` (Android selected) to generate `lib/firebase_options.dart`.
4. Deploy rules: `firebase deploy --only firestore:rules`
5. Run: `flutter pub get`, then `flutter run`.
6. Release APK: `flutter build apk --release` (output: `build/app/outputs/flutter-apk/app-release.apk`).

No passwords, tokens, or service-account credentials are committed. Firebase client config is not a secret; Security Rules protect the data.

## Auth flow
- `main.dart` shows a styled splash while `Firebase.initializeApp` runs (retry screen on failure), then opens `AuthGate`.
- `AuthService` owns every Firebase Auth call: register, sign in, sign out, current user, and the `authStateChanges()` stream.
- `AuthGate` listens to the auth stream: signed-out users see login/register, signed-in users go to `ProfileGate`.
- `ProfileGate` checks that the `users/{uid}` document has all five required fields before showing the board. If the account exists but the record is missing, it shows a profile completion form (no second account is created).
- Forms validate input, disable the button while busy, and translate Firebase errors into safe messages.

## Data model
| Document | Fields | Writer | Purpose |
|---|---|---|---|
| `users/{uid}` | uid, firstName, lastName, role, registrationDateTime (server timestamp) | Client, once at registration (uid-keyed) | Private user record, readable only by its owner |
| `messages/{msgId}` | text, authorUid, authorName, createdAt (server timestamp), editedAt (server timestamp, on edit) | Signed-in author (create, and update/delete of own) | Public board content streamed to all signed-in users |

The `role` field is descriptive only and is never used to grant access.

## Services
- `AuthService`: all Firebase Auth calls.
- `UserService`: writes and streams the `users/{uid}` record.
- `BoardService`: every messages call (create, live stream, update, delete). Widgets use its typed methods and a `Message` model.

## CRUD operations
- Create: `BoardService.postMessage` (adds uid-owned, server-timestamped doc)
- Read: `BoardService.messageBoard()` returns a live `snapshots()` stream ordered by `createdAt`
- Update: `BoardService.editMessage` (changes only `text` and `editedAt`)
- Delete: `BoardService.deleteMessage`

The board renders loading, empty ("No messages yet"), and error states. Edit/delete buttons only show on your own messages, but the real enforcement is in the rules.

## Security rules (`firestore.rules`)
- `users/{uid}`: read/write only if `request.auth.uid == uid`.
- `messages`: any signed-in user can read; create requires `authorUid == request.auth.uid`, non-empty string text, and `createdAt == request.time`; update only by the author and only the `text` and `editedAt` fields; delete only by the author.
- Signed-out reads and cross-user writes are denied by Firestore itself, not by hidden UI.

## How to test
1. Register a user, then confirm `users/{uid}` has all five fields in the Firebase console.
2. Post, edit, and delete a message; the board updates from the stream with no refresh.
3. Run a second window (Chrome) as another user; posts appear on the first device live.
4. Signed-out read: `curl "https://firestore.googleapis.com/v1/projects/<project-id>/databases/(default)/documents/messages"` returns PERMISSION_DENIED.
5. Cross-user edit/delete: temporarily force the buttons visible, try another user's message, and observe the permission-denied snackbar.
6. Duplicate submit: tap Send rapidly; exactly one document is created (the button is disabled while the write is pending).

Screenshots and captions for all of these are in the evidence document.
