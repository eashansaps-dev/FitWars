# FitWars — Task Breakdown (App: PulseCombat)

## Phase 1: Foundation ✅ DONE

- [x] Project setup, models, HealthKit, Stats Engine
- [x] Avatar customizer → simplified to fighter variant picker
- [x] Dashboard, Profile, Battle screens

## Phase 2: Battle System Overhaul ✅ DONE

- [x] SpriteKit battle scene with subsystem architecture
- [x] FighterNode with SpriteAnimator + sprite atlas support
- [x] InputManager (virtual joystick + action buttons)
- [x] AIController (3 difficulty levels, combos, pattern tracking)
- [x] ComboSystem, HUDOverlay, VFXManager, CameraController
- [x] ParallaxBackground, SoundManager hooks
- [x] Arena background image

## Phase 3: Firebase Auth + Stat Sync ✅ DONE

- [x] AuthManager (Sign in with Apple + anonymous)
- [x] FirestoreService (user profiles, stat sync, battle results)
- [x] Auth-state-aware app routing
- [x] SignInView, ProfileView account management
- [x] Cloud Function for stat validation

## Phase 4: Frutiger Aero Theme ✅ DONE

- [x] Centralized theme (AeroColors, AeroGradients, AeroButtonStyle, AeroCardModifier)
- [x] All SwiftUI screens themed
- [x] SpriteKit HUD + controls themed
- [x] Tab bar styled (Wii aesthetic)

## Phase 5: Sprite Art ✅ DONE (MVP)

- [x] Gemini-generated fighter sprites (9 poses)
- [x] Background removal + 256x256 frame processing
- [x] 5 character variants (default, female, dark, blonde, redhair)
- [x] Arena background image
- [x] Fighter variant picker replacing old shape-based customizer
- [x] FighterSpriteView for SwiftUI screens

## Phase 6: Real-Time PvP Multiplayer 📋 PLANNED

- [ ] Firebase Realtime Database setup
- [ ] Matchmaking queue + Cloud Function matching
- [ ] Input relay system (send/receive inputs via RTDB)
- [ ] Network battle scene
- [ ] Input synchronization + rollback
- [ ] Disconnection handling
- [ ] PvP result validation
- [ ] PvP UI (Find Match, waiting screen)

## Phase 7: Social + Leaderboard 📋 PLANNED

- [ ] Friends list
- [ ] Challenge a friend
- [ ] Global leaderboard (weekly reset)
- [ ] Rank tiers

## Phase 8: Polish 📋 PLANNED

- [ ] Sound effects + background music
- [ ] More character variants + full animation sets per variant
- [ ] Loading states, error handling
- [ ] App icon and launch screen
- [ ] TestFlight + App Store submission

---

## Pending Setup (needs Apple Dev Account)

- [ ] HealthKit entitlement (Signing & Capabilities)
- [ ] Sign in with Apple entitlement
- [ ] Enable Firestore API in Google Cloud Console
- [ ] Enable Anonymous Auth in Firebase Console
- [ ] Deploy Cloud Function (`functions/index.js`)

## Decisions Made

- ✅ Engine: SpriteKit (Unity/Unreal rejected)
- ✅ Theme: Frutiger Aero (Nintendo Wii aesthetic)
- ✅ Character system: Pre-rendered variants, not dynamic customization
- ✅ PvP: Real-time via Firebase RTDB input relay
- ✅ Art: AI-generated (Gemini) with programmatic background removal
- ✅ Battles: Portrait mode (landscape rejected — layout issues)
