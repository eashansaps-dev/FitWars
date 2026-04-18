# Requirements Document

## Introduction

This feature integrates Firebase Authentication, Firestore user profiles, and stat synchronization into PulseCombat (FitWars). Currently, all player data lives in memory or UserDefaults with no backend persistence and no auth flow. This feature adds Sign in with Apple as the primary auth method (required for App Store), anonymous auth for immediate onboarding, Firestore-backed user profiles and stat storage, server-side stat validation via Cloud Functions, real opponent matchmaking from Firestore, battle result persistence, and offline support via Firestore offline persistence.

## Glossary

- **AuthManager**: The singleton service responsible for managing Firebase Authentication state, sign-in flows, and credential linking
- **FirestoreService**: The service responsible for all Firestore read/write operations including user profiles, stats, and battle results
- **User_Profile**: A Firestore document in the `users/{userId}` collection containing username, avatar config, level, XP, rank, streak, and timestamps
- **Stat_Document**: A Firestore document in the `stats/{userId}` collection containing derived strength, stamina, and speed values
- **Battle_Record**: A Firestore document in the `battles/{battleId}` collection containing participants, winner, mode, and timestamp
- **StatsEngine**: The existing local service that converts HealthKit DailyActivity into XP gains and derived stats
- **Anonymous_Auth**: A Firebase Authentication method that creates a temporary account without credentials, allowing immediate app usage
- **Apple_Auth**: Sign in with Apple authentication, the primary credential method required for App Store compliance
- **Credential_Linking**: The Firebase Auth process of upgrading an Anonymous_Auth account by attaching Apple_Auth credentials
- **Daily_XP_Cap**: The maximum XP gain per stat per day, currently set to 100 in AppConfig
- **Sync_Queue**: A local persistence layer that buffers Firestore write operations when the device is offline
- **Cloud_Function**: A Firebase Cloud Function that runs server-side to validate stat updates before committing them to Firestore
- **Derived_Stats**: The strength, stamina, and speed values computed by StatsEngine from HealthKit data — raw health data never leaves the device

## Requirements

### Requirement 1: Anonymous Authentication on First Launch

**User Story:** As a new player, I want to start playing PulseCombat immediately without creating an account, so that I can experience the game before committing to sign-up.

#### Acceptance Criteria

1. WHEN the app launches for the first time with no existing auth session, THE AuthManager SHALL create an Anonymous_Auth session via Firebase Authentication
2. WHEN Anonymous_Auth succeeds, THE AuthManager SHALL store the Firebase user ID and auth state locally
3. WHEN Anonymous_Auth succeeds, THE FirestoreService SHALL create a User_Profile document in Firestore with default values and the anonymous user ID
4. IF Anonymous_Auth fails due to network unavailability, THEN THE AuthManager SHALL retry authentication when network connectivity is restored
5. WHILE the user is authenticated via Anonymous_Auth, THE app SHALL provide full access to all gameplay features including battles, stat tracking, and avatar customization

### Requirement 2: Sign in with Apple Authentication

**User Story:** As a player, I want to sign in with my Apple ID, so that my game progress is tied to a persistent identity and I can recover my account on a new device.

#### Acceptance Criteria

1. WHEN the user taps the Sign in with Apple button, THE AuthManager SHALL initiate the Apple Sign-In flow using AuthenticationServices
2. WHEN Apple Sign-In completes with valid credentials, THE AuthManager SHALL authenticate with Firebase using the Apple ID token
3. WHEN a user with an existing Anonymous_Auth session completes Apple Sign-In, THE AuthManager SHALL link the Apple credential to the existing anonymous account via Credential_Linking
4. WHEN Credential_Linking succeeds, THE FirestoreService SHALL retain the existing User_Profile and Stat_Document without data loss
5. IF Credential_Linking fails because the Apple ID is already associated with a different account, THEN THE AuthManager SHALL present an error message explaining the conflict and offer to sign in to the existing account instead
6. IF Apple Sign-In is cancelled by the user, THEN THE AuthManager SHALL maintain the current auth session without changes

### Requirement 3: Auth State Management

**User Story:** As a player, I want the app to remember my sign-in state and react to auth changes, so that I have a seamless experience across app launches.

#### Acceptance Criteria

1. THE AuthManager SHALL listen to Firebase Auth state changes and publish the current auth state to the app via an observable property
2. WHEN the app launches with a previously authenticated session, THE AuthManager SHALL restore the session without requiring user interaction
3. WHEN the user signs out, THE AuthManager SHALL clear the local auth state, remove cached user data, and navigate to the sign-in screen
4. WHEN a Firebase Auth token refresh fails, THE AuthManager SHALL attempt re-authentication and notify the user only if re-authentication also fails
5. WHILE the user is not authenticated, THE app SHALL display the sign-in screen and restrict access to gameplay features

### Requirement 4: User Profile Creation and Persistence

**User Story:** As a player, I want my profile (username, avatar, level, rank) stored in the cloud, so that my identity persists across devices and sessions.

#### Acceptance Criteria

