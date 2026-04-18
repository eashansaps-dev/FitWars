# Design Document

## Overview

This design adds Firebase Authentication, Firestore user profiles, stat synchronization, and battle result storage to PulseCombat. The architecture introduces two new services (AuthManager, FirestoreService) that integrate with the existing StatsEngine, AvatarConfig, and APIService protocol. A Cloud Function provides server-side stat validation to prevent cheating.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    FitWarsApp (Entry Point)                  │
│  ┌──────────────┐                                           │
│  │ AuthManager   │◄── Firebase Auth state listener          │
│  │ (singleton)   │    Sign in with Apple / Anonymous        │
│  └──────┬───────┘                                           │
│         │ auth state                                        │
│         ▼                                                   │
│  ┌──────────────────────────────────────────────────┐       │
│  │              Authenticated App Shell              │       │
│  │                                                   │       │
│  │  ┌──────────────┐  ┌────────────────────────┐    │       │
│  │  │ StatsEngine   │──│ FirestoreService       │    │       │
│  │  │ (local XP)    │  │ (Firestore read/write) │    │       │
│  │  └──────────────┘  │ implements APIService   │    │       │
│  │                     └────────────┬───────────┘    │       │
│  │  ┌──────────────┐               │                 │       │
│  │  │ AvatarConfig  │──── sync ────┘                 │       │
│  │  │ (UserDefaults  │                               │       │
│  │  │  + Firestore)  │                               │       │
│  │  └──────────────┘                                 │       │
│  └──────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Firebase Backend                         │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Auth          │  │ Firestore    │  │ Cloud        │      │
│  │ (Apple +      │  │ users/       │  │ Functions    │      │
│  │  Anonymous)   │  │ stats/       │  │ (validate    │      │
│  │               │  │ battles/     │  │  stat caps)  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

## Components

### Component 1: AuthManager

**File:** `FitWars/Services/AuthManager.swift`

**Purpose:** Singleton `@Observable` class that wraps Firebase Auth. Manages sign-in flows (anonymous + Apple), auth state observation, credential linking, and sign-out.

**Key interfaces:**
```swift
@Observable
final class AuthManager {
    enum AuthState {
        case unknown      // initial state, checking session
        case signedOut    // no auth session
        case anonymous(userId: String)
        case authenticated(userId: String, email: String?)
    }
    
    private(set) var authState: AuthState = .unknown
    var currentUserId: String?  // convenience accessor
    var isAuthenticated: Bool   // true for anonymous or authenticated
    
    func signInAnonymously() async throws
    func signInWithApple() async throws
    func linkAppleCredential() async throws  // link Apple to anonymous
    func signOut() throws
}
```

**Behavior:**
- On init, attaches a `Auth.auth().addStateDidChangeListener` to track auth state changes
- Publishes `authState` as an observable property so SwiftUI views react to changes
- `signInAnonymously()` calls `Auth.auth().signInAnonymously()` and transitions to `.anonymous`
- `signInWithApple()` uses `ASAuthorizationController` to get Apple credential, then `Auth.auth().signIn(with: oAuthCredential)`
- `linkAppleCredential()` calls `Auth.auth().currentUser?.link(with: oAuthCredential)` to upgrade anonymous → Apple
- If linking fails with `credentialAlreadyInUse`, surfaces the error for UI handling
- `signOut()` calls `Auth.auth().signOut()`, clears local caches, transitions to `.signedOut`

**Dependencies:** FirebaseAuth, AuthenticationServices

### Component 2: FirestoreService

**File:** `FitWars/Services/FirestoreService.swift`

**Purpose:** Handles all Firestore read/write operations. Implements the existing `APIService` protocol to replace `MockAPIService`. Manages user profiles, stat documents, and battle records.

**Key interfaces:**
```swift
final class FirestoreService: APIService {
    private let db = Firestore.firestore()
    
    // User Profile
    func createUserProfile(userId: String, username: String, avatarConfig: AvatarConfig) async throws
    func fetchUserProfile(userId: String) async throws -> UserProfile
    func updateAvatarConfig(userId: String, avatarConfig: AvatarConfig) async throws
    
    // Stats
    func syncStats(userId: String, stats: PlayerStats) async throws
    func fetchStats(userId: String) async throws -> PlayerStats?
    
    // APIService protocol
    func fetchRandomOpponent() async -> Opponent
    func submitBattleResult(_ result: BattleResult) async
}
```

