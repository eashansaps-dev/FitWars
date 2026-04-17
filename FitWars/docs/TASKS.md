# FitWars — Task Breakdown (App: PulseCombat)

## Phase 1: Foundation (Week 1-2)

- [x] Create project spec and design docs
- [ ] Create Xcode project (SwiftUI, iOS 17+)
- [ ] Set up project structure (MVVM + `AppConfig` for app name)
- [ ] Add Firebase SDK via SPM
- [ ] Implement Firebase Auth (Sign in with Apple + anonymous)
- [ ] Build HealthKit Manager
  - [ ] Request permissions (steps, calories, workouts)
  - [ ] Query daily activity summaries
  - [ ] Background refresh support
- [ ] Create data models (`DailyActivity`, `PlayerStats`, `CharacterModel`)
- [ ] Build Stats Engine (activity → XP conversion with daily caps)
- [ ] Character selection screen (male/female, cosmetic only)
- [ ] Dashboard screen (character image + today's stats)

## Phase 2: Backend + Sync (Week 3)

- [ ] Set up Firebase project (Firestore, Auth, Functions)
- [ ] Create Firestore collections (users, stats, battles, leaderboard)
- [ ] Build API Service layer (Firestore read/write wrapper)
- [ ] Implement stat sync (local stats → Firestore)
- [ ] Server-side stat validation (Cloud Function)
- [ ] User profile creation on first auth (includes `characterModel`)

## Phase 3: Battle System (Week 4-5)

- [ ] Build battle resolution Cloud Function
- [ ] Matchmaking logic (random opponent selection)
- [ ] Friend challenge system
- [ ] Battle request + result flow (client → server → client)
- [ ] Battle UI screen — MVP: static result with stat comparison
- [ ] Battle history storage
- [ ] 3 battles/day limit enforcement

## Phase 4: Art + SpriteKit (Week 5-6)

- [ ] Commission or generate base character art (male + female fighters)
- [ ] Create static character images for MVP (idle pose, front-facing)
- [ ] Integrate character images into dashboard + battle screens
- [ ] Set up SpriteKit scene structure (`BattleScene: SKScene`)
- [ ] Create sprite sheets (idle, attack, defend, hit — 4-6 frames each)
- [ ] Build SpriteKit battle playback (animated fight sequence)
- [ ] Embed `SpriteView` in SwiftUI battle screen

## Phase 5: Social + Leaderboard (Week 6-7)

- [ ] Friends list (add by username)
- [ ] Challenge a friend flow
- [ ] Global leaderboard (weekly reset)
- [ ] Leaderboard screen
- [ ] Profile screen (stats, settings, change character model)

## Phase 6: Monetization + Polish (Week 7-8)

- [ ] Integrate AdMob (rewarded ads: double XP, extra battle)
- [ ] Remove ads IAP ($4.99)
- [ ] Daily streak bonus logic
- [ ] Comeback bonus for inactive users
- [ ] Loading states, error handling, empty states
- [ ] App icon and launch screen

## Phase 7: Ship (Week 8-9)

- [ ] TestFlight internal testing (iPhone 13 + iPhone 16 Pro + Watch Series 6)
- [ ] Anti-cheat validation testing
- [ ] App Store screenshots and metadata
- [ ] Privacy policy page
- [ ] App Store submission
- [ ] Post-launch monitoring setup

---

## Dependencies

| Blocker | Needed By |
|---------|-----------|
| Apple Developer Account ($99) | Phase 1 (device testing with HealthKit) |
| Firebase project created | Phase 2 |
| Character art assets | Phase 4 (static images needed for Phase 1 dashboard) |

## Test Devices

| Device | Purpose |
|--------|---------|
| iPhone 13 | Baseline performance testing |
| iPhone 16 Pro | Target experience, ProMotion display |
| Apple Watch Series 6 | HealthKit workout data source |

## Decisions Made

- ✅ App name: PulseCombat (configurable via `AppConfig.appName`)
- ✅ Art style: Semi-realistic 2D (Smash Bros with grounded proportions)
- ✅ Gender: Male + female character models, purely cosmetic, user picks at onboarding
- ✅ Battle engine: SpriteKit for animated fights (Phase 4), static results for MVP
