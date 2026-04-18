# FitWars — Task Breakdown (App: PulseCombat)

## Phase 1: Foundation ✅ DONE

- [x] Create project spec and design docs
- [x] Create Xcode project (SwiftUI, iOS 17+)
- [x] Set up project structure + `AppConfig`
- [x] Add Firebase SDK via SPM
- [x] Build HealthKit Manager (permissions, daily queries)
- [x] Create data models (DailyActivity, PlayerStats, CharacterModel, AvatarConfig)
- [x] Build Stats Engine (activity → XP conversion with daily caps)
- [x] Avatar customizer (name, skin, face, eyes, hair, outfit)
- [x] Dashboard screen (avatar + today's stats + XP breakdown)
- [x] Profile screen (stats, level, XP progress)

## Phase 2: Battle System Overhaul ✅ DONE

- [x] DifficultyLevel enum (easy/medium/hard) + AIAction enum
- [x] FighterState expanded (11 states) + AttackType enum
- [x] SpriteAnimator (atlas loading, frame grouping, fallback textures)
- [x] Placeholder sprite atlas (fighter_default.spriteatlas)
- [x] FighterNode refactor (SKSpriteNode + SpriteAnimator, special meter, state machine)
- [x] InputManager (virtual joystick, action buttons, multi-touch, special move buffer)
- [x] ComboSystem (hit chains, damage scaling, special meter bonus)
- [x] AIController (reactive AI, combos, survival mode, pattern tracking)
- [x] HUDOverlay (gradient health bars, ghost damage, timer, combo counter, special meter)
- [x] VFXManager (hit sparks, screen shake, special flash, slow-mo KO, adaptive perf)
- [x] CameraController (dynamic framing, zoom, shake)
- [x] ParallaxBackground (3-layer scrolling, fallback gradient)
- [x] SoundManager (event hooks, music, missing-file handling)
- [x] BattleScene complete rewrite (subsystem orchestrator)
- [x] BattleSpriteView + BattleView updates (difficulty picker, params)
- [x] Resource cleanup (willMove(from:))

## Phase 3: Firebase Auth + Stat Sync 🔜 NEXT

- [ ] Implement Sign in with Apple flow
- [ ] Anonymous auth fallback for onboarding
- [ ] Link anonymous → Apple ID upgrade
- [ ] Create user profile in Firestore on first auth
- [ ] Sync avatar config to Firestore
- [ ] Sync player stats (strength/stamina/speed) to Firestore
- [ ] Server-side stat validation (Cloud Function)
- [ ] Replace MockAPIService with real Firebase API service
- [ ] Fetch real opponents from Firestore (instead of hardcoded bots)
- [ ] Battle result storage in Firestore

## Phase 4: Sprite Art

- [ ] Generate base idle pose (AI tools — see SPRITE_ART_GUIDE.md)
- [ ] Generate attack, hit, block animation frames
- [ ] Generate walk forward/backward frames
- [ ] Generate special attack + knockdown + victory frames
- [ ] Post-process: remove backgrounds, resize to 512×512, center
- [ ] Create fighter sprite atlas in Xcode
- [ ] Generate stage background layers (far/mid/near)
- [ ] Add sound effects (hit, block, whiff, KO, round start/end)
- [ ] Add background music track

## Phase 5: Real-Time PvP Multiplayer 📋 PLANNED

- [ ] Set up Firebase Realtime Database
- [ ] Matchmaking queue (write to RTDB, Cloud Function matches players)
- [ ] Game session creation (Cloud Function creates games/{gameId})
- [ ] Client-side match listener (observe games/{gameId} for opponent)
- [ ] Input relay system (send local inputs to RTDB, receive remote inputs)
- [ ] Network battle scene (extends BattleScene for PvP mode)
- [ ] Input synchronization (2-frame buffer for jitter absorption)
- [ ] Rollback netcode (rewind + resimulate on late inputs)
- [ ] Disconnection handling (3s timeout → forfeit)
- [ ] PvP result validation (Cloud Function compares both clients)
- [ ] Anti-cheat: stat validation before match, input rate limiting
- [ ] PvP UI: "Find Match" button, waiting screen, connection status

## Phase 6: Social + Leaderboard 📋 PLANNED

- [ ] Friends list (add by username)
- [ ] Challenge a friend flow
- [ ] Global leaderboard (weekly reset)
- [ ] Leaderboard screen
- [ ] Rank tiers (Bronze → Diamond)

## Phase 7: Monetization + Polish 📋 PLANNED

- [ ] Integrate AdMob (rewarded ads: double XP, extra battle)
- [ ] Remove ads IAP ($4.99)
- [ ] Daily streak bonus logic
- [ ] Comeback bonus for inactive users
- [ ] Loading states, error handling, empty states
- [ ] App icon and launch screen

## Phase 8: Ship 📋 PLANNED

- [ ] TestFlight internal testing
- [ ] Anti-cheat validation testing
- [ ] App Store screenshots and metadata
- [ ] Privacy policy page
- [ ] App Store submission
- [ ] Post-launch monitoring setup

---

## Decisions Made

- ✅ App name: PulseCombat (configurable via `AppConfig.appName`)
- ✅ Art style: Semi-realistic 2D (Smash Bros with grounded proportions)
- ✅ Engine: SpriteKit (staying native — Unity/Unreal rejected)
- ✅ Avatar: Fully customizable, no gender selection
- ✅ Battle engine: SpriteKit with full subsystem architecture
- ✅ AI: 3 difficulty levels with reactive behavior, combos, pattern tracking
- ✅ PvP approach: Real-time via Firebase RTDB input relay (not async)
- ✅ Multiplayer networking: Firebase Realtime Database for relay, not GameKit
