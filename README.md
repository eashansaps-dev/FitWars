# FitWars 🥊

**App Display Name:** PulseCombat

A mobile iOS game that converts real-world fitness activity into in-game character progression and enables asynchronous PvP battles between users.

**The more you train in real life, the stronger your character becomes in-game.**

> App display name ("PulseCombat") is configurable via a single `AppConfig.appName` constant.

## How It Works

1. Work out (walk, run, gym — anything tracked by Apple Health)
2. Your activity converts into character stats (Strength, Stamina, Speed)
3. Challenge friends to async PvP battles
4. Win → rank up → repeat

## Tech Stack

- **Client:** SwiftUI + SpriteKit (iOS 17+)
- **Health:** Apple HealthKit
- **Backend:** Firebase (Auth, Firestore, Cloud Functions)
- **Ads:** Google AdMob (rewarded)

## Art Style

Semi-realistic 2D fighters — think Super Smash Bros with more grounded proportions and shading. SpriteKit-based battle scenes with animated sprite sheets.

## Test Devices

- iPhone 13
- iPhone 16 Pro
- Apple Watch Series 6

## Project Structure

```
FitWars/
├── docs/
│   ├── SPEC.md      # Product spec
│   ├── DESIGN.md    # Technical design
│   └── TASKS.md     # Task breakdown by phase
├── FitWars/          # Xcode source
└── README.md
```

## Docs

- [Product Spec](docs/SPEC.md)
- [Technical Design](docs/DESIGN.md)
- [Task Breakdown](docs/TASKS.md)

## License

Private — not open source.
