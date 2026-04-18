# Tasks

## Task 1: Create AuthManager Service
- [x] 1.1 Create `FitWars/Services/AuthManager.swift` with `@Observable` class, `AuthState` enum (unknown, signedOut, anonymous, authenticated), and observable `authState` property
- [x] 1.2 Implement `signInAnonymously()` using `Auth.auth().signInAnonymously()` and transition to `.anonymous(userId:)` state
- [x] 1.3 Implement Firebase Auth state listener in `init()` using `Auth.auth().addStateDidChangeListener` to update `authState` on auth changes and restore sessions on app launch
- [x] 1.4 Implement `signInWithApple()` using `ASAuthorizationController` to get Apple credential, then `Auth.auth().signIn(with:)` to authenticate with Firebase
- [x] 1.5 Implement `linkAppleCredential()` to upgrade anonymous accounts via `Auth.auth().currentUser?.link(with:)`, handling `credentialAlreadyInUse` error
- [x] 1.6 Implement `signOut()` that calls `Auth.auth().signOut()`, clears local caches (UserDefaults avatar, etc.), and transitions to `.signedOut`

## Task 2: Create FirestoreService
- [x] 2.1 Create `FitWars/Services/FirestoreService.swift` with Firestore database reference and collection path constants (`users`, `stats`, `battles`)
- [x] 2.2 Implement `createUserProfile(userId:username:avatarConfig:)` that writes a new document to `users/{userId}` with all default fields (level 1, totalXP 0, rank 0, streak 0, timestamps)
- [x] 2.3 Implement `fetchUserProfile(userId:)` that reads from `users/{userId}` and decodes into a `UserProfile` model
- [x] 2.4 Implement `updateAvatarConfig(userId:avatarConfig:)` that merges the avatar config fields into the existing `users/{userId}` document
- [x] 2.5 Implement `syncStats(userId:stats:)` that writes strength, stamina, speed, totalXP, and lastUpdated timestamp to `stats/{userId}`
- [x] 2.6 Implement `fetchStats(userId:)` that reads from `stats/{userId}` and returns a `PlayerStats` instance

## Task 3: Create UserProfile Model
- [x] 3.1 Create `FitWars/Models/UserProfile.swift` with `Codable` struct containing userId, username, avatarConfig, level, totalXP, rank, streak, lastActiveDate, and createdAt fields

## Task 4: Implement APIService Protocol in FirestoreService
- [x] 4.1 Make `FirestoreService` conform to `APIService` protocol
- [x] 4.2 Implement `fetchRandomOpponent()` that queries the `users` and `stats` collections, excludes the current user, and returns a random real player as an `Opponent`
- [x] 4.3 Implement bot fallback in `fetchRandomOpponent()` — if no real opponents are found in Firestore, return a bot from the existing MockAPIService data
- [x] 4.4 Implement `submitBattleResult(_:)` that writes a battle record to `battles/{auto-id}` with player IDs, winner, mode ("ai"/"pvp"), and server timestamp

## Task 5: Integrate AuthManager into App Entry Point
- [x] 5.1 Modify `FitWarsApp.swift` to create `AuthManager` as `@State` and pass it into the environment
- [x] 5.2 Replace the current `hasCompletedOnboarding` routing with auth-state-aware routing: `.unknown` → loading view, `.signedOut` → SignInView, `.anonymous`/`.authenticated` → onboarding or MainTabView
- [x] 5.3 Add auto-trigger for `signInAnonymously()` on first launch when no existing auth session is detected
- [x] 5.4 Create a User_Profile in Firestore after successful first-time authentication (anonymous or Apple)

## Task 6: Create SignInView
- [x] 6.1 Create `FitWars/Views/SignInView.swift` with `SignInWithAppleButton` from AuthenticationServices
- [x] 6.2 Wire the button to call `authManager.signInWithApple()` or `authManager.linkAppleCredential()` based on current auth state
- [x] 6.3 Add error handling UI (alert) for credential conflicts and sign-in failures

## Task 7: Modify ProfileView for Account Management
- [x] 7.1 Add an "Account" section to ProfileView's List
- [x] 7.2 Show "Upgrade to Apple ID" button with Sign in with Apple when user is anonymous
- [x] 7.3 Show associated email and "Sign Out" button when user is authenticated via Apple
- [x] 7.4 Wire sign-out button to `authManager.signOut()`

## Task 8: Integrate Stat Sync with StatsEngine
- [x] 8.1 Modify `MainTabView` to call `firestoreService.syncStats()` after `engine.calculate()` completes, passing the current user ID and computed stats
- [x] 8.2 On app launch (in MainTabView's `.task`), fetch remote stats via `firestoreService.fetchStats()` and reconcile with local stats using `max(local, remote)` per field
- [x] 8.3 Ensure stat sync is fire-and-forget from the UI — Firestore offline persistence handles retries automatically

## Task 9: Integrate Avatar Config Sync with Firestore
- [x] 9.1 After avatar config is saved in `AvatarCustomizerView`, call `firestoreService.updateAvatarConfig()` to sync to Firestore
- [x] 9.2 On app launch, fetch avatar config from Firestore and reconcile with local UserDefaults cache (prefer Firestore if timestamps differ)
- [x] 9.3 Keep existing `AvatarConfig.save()` to UserDefaults as local cache — do not remove it

## Task 10: Replace MockAPIService with FirestoreService
- [x] 10.1 Update `BattleView.swift` to use `FirestoreService` instead of `MockAPIService` for the `api` property
- [x] 10.2 Pass `FirestoreService` instance from the environment or inject it into BattleView
- [x] 10.3 Verify bot fallback works when Firestore has no other users

## Task 11: Create Cloud Function for Stat Validation
- [x] 11.1 Create `functions/index.js` with a Firestore trigger on `stats/{userId}` document writes
- [x] 11.2 Implement validation logic: reject if any single stat gain > 100 (Daily_XP_Cap) in 24 hours
- [x] 11.3 Implement validation logic: reject if total XP gain > 300 (3× Daily_XP_Cap) in 24 hours
- [x] 11.4 On rejection, revert the document to previous values and log the violation with userId and attempted values
- [x] 11.5 Create `functions/package.json` with firebase-functions and firebase-admin dependencies

## Task 12: Verify Offline Support
- [x] 12.1 Confirm Firestore offline persistence is enabled by default (no explicit config needed in Firebase iOS SDK)
- [x] 12.2 Test that cached User_Profile and Stat_Document data is readable when offline
- [x] 12.3 Test that battle against bots works offline using cached or fallback data
- [x] 12.4 Test that pending Firestore writes sync automatically when connectivity is restored
