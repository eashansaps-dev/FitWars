# FitWars 🥊

**App Display Name:** PulseCombat

A mobile iOS fighting game where real-world fitness activity powers your in-game character. Work out → get stronger → fight.

> App display name is configurable via `AppConfig.appName`.

## How It Works

1. Work out (walk, run, gym — anything tracked by Apple Health)
2. Your activity converts into character stats (Strength, Stamina, Speed)
3. Pick your fighter from 5 character variants
4. Fight AI opponents or challenge friends in real-time PvP (coming soon)
5. Win → rank up → repeat

## Current State

- ✅ SpriteKit battle system with 3 AI difficulty levels
- ✅ Gemini-generated fighter sprites (idle, walk, punch, kick, block, hit reaction)
- ✅ 5 character variants (Fighter, Kunoichi, Striker, Blaze, Inferno)
- ✅ Frutiger Aero UI theme (glossy buttons, glass cards, sky-blue gradients)
- ✅ Firebase Auth (Sign in with Apple + anonymous)
- ✅ Firestore stat sync + Cloud Function validation
- ✅ HealthKit integration (steps, calories, workouts → XP)
- ✅ Dynamic HUD (health bars, combo counter, special meter, timer)
- ✅ VFX (hit sparks, screen shake, slow-mo KO)
- ✅ Arena background
- 🔜 Real-time PvP multiplayer
- 🔜 Social features + leaderboard
- 📋 Sound effects + music
- 📋 More character variants + full animation sets

## Tech Stack

- **Client:** SwiftUI + SpriteKit (iOS 17+)
- **Health:** Apple HealthKit
- **Backend:** Firebase (Auth, Firestore, Cloud Functions)
- **Art:** AI-generated 2D sprites (Gemini)
- **Theme:** Frutiger Aero (Nintendo Wii aesthetic)

## Project Structure

```
FitWars/
├── Models/          # Data models (PlayerStats, AvatarConfig, FighterVariant)
├── Services/        # HealthKit, Stats Engine, Auth, Firestore, API
├── Views/           # SwiftUI screens (Dashboard, Profile, Battle, SignIn)
├── Battle/          # SpriteKit battle system (12 files)
├── Theme/           # Frutiger Aero theme (colors, gradients, styles)
├── Sprites/         # Fighter sprite PNGs (loaded at runtime)
├── Assets.xcassets/ # Sprite atlases, colors, app icon
└── docs/
    ├── SPEC.md              # Product spec
    ├── DESIGN.md            # Technical design
    ├── TASKS.md             # Task breakdown by phase
    └── SPRITE_ART_GUIDE.md  # AI art generation guide
functions/               # Firebase Cloud Functions (stat validation)
```

## Docs

- [Product Spec](FitWars/docs/SPEC.md)
- [Technical Design](FitWars/docs/DESIGN.md)
- [Task Breakdown](FitWars/docs/TASKS.md)
- [Sprite Art Guide](FitWars/docs/SPRITE_ART_GUIDE.md)

## License

Private — not open source.
