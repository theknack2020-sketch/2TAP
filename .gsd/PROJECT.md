# Project

## What This Is

2TAP — iOS SpriteKit + SwiftUI color-matching reflex game. Balls bounce around the screen, 3 share the same color, player must find and tap all 3 before time runs out. Three difficulty modes (Easy 3s, Normal 2s, Insane 1.5s). Game Center leaderboard. FM synthesis audio with no asset files.

## Core Value

Fast, addictive color-matching gameplay that's accessible to all players and feels polished enough for App Store.

## Current State

- 21 source files, ~4,600 lines Swift
- 30 unit tests passing, ~21% file coverage
- Builds clean on iOS 17+ (XcodeGen)
- Core gameplay loop works but has bugs (race condition, broken review prompt)
- UX gaps: harsh empty-tap penalty, no mid-game exit, no color-blind support
- Code quality: GameScene god-class, 4 singletons, magic numbers

## Architecture / Key Patterns

- SpriteKit GameScene ↔ @Observable GameState ↔ SwiftUI HUD
- Static engine structs for pure game logic (Score, Difficulty, ColorMatch, BallPlacement)
- SettingsManager singleton with UserDefaults persistence
- XcodeGen (project.yml) for project generation
- iOS 17+ @Observable (not Combine)

## Capability Contract

See `.gsd/REQUIREMENTS.md` for the explicit capability contract.

## Milestone Sequence

- [ ] M001: Audit & Improvement — Fix bugs, harden tests, polish UX, add player features, clean up code
