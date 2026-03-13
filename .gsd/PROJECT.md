# Project

## What This Is

2TAP is an iOS game built with SwiftUI + SpriteKit. A fast-paced perception/reflex game where players have exactly 2 seconds to identify and tap all balls of the matching color. Endless rounds, increasing difficulty, combo scoring.

## Core Value

The 2-second core loop: balls appear → find the matching color → tap them all before time runs out. Everything else supports this tension.

## Current State

Empty project. No code, no assets, no Xcode project yet. `IOS/2TAP/` directory created.

## Architecture / Key Patterns

- **SwiftUI** — all non-gameplay UI (menus, settings, game over, HUD overlays)
- **SpriteKit** — game scene (ball rendering, touch detection, timer, animations) embedded via `SpriteView`
- **UserDefaults** — persistent high score and settings
- **Gemini API (build time)** — AI-generated assets (logo, app icon, backgrounds, UI elements)
- Target: iOS 17+, iPhone

## Capability Contract

See `.gsd/REQUIREMENTS.md` for the explicit capability contract, requirement status, and coverage mapping.

## Milestone Sequence

- [ ] M001: 2TAP Game — Full game from menu to App Store readiness