**Behavior:**
- `createUserProfile` writes to `users/{userId}` with all default fields and server timestamp
- `updateAvatarConfig` merges avatar config into the user profile document
- `syncStats` writes to `stats/{userId}` with derived stats only (strength, stamina, speed, totalXP, lastUpdated)
- `fetchRandomOpponent` queries `users` collection, excludes current user, picks a random result. Falls back to bot opponents from MockAPIService data if no real users found
- `submitBattleResult` writes to `battles/{auto-id}` with player IDs, winner, mode, and server timestamp
- All writes use Firestore offline persistence — writes are cached locally and synced when online

**Dependencies:** FirebaseFirestore

### Component 3: UserProfile Model

**File:** `FitWars/Models/UserProfile.swift`

**Purpose:** Codable model representing the Firestore user profile document. Used for serialization/deserialization between the app and Firestore.

**Key interfaces:**
```swift
struct UserProfile: Codable {
    let userId: String
    var username: String
    var avatarConfig: AvatarConfig
    var level: Int
    var totalXP: Int
    var rank: Int
    var streak: Int
    var lastActiveDate: Date
    var createdAt: Date
}
```

### Component 4: Cloud Function — Stat Validator

**File:** `functions/index.js` (Firebase Cloud Functions project, separate from iOS)

**Purpose:** Firestore trigger that validates stat updates before they are committed. Prevents cheating by enforcing daily XP caps.

**Behavior:**
- Triggers on `stats/{userId}` document writes (onCreate/onUpdate)
- Compares new stat values against previous values (or defaults for new documents)
- Calculates per-stat delta and total delta
- Rejects if any single stat gain > 100 (Daily_XP_Cap) in 24 hours
- Rejects if total gain > 300 (3× Daily_XP_Cap) in 24 hours
- On rejection: reverts the document to previous values and logs the violation
- Validation uses the `lastUpdated` timestamp to determine the 24-hour window

### Component 5: Modified FitWarsApp Entry Point

**File:** `FitWars/FitWarsApp.swift` (modified)

**Purpose:** Integrate AuthManager into the app lifecycle. Gate the main app behind auth state. Trigger anonymous auth on first launch.

**Changes:**
- Add `@State private var authManager = AuthManager()` 
- Replace the current `if hasCompletedOnboarding` check with auth-state-aware routing:
  - `.unknown` → loading/splash screen
  - `.signedOut` → SignInView
  - `.anonymous` / `.authenticated` → onboarding or MainTabView based on `hasCompletedOnboarding`
- Pass `authManager` into the environment for child views
- On first launch (no existing session), auto-trigger `authManager.signInAnonymously()`

### Component 6: SignInView

**File:** `FitWars/Views/SignInView.swift`

**Purpose:** Presents Sign in with Apple button. Shown when user is signed out or as an upgrade prompt for anonymous users.

**Behavior:**
- Displays the `SignInWithAppleButton` from AuthenticationServices
- On tap, calls `authManager.signInWithApple()` or `authManager.linkAppleCredential()` depending on current auth state
- Shows error alerts for credential conflicts or failures
- Minimal UI — Apple's HIG-compliant sign-in button with app branding

### Component 7: Modified ProfileView

**File:** `FitWars/Views/ProfileView.swift` (modified)

**Purpose:** Add account management section showing auth state, upgrade prompt for anonymous users, and sign-out button.

**Changes:**
- Add a new "Account" section to the List
- If anonymous: show "Upgrade to Apple ID" button that triggers `linkAppleCredential()`
- If authenticated: show email (if available) and "Sign Out" button
- Sign out calls `authManager.signOut()` which navigates away via auth state change

### Component 8: Modified StatsEngine Integration

**File:** `FitWars/Services/StatsEngine.swift` (modified)

**Purpose:** After `calculate(from:)` computes stats, trigger a Firestore sync.

**Changes:**
- Add a callback or use the caller (MainTabView) to trigger `firestoreService.syncStats()` after `engine.calculate()` completes
- The sync is fire-and-forget from the UI perspective — Firestore offline persistence handles retries
- On app launch, fetch remote stats and reconcile: use `max(local, remote)` for each stat to prevent data loss

### Component 9: Modified AvatarConfig Persistence

**File:** `FitWars/Models/AvatarConfig.swift` (modified)

**Purpose:** Extend the existing `save()` method to also sync to Firestore.

**Changes:**
- Keep the existing `UserDefaults` save as local cache
- Add a `save(to firestoreService: FirestoreService, userId: String)` method or have the caller trigger Firestore sync after local save
- Preferred approach: keep AvatarConfig's `save()` as UserDefaults-only, and have the view layer call `firestoreService.updateAvatarConfig()` separately. This keeps AvatarConfig decoupled from Firebase.

### Component 10: Firestore Offline Persistence Configuration

**File:** `FitWars/FitWarsApp.swift` (modified)

