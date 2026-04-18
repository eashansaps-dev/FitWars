# FitWars — Product Spec (App: PulseCombat)

## 1. Overview

PulseCombat is an iOS game where real-world fitness activity powers an in-game fighting character. Users compete in real-time PvP battles and vs AI. The more you train in real life, the stronger your character becomes.

**Platform:** iOS 17+ (iPhone + Apple Watch)
**Engine:** SwiftUI + SpriteKit
**Backend:** Firebase (Auth, Firestore, Cloud Functions, Realtime Database)
**Health Data:** Apple HealthKit
**Multiplayer:** Apple GameKit (Game Center) + Firebase Realtime Database

> App name is stored in a single `AppConfig.appName` constant for easy renaming.

## 2. Core Loop

1. User works out (walk, run, gym, etc.)
2. App syncs activity data from HealthKit (daily)
3. Activity converts into XP and stat upgrades
4. User enters battles (vs AI or real-time PvP)
5. Wins → rewards → rank progression
6. Repeat

## 3. Art Style

**Target:** Semi-realistic 2D — Super Smash Bros with more grounded proportions and shading. Not pixel art, not cartoon, not full 3D.

- Characters are detailed 2D sprite sheets with idle, walk, attack, block, hit, special, knockdown, and victory animations
- Battle scenes rendered in SpriteKit (embedded in SwiftUI views)
- Dashboard/menus are native SwiftUI
- Parallax scrolling stage backgrounds with 3 depth layers

**Asset pipeline:** AI-generated base art (Midjourney/Leonardo.ai/Stable Diffusion) → artist cleanup → sprite sheet export → SpriteKit atlas.
See `docs/SPRITE_ART_GUIDE.md` for detailed prompts and workflow.

**Engine decision:** SpriteKit (staying native). Unity/Unreal considered and rejected — SpriteKit handles 2D fighting games well, integrates natively with HealthKit/SwiftUI/Firebase, and the visual quality gap is an art problem, not an engine problem.

## 4. Avatar Customization

At onboarding, users build a custom fighter avatar:

**Body type:** Adult fighter proportions (Street Fighter / Mortal Kombat style). Not chibi, not cartoon.

**Customizable features:**
- Fighter name (user-chosen)
- Skin tone (color spectrum)
- Face shape (oval, square, round, angular)
- Eyes (multiple styles)
- Hair style (short, long, mohawk, bald, braids, ponytail)
- Hair color (color spectrum)
- Outfit (gi, tank top, hoodie, armor — unlockable)

**Rendering:** Modular layered system in SwiftUI (AvatarRenderer) for dashboard/profile. SpriteKit sprite sheets for battle.

**Gender:** No gender selection. Avatar is fully customizable.

Stats are derived entirely from real-world fitness activity, never from avatar appearance.

## 5. Player Stats

| Stat | Derived From | Character Archetype |
|------|-------------|---------------------|
| **Strength** | Strength workouts, core training, HIIT | The Tank |
| **Stamina** | Cardio workouts, exercise minutes, cycling, swimming, yoga | The Endurance Fighter |
| **Speed** | Steps, running workouts, running distance | The Speedster |
| **Level** | Aggregate XP across all stats | — |

### HealthKit Workout Type Mapping

| HealthKit Workout Type | Maps To |
|---|---|
| `.traditionalStrengthTraining` | Strength |
| `.functionalStrengthTraining` | Strength |
| `.coreTraining` | Strength |
| `.highIntensityIntervalTraining` | Strength + Stamina (split) |
| `.running` | Speed |
| `.walking` | Speed |
| `.cycling` | Stamina |
| `.swimming` | Stamina |
| `.yoga` | Stamina |
| `.mixedCardio` | Stamina |

## 6. XP System

Workout type matters more than raw calories.

### Strength XP
| Source | XP |
|--------|-----|
| Per strength/core workout session | +20 |
| Per 10 min of strength workout duration | +5 |
| Per 100 kcal burned during strength workouts | +3 |

### Stamina XP
| Source | XP |
|--------|-----|
| Per cardio workout session | +5 |
| Per 10 min of appleExerciseTime | +3 |
| Per 100 active calories (general) | +2 |

### Speed XP
| Source | XP |
|--------|-----|
| Per running workout session | +10 |
| Per 1,000 steps | +5 |
| Per km of running distance | +3 |

### HIIT Split
HIIT workouts award XP to both Strength and Stamina (50/50 split).

**Daily caps per stat:** 100 XP
**Leveling curve:** Each level requires `level * 100` total XP.

## 7. Battle System

### 7.1 Current: User vs AI (✅ Implemented)

Real-time 2D combat with SpriteKit. Side-view, on-screen controls.

