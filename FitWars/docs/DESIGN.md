# FitWars — Technical Design (App: PulseCombat)

## 1. Architecture Overview

```
┌──────────────────────────────────────────────┐
│           iOS Client (SwiftUI + SpriteKit)    │
│                                               │
│  ┌──────────┐  ┌───────────────────────────┐ │
│  │HealthKit │  │     Stats Engine          │ │
│  │ Manager  │──│  (local XP compute)       │ │
│  └──────────┘  └───────────┬───────────────┘ │
│                             │                 │
│  ┌──────────────────────┐  │                 │
│  │ SpriteKit Battle     │  │                 │
│  │ ├─ CameraController  │  │                 │
│  │ ├─ ParallaxBackground│  │                 │
│  │ ├─ FighterNode ×2    │  │                 │
│  │ ├─ InputManager      │  │                 │
│  │ ├─ AIController      │  │                 │
│  │ ├─ ComboSystem       │  │                 │
│  │ ├─ HUDOverlay        │  │                 │
│  │ ├─ VFXManager        │  │                 │
│  │ └─ SoundManager      │  │                 │
│  └──────────────────────┘  │                 │
│                             │                 │
│  ┌──────────────────────┐  │                 │
│  │   API Service        │──┘                 │
│  │  (Firebase wrapper)  │                    │
│  └──────────┬───────────┘                    │
└─────────────┼────────────────────────────────┘
              │
┌─────────────▼────────────────────────────────┐
│           Firebase Backend                    │
│                                               │
│  ┌─────────────┐  ┌────────────────────────┐ │
│  │ Firestore   │  │ Realtime Database      │ │
│  │ (users,     │  │ (PvP matchmaking,      │ │
│  │  stats,     │  │  game state relay)     │ │
│  │  battles)   │  │                        │ │
│  └─────────────┘  └────────────────────────┘ │
│                                               │
│  ┌─────────────┐  ┌────────────────────────┐ │
│  │ Cloud       │  │ Firebase Auth          │ │
│  │ Functions   │  │ (Sign in with Apple)   │ │
│  └─────────────┘  └────────────────────────┘ │
└───────────────────────────────────────────────┘
```

## 2. App Name Configuration

```swift
enum AppConfig {
    static let appName = "PulseCombat"
    static let dailyXPCap = 100
    static let maxBattlesPerDay = 3
    static let xpPerLevel = 100
}
```

## 3. Client Modules

### 3.1 HealthKit Manager (✅ Implemented)
- Requests permissions: steps, active calories, exercise time, workouts
- Queries daily summaries via `HKStatisticsQueryDescriptor`
- Returns `DailyActivity` struct

### 3.2 Stats Engine (✅ Implemented)
- Converts `DailyActivity` → XP gains with daily caps (100/stat)
- Workout-type-specific XP (strength/stamina/speed/HIIT split)
- **TODO:** Sync derived stats to Firestore

### 3.3 Avatar System (✅ Implemented)
- `AvatarConfig` with customizable features (skin, face, eyes, hair, outfit)
- `AvatarRenderer` (SwiftUI) for dashboard/profile
- Persisted to UserDefaults locally
- **TODO:** Sync to Firestore user profile

### 3.4 Battle System (✅ Implemented)
Full SpriteKit real-time combat with subsystem architecture:

| Subsystem | File | Purpose |
|-----------|------|---------|
| BattleScene | `BattleScene.swift` | Orchestrator — wires all subsystems |
| FighterNode | `FighterNode.swift` | Sprite-based fighter with state machine |
| SpriteAnimator | `SpriteAnimator.swift` | Texture atlas frame playback |
| InputManager | `InputManager.swift` | Virtual joystick + action buttons |
| AIController | `AIController.swift` | Reactive CPU with 3 difficulty levels |
| ComboSystem | `ComboSystem.swift` | Hit chain tracking + damage scaling |
| HUDOverlay | `HUDOverlay.swift` | Health bars, timer, combo counter, special meter |
| VFXManager | `VFXManager.swift` | Particles, screen shake, slow-mo |
| CameraController | `CameraController.swift` | Dynamic framing + zoom |
| ParallaxBackground | `ParallaxBackground.swift` | 3-layer scrolling stage |
| SoundManager | `SoundManager.swift` | Event-driven audio hooks |
| DifficultyLevel | `DifficultyLevel.swift` | AI config per difficulty |

### 3.5 API Service (🔜 Needs Firebase integration)
- Currently uses `MockAPIService` with hardcoded bot opponents
- **TODO:** Replace with real Firebase Firestore reads/writes

## 4. Data Model

### Firestore Collections

**users/{userId}**
```json
{
  "username": "string",
  "avatarConfig": { ... },
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
  "winner": "userId",
  "mode": "ai|pvp",
  "timestamp": "timestamp"
}
```

### Firebase Realtime Database (for PvP)

**matchmaking/{queueId}**
```json
{
  "userId": "string",
  "rank": 0,
  "stats": { "strength": 10, "stamina": 10, "speed": 10 },
  "timestamp": "serverTimestamp"
}
```

**games/{gameId}**
```json
{
  "player1": "userId",
  "player2": "userId",
  "state": "waiting|active|finished",
  "inputs": {
    "player1": [{ "frame": 0, "action": "lightAttack", "direction": 1.0 }],
    "player2": [{ "frame": 0, "action": "block", "direction": -1.0 }]
  },
  "winner": null,
  "createdAt": "serverTimestamp"
}
```