**Purpose:** Enable Firestore offline persistence at app startup.

**Changes:**
- Firestore offline persistence is enabled by default in Firebase iOS SDK, so no explicit configuration is needed
- Verify that `FirebaseApp.configure()` is called before any Firestore access (already the case)
- Firestore automatically caches reads and queues writes when offline

## Data Model

### Firestore Collections

**`users/{userId}`**
```
{
  username: string
  avatarConfig: {
    name: string
    skinTone: { red: number, green: number, blue: number }
    faceShape: string
    eyeStyle: string
    hairStyle: string
    hairColor: { red: number, green: number, blue: number }
    outfit: string
  }
  level: number
  totalXP: number
  rank: number
  streak: number
  lastActiveDate: timestamp
  createdAt: timestamp
}
```

**`stats/{userId}`**
```
{
  strength: number
  stamina: number
  speed: number
  totalXP: number
  lastUpdated: timestamp
}
```

**`battles/{auto-id}`**
```
{
  player1: string (userId)
  player2: string (userId or botId)
  winner: string (userId or botId)
  mode: string ("ai" | "pvp")
  timestamp: server timestamp
}
```

## Correctness Properties

### Property 1: Credential Linking Preserves User Data (Req 2.4)
- **Type:** Invariant
- **Statement:** For any user with an anonymous account containing a User_Profile and Stat_Document, after successful Credential_Linking to Apple_Auth, the User_Profile and Stat_Document remain identical (same userId, same field values)
- **Tested by:** Verify profile and stats before and after linking are equal

### Property 2: Firestore Profile Reconciliation Prefers Newer Data (Req 4.4)
- **Type:** Metamorphic
- **Statement:** For any two versions of a User_Profile (local and remote) with different timestamps, reconciliation always selects the version with the more recent timestamp
- **Tested by:** Generate random profile pairs with different timestamps, verify the newer one is always chosen

### Property 3: Only Derived Stats Leave the Device (Req 5.3)
- **Type:** Invariant
- **Statement:** For any stat sync payload sent to Firestore, the payload contains only the fields: strength, stamina, speed, totalXP, and lastUpdated. No raw HealthKit data (steps, calories, exerciseMinutes, workout details) is present
- **Tested by:** Intercept/mock Firestore writes and verify payload keys

### Property 4: Stat Validation Enforces Daily Caps (Req 6.2, 6.3)
- **Type:** Error Condition
- **Statement:** For any stat update where a single stat gain exceeds 100 or total gain exceeds 300 in a 24-hour window, the Cloud_Function rejects the update
- **Tested by:** Generate random stat deltas, verify all exceeding caps are rejected and all within caps are accepted

### Property 5: Opponent Fetch Never Returns Current User (Req 7.3)
- **Type:** Invariant
- **Statement:** For any call to fetchRandomOpponent, the returned Opponent's ID is never equal to the current authenticated user's ID
- **Tested by:** Populate Firestore with test users including the current user, call fetchRandomOpponent many times, verify current user is never returned

### Property 6: Stat Reconciliation Uses Max Values (Req 9.5)
- **Type:** Invariant
- **Statement:** For any two stat sets (local and remote), the reconciled stat set has each field value equal to max(local_field, remote_field). The reconciled strength is always >= both local and remote strength, and the same for stamina, speed, and totalXP
- **Tested by:** Generate random stat pairs, verify reconciled values satisfy the max property

## Handling Ambiguity

1. **Avatar sync timing (Req 4.2 "within 5 seconds"):** Implemented as a debounced write — after the user finishes editing avatar config, a 1-second debounce triggers the Firestore sync. The 5-second requirement is met by the debounce + Firestore write latency.

2. **Stat reconciliation strategy (Req 9.5):** Using `max(local, remote)` per stat field. This prevents data loss but could theoretically allow a stat to be higher than expected if both local and remote advanced independently. This is acceptable because stats only increase (XP is additive) and the Cloud Function caps prevent unreasonable values.

3. **Bot fallback threshold (Req 7.4):** "Fewer than 1 real opponent" means the Firestore query returned 0 results (excluding current user). The query fetches up to 10 random users and picks one. If the collection has only the current user, it falls back to bots.

4. **Cloud Function rejection behavior (Req 6.4):** The Cloud Function reverts the document to its previous state and returns an error. The iOS app catches this error via the Firestore write's completion handler and shows a non-blocking alert. The user's local stats are not rolled back — they will be re-validated on the next sync attempt.

5. **Offline battle opponents (Req 9.3):** When offline, `fetchRandomOpponent` will use Firestore's cached data if available. If no cached opponents exist, it falls back to the hardcoded bot list from MockAPIService.