**Controls:** Virtual joystick (left) + action buttons (right): Light Attack, Heavy Attack, Block, Special
**Special moves:** Forward-forward-attack input sequence when special meter is full

**How fitness stats affect combat:**
- Strength → more damage per hit
- Stamina → larger health pool
- Speed → faster movement

**AI difficulty levels:** Easy, Medium, Hard
- Easy: 0.5s reaction time, no combos
- Medium: 0.3s reaction, 2-hit combos
- Hard: 0.15s reaction, 4-hit combos, pattern tracking, counter-play

**Combo system:** Chain attacks within 0.4s window, damage scales 1.0x → 1.1x → 1.2x etc.
**Special meter:** Fills on hits dealt (5%) and received (3%). 5+ hit combo awards 10% bonus.

**Visual effects:** Hit sparks, screen shake, special attack flash, slow-motion KO, dynamic camera zoom.
**HUD:** Gradient health bars with ghost damage trail, round timer (pulses red at ≤10s), combo counter, special meter with "READY" indicator.

### 7.2 Planned: Real-Time PvP Multiplayer

**Type:** Real-time online PvP — both players fight simultaneously over the network.

**Networking approach:** Firebase Realtime Database for matchmaking + signaling, then peer-to-peer via GameKit (Game Center) for the actual fight. This gives low-latency gameplay while using Firebase for the social layer.

**Alternative:** Full server-authoritative via Firebase Realtime Database with input relay. Higher latency but prevents cheating.

**Key challenges:**
- Input synchronization (lockstep or rollback netcode)
- Latency compensation (target <100ms round-trip)
- Disconnection handling (forfeit after timeout)
- Anti-cheat (server validates stats, client validates inputs)

**Matchmaking:** Skill-based using rank + level range. Queue via Firebase, match via Cloud Function.

### 7.3 Auto-Resolve Fallback

For async challenges or when real-time isn't available:
```
score = (strength * 0.4) + (stamina * 0.3) + (speed * 0.3) + random(0..5)
```

### Post-Battle Insights

Every battle result includes:
1. **Stat Comparison** — side-by-side with delta per stat
2. **Weakness Highlight** — identifies weakest stat and biggest gap
3. **Workout Suggestions** — maps weak stats to real-world workouts
4. **Win insights** — even on wins, highlight growth areas

## 8. Social Features

- Friends list (add by username)
- Challenge a specific friend
- Global leaderboard (weekly reset)
- **Planned:** Rank tiers (Bronze → Diamond), guilds/teams

## 9. Retention Mechanics

- Daily streak bonus (+10% XP per consecutive day, max 7x)
- 3 free battles per day
- Comeback bonus if inactive 3+ days
- Weekly leaderboard reset

## 10. Monetization

| Type | Details |
|------|---------|
| Rewarded ads | Post-battle double XP, extra battle |
| Remove ads | $4.99 one-time |
| Cosmetic skins | Character appearances, fight effects |
| Battle pass | Weekly challenges with cosmetic rewards |

**Hard rule:** No pay-to-win stat boosts. Ever.

## 11. Privacy & Compliance

- HealthKit permissions requested explicitly
- Raw health data never leaves the device
- Only derived stats (strength/stamina/speed) sent to backend
- Users can opt out and delete data at any time
- Compliant with Apple HealthKit guidelines

## 12. Screens

1. **Onboarding** — Avatar customizer (name, skin, face, eyes, hair, outfit), HealthKit permission
2. **Dashboard** — Avatar view, today's stats, streak counter, XP breakdown
3. **Battle** — Opponent preview, difficulty picker, fight (SpriteKit), results with insights
4. **Leaderboard** — Friends + global rankings (planned)
5. **Profile** — Character stats, settings

## 13. Development Phases

| Phase | Status | Description |
|-------|--------|-------------|
| Foundation | ✅ Done | Project setup, models, HealthKit, Stats Engine, avatar customizer |
| Battle System Overhaul | ✅ Done | SpriteKit combat, AI, HUD, VFX, camera, input, sound hooks |
| Firebase Auth + Sync | 🔜 Next | Sign in with Apple, stat persistence, user profiles |
| Sprite Art | 🔜 Next | AI-generated character sprites, stage backgrounds |
| Real-Time PvP | 📋 Planned | Online multiplayer via GameKit/Firebase |
| Social + Leaderboard | 📋 Planned | Friends, challenges, rankings |
| Monetization + Polish | 📋 Planned | Ads, IAP, streak bonuses, polish |
| Ship | 📋 Planned | TestFlight, App Store submission |

## 14. Test Devices

- iPhone 13 (baseline performance)
- iPhone 16 Pro (target experience)
- Apple Watch Series 6 (workout data source)

## 15. Success Metrics

- Day 1 / Day 7 retention
- Daily active users
- Battles per user per day
- Average session length
- Revenue per user (ARPU)
