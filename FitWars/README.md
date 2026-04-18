# FitWars 🥊

**App Display Name:** PulseCombat

A mobile iOS fighting game where real-world fitness activity powers your in-game character. Work out → get stronger → fight.

> App display name is configurable via `AppConfig.appName`.

## How It Works

1. Work out (walk, run, gym — anything tracked by Apple Health)
2. Your activity converts into character stats (Strength, Stamina, Speed)
3. Fight AI opponents or challenge friends in real-time PvP
4. Win → rank up → repeat

## Current State

- ✅ Full SpriteKit battle system (vs AI) with 3 difficulty levels
- ✅ Reactive AI with combos, survival mode, pattern tracking
- ✅ Virtual joystick + action buttons with multi-touch
- ✅ Combo system with damage scaling + special meter
- ✅ Dynamic camera, parallax backgrounds, VFX (hit sparks, screen shake, slow-mo KO)
- ✅ Polished HUD (gradient health bars, combo counter, special meter)
- ✅ HealthKit integration (steps, calories, workouts → XP)
- ✅ Avatar customizer (name, skin, face, eyes, hair, outfit)
- 🔜 Firebase Auth + stat sync
- 🔜 Real sprite art (currently using placeholders)
- 📋 Real-time PvP multiplayer
- 📋 Social features + leaderboard

## Tech Stack

- **Client:** SwiftUI + SpriteKit (iOS 17+)
- **Health:** Apple HealthKit
- **Backend:** Firebase (Auth, Firestore, Cloud Functions, Realtime Database)
- **Art:** AI-generated 2D sprites (see `docs/SPRITE_ART_GUIDE.md`)

## Project Structure

```
FitWars/
├── Models/          # Data models (PlayerStats, AvatarConfig, etc.)
├── Services/        # HealthKit, Stats Engine, API Service
├── Views/           # SwiftUI screens (Dashboard, Profile, Battle)
├── Battle/          # SpriteKit battle system (12 files)
├── Assets.xcassets/ # Sprite atlases, colors, app icon
└── docs/
    ├── SPEC.md              # Product spec
    ├── DESIGN.md            # Technical design
    ├── TASKS.md             # Task breakdown by phase
    └── SPRITE_ART_GUIDE.md  # AI art generation guide
```

## Docs

- [Product Spec](docs/SPEC.md)
- [Technical Design](docs/DESIGN.md)
- [Task Breakdown](docs/TASKS.md)
- [Sprite Art Guide](docs/SPRITE_ART_GUIDE.md)

## License

Private — not open source.
