# FitWars — Product Spec (App: PulseCombat)

## 1. Overview

PulseCombat is an iOS game where real-world fitness activity powers an in-game fighting character. Users compete in asynchronous PvP battles against friends. The more you train in real life, the stronger your character becomes.

**Platform:** iOS 17+ (iPhone + Apple Watch)
**Engine:** SwiftUI + SpriteKit
**Backend:** Firebase
**Health Data:** Apple HealthKit

> App name is stored in a single `AppConfig.appName` constant for easy renaming.

## 2. Core Loop

1. User works out (walk, run, gym, etc.)
2. App syncs activity data from HealthKit (daily)
3. Activity converts into XP and stat upgrades
4. User enters async PvP battles
5. Wins → rewards → rank progression
6. Repeat

## 3. Art Style

**Target:** Semi-realistic 2D — Super Smash Bros with more grounded proportions and shading. Not pixel art, not cartoon, not full 3D.

- Characters are detailed 2D sprite sheets with idle, attack, defend, and hit animations
- Battle scenes rendered in SpriteKit (embedded in SwiftUI views)
- Dashboard/menus are native SwiftUI
- MVP: static character art with minimal animation. Full sprite animation in Phase 2.

**Asset pipeline:** AI-generated base art → artist cleanup → sprite sheet export → SpriteKit atlas.

## 4. Character Selection

At onboarding, users choose a character model:

- **Male fighter** and **Female fighter** available at launch
- Choice is purely cosmetic — zero stat differences
- Users can change character model anytime in settings
- Post-MVP: additional character models, skins, outfits as cosmetic unlocks/purchases

Stats are derived entirely from real-world fitness activity, never from character choice.

## 5. Player Stats

| Stat | Derived From | Character Archetype |
|------|-------------|---------------------|
| **Strength** | Strength workouts, core training, HIIT | The Tank |
| **Stamina** | Cardio workouts, exercise minutes, cycling, swimming, yoga | The Endurance Fighter |
| **Speed** | Steps, running workouts, running distance | The Speedster |
| **Level** | Aggregate XP across all stats | — |

No stat differences between male/female characters. Same workout = same XP regardless of character model.

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

Workout type matters more than raw calories. A strength session gives Strength XP even if calorie burn is low. A 5k run gives Speed XP regardless of calorie count.

### Strength XP
| Source | XP |
|--------|-----|
| Per strength/core workout session | +20 |
| Per 10 min of strength workout duration | +5 |
| Per 100 kcal burned during strength workouts | +3 |

### Stamina XP
| Source | XP |
|--------|-----|
| Per cardio workout session (cycling, swimming, yoga, HIIT) | +5 |
| Per 10 min of appleExerciseTime | +3 |
| Per 100 active calories (general) | +2 |

### Speed XP
| Source | XP |
|--------|-----|
| Per running workout session | +10 |
| Per 1,000 steps | +5 |
| Per km of running distance | +3 |

### HIIT Split
HIIT workouts award XP to both Strength and Stamina (50/50 split on duration and calorie bonuses).

**Daily caps per stat:** 100 XP (prevents abuse, encourages consistency)

**Leveling curve:** Each level requires `level * 100` total XP. Level 1 = 100 XP, Level 10 = 1,000 XP.

## 7. Battle System

**Type:** Async, auto-resolved (MVP). SpriteKit animated playback (Phase 2).

**Algorithm (v1):**
```
score = (strength * 0.4) + (stamina * 0.3) + (speed * 0.3) + random(0..5)
winner = player with higher score
```

**Battle flow:**
1. User taps "Fight" → matched with opponent (random or friend)
2. Server resolves battle using both players' stats
3. Result screen shows outcome with stat comparison
4. Phase 2: SpriteKit replays the fight as an animated sequence
5. Winner gets +25 XP bonus + rank points

**Limits:** 3 battles per day (free), more via rewarded ads.

## 8. Social Features (MVP)

- Friends list (add by username)
- Challenge a specific friend
- Global leaderboard (weekly reset)

**Post-MVP:** Rank tiers (Bronze → Diamond), guilds/teams.

## 9. Retention Mechanics

- Daily streak bonus (+10% XP per consecutive day, max 7x)
- 3 free battles per day
- Comeback bonus if inactive 3+ days
- Weekly leaderboard reset (fresh competition)

## 10. Monetization

| Type | Details |
|------|---------|
| Rewarded ads | Post-battle double XP, extra battle |
| Remove ads | $4.99 one-time |
| Cosmetic skins | Character appearances, fight effects |
| Battle pass | Weekly challenges with cosmetic rewards |

**Hard rule:** No pay-to-win stat boosts. Ever.

## 11. Privacy & Compliance

- HealthKit permissions requested explicitly with clear explanation
- Raw health data never exposed to other users or stored on server
- Only derived stats (strength/stamina/speed scores) leave the device
- Users can opt out and delete data at any time
- Compliant with Apple HealthKit guidelines

## 12. Screens (MVP)

1. **Onboarding** — Character selection (male/female), HealthKit permission
2. **Dashboard** — Character view, today's stats, streak counter
3. **Battle** — Opponent preview, fight button, results
4. **Leaderboard** — Friends + global rankings
5. **Profile** — Character stats, settings, change character model

## 13. Test Devices

- iPhone 13 (baseline performance)
- iPhone 16 Pro (target experience)
- Apple Watch Series 6 (workout data source)

## 14. Success Metrics

- Day 1 / Day 7 retention
- Daily active users
- Battles per user per day
- Average session length
- Revenue per user (ARPU)

## 15. Out of Scope (MVP)

- Real-time combat
- Full SpriteKit battle animations (Phase 2)
- Deep character customization
- AR mode
- Android
