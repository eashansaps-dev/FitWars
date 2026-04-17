# FitWars — Technical Design (App: PulseCombat)

## 1. Architecture Overview

```
┌──────────────────────────────────────────┐
│           iOS Client (SwiftUI + SpriteKit)│
│                                           │
│  ┌──────────┐  ┌───────────────────────┐ │
│  │HealthKit │  │    Stats Engine       │ │
│  │ Manager  │──│  (local compute)      │ │
│  └──────────┘  └───────────┬───────────┘ │
│                             │             │
│  ┌──────────┐  ┌───────────▼───────────┐ │
│  │SpriteKit │  │    API Service        │ │
│  │Battle    │  │  (Firebase wrapper)   │ │
│  │Scene     │  └───────────┬───────────┘ │
│  └──────────┘              │             │
└────────────────────────────┼─────────────┘
                             │
              ┌──────────────▼──────────────┐
              │      Firebase Backend        │
              │                              │
              │  ┌────────────────────────┐  │
              │  │   Firestore DB         │  │
              │  │  (users, stats,        │  │
              │  │   battles, characters) │  │
              │  └────────────────────────┘  │
              │                              │
              │  ┌────────────────────────┐  │
              │  │  Cloud Functions       │  │
              │  │  (battle resolve,      │  │
              │  │   leaderboard)         │  │
              │  └────────────────────────┘  │
              │                              │
              │  ┌────────────────────────┐  │
              │  │   Firebase Auth        │  │
              │  └────────────────────────┘  │
              └──────────────────────────────┘
```

## 2. App Name Configuration

All user-facing references to the app name go through a single constant:

```swift
enum AppConfig {
    static let appName = "PulseCombat"
}
```

Changing the name later = update this constant + App Store metadata. No string literals scattered through code.

## 3. Client Modules

### 3.1 HealthKit Manager
- Requests permissions: steps, active calories, workout sessions
- Queries daily summaries via `HKStatisticsCollectionQuery`
- Runs on app foreground + background refresh
- Returns normalized `DailyActivity` struct

### 3.2 Stats Engine
- Converts `DailyActivity` → XP gains (with daily caps)
- Maintains local stat cache
- Syncs derived stats to Firebase on each calculation
- **Key rule:** Raw health data stays on device. Only computed stats are sent to backend.

### 3.3 Character System
- User selects character model at onboarding (male/female fighter)
- Character choice stored in user profile (Firestore + local)
- Character model determines which sprite sheet to load — nothing else
- Stats are identical regardless of character choice

```swift
enum CharacterModel: String, Codable, CaseIterable {
    case maleDefault = "fighter_male_01"
    case femaleDefault = "fighter_female_01"
    // Future: additional models added here
}
```

### 3.4 SpriteKit Battle Scene (Phase 2)
- `SKScene` embedded in SwiftUI via `SpriteView`
- Loads character sprite sheets based on each player's `CharacterModel`
- Plays back server-resolved battle as animated sequence
- MVP fallback: static result screen with stat comparison

### 3.5 API Service
- Thin wrapper around Firebase SDK
- Handles auth, Firestore reads/writes, Cloud Function calls
- Offline support via Firestore local cache

## 4. Data Model

### Firestore Collections

**users/{userId}**
```json
{
  "username": "string",
  "characterModel": "fighter_male_01",
  "level": 1,
  "totalXP": 0,
  "rank": 0,
  "createdAt": "timestamp",
  "streak": 0,
  "lastActiveDate": "date"
}
```

**stats/{userId}**
```json
{
  "strength": 10,
  "stamina": 10,
  "speed": 10,
  "lastUpdated": "timestamp"
}
```

**battles/{battleId}**
```json
{
  "player1": "userId",
  "player2": "userId",
  "player1Score": 42.3,
  "player2Score": 38.7,
  "winner": "userId",
  "timestamp": "timestamp"
}
```

**leaderboard/{userId}**
```json
{
  "username": "string",
  "rank": 1,
  "wins": 15,
  "losses": 3,
  "weekStart": "date"
}
```

## 5. Battle Resolution (Cloud Function)

```
function resolveBattle(player1Stats, player2Stats):
    score1 = (p1.strength * 0.4) + (p1.stamina * 0.3) + (p1.speed * 0.3) + random(0, 5)
    score2 = (p2.strength * 0.4) + (p2.stamina * 0.3) + (p2.speed * 0.3) + random(0, 5)
    winner = score1 > score2 ? player1 : player2
    return { winner, score1, score2 }
```

Battle resolution runs server-side to prevent client manipulation.

## 6. HealthKit Data Flow

```
1. App foreground / background refresh triggers
2. HealthKitManager queries last 24h:
   - stepCount
   - activeEnergyBurned
   - appleExerciseTime
3. Returns DailyActivity { steps, calories, workoutMinutes, date }
4. StatsEngine computes XP:
   - speedXP = min(steps / 1000 * 10, 100)
   - staminaXP = min(workoutMinutes / 10 * 15, 100)
   - strengthXP = min(calories / 100 * 10, 100)
5. Stats updated locally + synced to Firestore
```

## 7. Auth Flow

- Firebase Auth with Sign in with Apple (required for App Store)
- Anonymous auth as fallback for onboarding
- Link anonymous → Apple ID when user is ready

## 8. Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | SwiftUI |
| Battle Rendering | SpriteKit (Phase 2) |
| Health | HealthKit |
| Auth | Firebase Auth + Sign in with Apple |
| Database | Cloud Firestore |
| Server Logic | Firebase Cloud Functions (Node.js) |
| Push Notifications | Firebase Cloud Messaging |
| Analytics | Firebase Analytics |
| Ads | Google AdMob (rewarded) |

## 9. Sprite Asset Pipeline

1. Generate base character art (AI tools or commission artist)
2. Create sprite sheets: idle (4 frames), attack (6 frames), defend (4 frames), hit (4 frames)
3. Export as PNG atlas per character model
4. Load into SpriteKit `SKTextureAtlas`
5. Each `CharacterModel` enum case maps to an atlas name

**MVP:** Single static image per character. Animated sprites added in Phase 2.

## 10. Anti-Cheat

- Daily XP caps (100 per stat) enforced client-side AND server-side
- Server validates stat deltas — reject if daily gain exceeds caps
- Flag accounts with abnormal spikes (e.g., 50k steps in 1 hour)
- Weight workout-derived XP higher than step-only XP

## 11. Offline Support

- Firestore offline persistence enabled
- Stats computed locally even without network
- Battles require network (server-resolved)
- Sync queue for pending stat updates