1. WHEN a new user authenticates for the first time, THE FirestoreService SHALL create a User_Profile document containing username, avatar config, level (1), totalXP (0), rank (0), streak (0), lastActiveDate, and createdAt timestamp
2. WHEN the user modifies their AvatarConfig, THE FirestoreService SHALL sync the updated avatar config to the User_Profile document in Firestore within 5 seconds
3. WHEN the user modifies their AvatarConfig, THE app SHALL continue to save the config to UserDefaults as a local cache
4. WHEN the app launches with an authenticated user, THE FirestoreService SHALL fetch the User_Profile from Firestore and reconcile it with the local UserDefaults cache, preferring the Firestore version if timestamps differ
5. THE User_Profile document SHALL use the Firebase Auth user ID as the document ID in the `users` collection

### Requirement 5: Stat Synchronization to Firestore

**User Story:** As a player, I want my fitness-derived stats synced to the cloud, so that opponents see my real stats and my progress is preserved.

#### Acceptance Criteria

1. WHEN StatsEngine completes an XP calculation from HealthKit data, THE FirestoreService SHALL write the updated Derived_Stats (strength, stamina, speed) and totalXP to the Stat_Document in Firestore
2. THE FirestoreService SHALL include a lastUpdated timestamp with each Stat_Document write
3. THE app SHALL send only Derived_Stats to Firestore and SHALL keep raw HealthKit data (steps, calories, exercise minutes, workout details) on the device
4. WHEN the app launches with an authenticated user, THE FirestoreService SHALL fetch the Stat_Document from Firestore and use it to initialize StatsEngine if the Firestore data is more recent than local data
5. IF a stat sync write fails, THEN THE FirestoreService SHALL enqueue the update in the Sync_Queue for retry when connectivity is restored

### Requirement 6: Server-Side Stat Validation

**User Story:** As a player, I want the game to prevent cheating, so that battles are fair and stat-based rankings are trustworthy.

#### Acceptance Criteria

1. WHEN the FirestoreService writes a stat update to Firestore, THE Cloud_Function SHALL validate the update before committing it
2. THE Cloud_Function SHALL reject a stat update if any single stat gain exceeds the Daily_XP_Cap (100 XP) in a 24-hour period
3. THE Cloud_Function SHALL reject a stat update if the total XP gain across all stats exceeds 3 times the Daily_XP_Cap (300 XP) in a 24-hour period
4. IF the Cloud_Function rejects a stat update, THEN THE Cloud_Function SHALL return an error code and THE app SHALL display a message indicating the update was rejected
5. THE Cloud_Function SHALL log rejected stat updates with the user ID and attempted values for audit purposes

### Requirement 7: Firebase-Backed API Service

**User Story:** As a player, I want to fight real opponents from the player base, so that battles feel competitive and dynamic.

#### Acceptance Criteria

1. THE FirestoreService SHALL implement the APIService protocol, replacing MockAPIService as the default implementation
2. WHEN fetchRandomOpponent is called, THE FirestoreService SHALL query the `users` and `stats` collections in Firestore to return a real player as an Opponent
3. WHEN fetchRandomOpponent is called, THE FirestoreService SHALL exclude the current user from opponent results
4. WHEN fetchRandomOpponent finds fewer than 1 real opponent in Firestore, THE FirestoreService SHALL fall back to returning a bot opponent from the existing mock data
5. WHEN fetchRandomOpponent selects a real opponent, THE FirestoreService SHALL return the opponent's username, avatar config, and current stats from Firestore

### Requirement 8: Battle Result Storage

**User Story:** As a player, I want my battle history recorded, so that I can track my wins and losses and the game can use it for matchmaking.

#### Acceptance Criteria

1. WHEN a battle concludes, THE FirestoreService SHALL create a Battle_Record document in the `battles` collection
2. THE Battle_Record SHALL contain the player user ID, opponent user ID (or bot ID), winner user ID, battle mode (ai or pvp), and a server timestamp
3. WHEN submitBattleResult is called with a bot opponent, THE FirestoreService SHALL store the bot identifier in the opponent field of the Battle_Record
4. IF writing a Battle_Record fails due to network unavailability, THEN THE FirestoreService SHALL enqueue the write in the Sync_Queue for retry when connectivity is restored

### Requirement 9: Offline Support

**User Story:** As a player, I want to keep playing even without internet, so that my workout progress and battles are not blocked by connectivity issues.

#### Acceptance Criteria

1. THE app SHALL enable Firestore offline persistence at app startup so that cached data is available when the device is offline
2. WHILE the device is offline, THE app SHALL allow the user to view their cached User_Profile and Stat_Document data
3. WHILE the device is offline, THE app SHALL allow the user to complete battles against bot opponents using locally cached data
4. WHEN the device regains network connectivity, THE FirestoreService SHALL automatically sync all pending Firestore writes from the Sync_Queue
5. WHEN the device regains network connectivity after an offline session, THE FirestoreService SHALL reconcile local stat data with the Firestore Stat_Document, preferring the higher value for each stat to prevent data loss

### Requirement 10: Sign-Out and Account Management

**User Story:** As a player, I want to sign out or manage my account from the profile screen, so that I have control over my identity in the app.

#### Acceptance Criteria

1. WHEN the user taps Sign Out on the profile screen, THE AuthManager SHALL sign out from Firebase Auth and clear the local session
2. WHEN the user signs out, THE app SHALL navigate to the sign-in screen and restrict access to gameplay features
3. WHILE the user is authenticated via Anonymous_Auth, THE profile screen SHALL display a prompt to upgrade to Apple_Auth with a Sign in with Apple button
4. WHILE the user is authenticated via Apple_Auth, THE profile screen SHALL display the associated Apple ID email (if available) and a Sign Out button