## 5. Real-Time PvP Architecture (Planned)

### Networking Model: Input Relay via Firebase Realtime Database

```
Player A Device                Firebase RTDB              Player B Device
     │                              │                          │
     │── send input (frame N) ─────>│                          │
     │                              │──── relay input ────────>│
     │                              │                          │
     │<──── relay input ────────────│<── send input (frame N) ─│
     │                              │                          │
     │  [both simulate locally]     │   [both simulate locally]│
```

Each client runs the full battle simulation locally. Inputs are relayed through Firebase RTDB with minimal latency. Both clients process the same inputs in the same order to stay in sync.

### Matchmaking Flow
1. Player taps "Find Match" → writes to `matchmaking/` queue in RTDB
2. Cloud Function triggers on new queue entry → finds compatible opponent (rank ± 5 levels)
3. Cloud Function creates `games/{gameId}` with both player IDs
4. Both clients listen to `games/{gameId}` → transition to battle scene
5. Inputs written to `games/{gameId}/inputs/` in real-time
6. Game ends → Cloud Function writes result to Firestore `battles/`

### Latency Handling
- **Input delay:** 2-frame input buffer (33ms at 60fps) to absorb network jitter
- **Rollback:** If remote input arrives late, rewind and resimulate from the divergence frame
- **Timeout:** If no input received for 3 seconds, opponent forfeits
- **Target:** <100ms round-trip for playable experience

### Anti-Cheat for PvP
- Server validates both players' stats before match starts
- Input rate limiting (max 10 inputs/second)
- Game result validated by Cloud Function comparing both clients' reported outcomes
- Flagged if outcomes disagree → replay analysis

## 6. HealthKit Data Flow (✅ Implemented)

```
1. App foreground triggers HealthKitManager
2. Queries last 24h: steps, calories, exercise time, workouts
3. Returns DailyActivity { steps, activeCalories, exerciseMinutes, workouts[] }
4. StatsEngine computes XP by workout type (with daily caps)
5. Stats updated locally
6. TODO: Sync to Firestore
```

## 7. Auth Flow (🔜 Next)

- Firebase Auth with Sign in with Apple (required for App Store)
- Anonymous auth as fallback for onboarding
- Link anonymous → Apple ID when user is ready
- User profile created in Firestore on first auth

## 8. Tech Stack

| Layer | Technology | Status |
|-------|-----------|--------|
| UI | SwiftUI | ✅ |
| Battle Rendering | SpriteKit | ✅ |
| Health | HealthKit | ✅ |
| Auth | Firebase Auth + Sign in with Apple | 🔜 |
| Database | Cloud Firestore | 🔜 |
| PvP Relay | Firebase Realtime Database | 📋 |
| Server Logic | Firebase Cloud Functions (Node.js) | 🔜 |
| Push Notifications | Firebase Cloud Messaging | 📋 |
| Analytics | Firebase Analytics | 📋 |
| Ads | Google AdMob (rewarded) | 📋 |

## 9. Sprite Asset Pipeline

1. Generate base art using AI tools (see `docs/SPRITE_ART_GUIDE.md`)
2. Create sprite sheets per animation state (idle, walk, attack, block, hit, special, knockdown, victory)
3. Export as PNG with transparency, max 512×512 per frame
4. Place in Xcode `.spriteatlas` folders
5. SpriteAnimator auto-detects frames by `{action}_{frame}` naming convention
6. Fallback: colored rectangles when atlas is missing

## 10. File Structure

```
FitWars/
├── AppConfig.swift
├── FitWarsApp.swift
├── Models/
│   ├── Models.swift          (PlayerStats, DailyActivity, WorkoutEntry, CharacterModel)
│   └── AvatarConfig.swift    (avatar customization + persistence)
├── Services/
│   ├── APIService.swift      (mock API, TODO: Firebase)
│   ├── BattleEngine.swift    (auto-resolve fallback)
│   ├── HealthKitManager.swift
│   └── StatsEngine.swift
├── Views/
│   ├── AvatarCustomizerView.swift
│   ├── AvatarRenderer.swift
│   ├── BattleResultView.swift
│   ├── BattleView.swift
│   ├── CharacterSelectionView.swift
│   ├── DashboardView.swift
│   └── ProfileView.swift
├── Battle/
│   ├── BattleScene.swift
│   ├── BattleSpriteView.swift
│   ├── FighterNode.swift
│   ├── SpriteAnimator.swift
│   ├── InputManager.swift
│   ├── AIController.swift
│   ├── ComboSystem.swift
│   ├── HUDOverlay.swift
│   ├── VFXManager.swift
│   ├── CameraController.swift
│   ├── ParallaxBackground.swift
│   ├── SoundManager.swift
│   └── DifficultyLevel.swift
├── Assets.xcassets/
│   └── fighter_default.spriteatlas/
└── docs/
    ├── SPEC.md
    ├── DESIGN.md
    ├── TASKS.md
    └── SPRITE_ART_GUIDE.md
```

## 11. Performance Budget

| Resource | Budget |
|----------|--------|
| Frame rate | 60 FPS minimum on iPhone 13 |
| Active emitters | Max 8 simultaneous |
| Texture memory | Max 200 MB during battle |
| Audio channels | Max 4 concurrent SFX + 1 music |
| Sprite frame size | Max 512×512 per frame |
| PvP input latency | <100ms round-trip target |
