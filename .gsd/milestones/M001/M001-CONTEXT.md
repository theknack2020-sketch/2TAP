# M001: 2TAP Audit & Improvement — Context

**Gathered:** 2026-03-16
**Status:** Ready for planning

## Project Description

2TAP is a SpriteKit + SwiftUI iOS color-matching reflex game. Balls bounce around, 3 share the same color, player taps them before time runs out. Three difficulty modes. Game Center leaderboard. FM synthesis audio. The game works but needs bug fixes, test hardening, UX polish, accessibility, and code cleanup.

## Why This Milestone

The game is functional but has real bugs (race conditions, broken review prompt), harsh UX that punishes casual players, zero tests on critical state machine code, no accessibility support for a color-matching game, and a god-class that's hard to maintain. This is the "make it right" pass before any App Store push.

## User-Visible Outcome

### When this milestone is complete, the user can:

- Play a bug-free game with fair mechanics (no phantom life loss, no trapped-in-game feeling)
- Color-blind players can play with shape overlays on balls
- Share scores via iOS share sheet
- See per-difficulty high scores and leaderboards
- Quickly restart after game over without countdown delay

### Entry point / environment

- Entry point: iOS app launch
- Environment: iOS 17+ Simulator and device
- Live dependencies involved: Game Center (leaderboard)

## Completion Class

- Contract complete means: All 30+ existing tests pass, 30+ new tests pass, build clean
- Integration complete means: Game plays correctly on simulator, Game Center submits scores
- Operational complete means: App launches, plays, and recovers correctly across app lifecycle

## Final Integrated Acceptance

To call this milestone complete, we must prove:

- Full game loop (launch → menu → play → game over → restart) works without bugs on iPhone 16 Pro simulator
- Color-blind mode activates and shows shape overlays on balls
- Score sharing produces a share sheet with score card
- Per-difficulty high scores display correctly in menu and settings
- All tests pass (target: 60+)

## Risks and Unknowns

- SpriteKit ↔ SwiftUI threading — race condition fix must not introduce new timing issues
- GameScene refactor — behavior must be identical after splitting into modules
- Color-blind shape overlays in SpriteKit — need to verify SKShapeNode performance with many balls
- Per-difficulty leaderboards — requires Game Center dashboard configuration (can only verify format, not actual submission without real account)

## Existing Codebase / Prior Art

- `Game/GameScene.swift` — 380-line god-class, core game loop. Every change flows through here.
- `Game/GameState.swift` — @Observable state bridge between SpriteKit and SwiftUI. Zero tests.
- `Game/ScoreEngine.swift` — Pure static scoring logic. Well-tested.
- `Game/BallPlacementEngine.swift` — Non-overlapping position generation. Well-tested.
- `Game/ColorMatchEngine.swift` — Color assignment per round. Well-tested.
- `Game/DifficultyEngine.swift` — Score-based difficulty progression. Well-tested.
- `Game/BallNode.swift` — SpriteKit ball with 3D metallic appearance + physics. Untested hitTest.
- `Game/AudioManager.swift` — FM synthesis. Has dead musicEnabled code.
- `Game/HapticManager.swift` — Creates new generators per call (should reuse).
- `Models/SettingsManager.swift` — UserDefaults persistence + streak logic. Untested date math.
- `Views/GameView.swift` — 435 lines, largest view. HUD + game over + score popups.
- `Views/MainMenuView.swift` — Animated menu with difficulty selector.
- `Views/SettingsView.swift` — Sound, theme, palette settings.
- `project.yml` — XcodeGen config. iOS 17+, Swift 5.9, SpriteKit + AVFoundation + GameKit.

> See `.gsd/DECISIONS.md` for all architectural and pattern decisions.

## Relevant Requirements

- R001-R006 — Bug fixes (S01)
- R007-R010 — Test coverage (S02)
- R011-R015 — UX polish (S03)
- R016-R019 — Player features (S04)
- R020-R023 — Code quality (S05)

## Scope

### In Scope

- Fix all identified bugs
- Add unit tests for untested critical paths
- UX improvements from player perspective
- Color-blind accessibility
- Score sharing
- Per-difficulty tracking
- Code quality refactoring
- Simulator-based visual verification

### Out of Scope / Non-Goals

- Monetization (IAP, ads)
- Multiplayer
- CloudKit sync
- Background music (deferred)
- Localization (deferred)
- Analytics (deferred)

## Technical Constraints

- iOS 17+ minimum (uses @Observable)
- Swift 5.9
- XcodeGen for project generation (must run `xcodegen generate` after adding files)
- SpriteKit main thread constraint — GameScene.update() runs on main thread via SpriteView
- Game Center requires entitlement and real developer account for full testing

## Integration Points

- Game Center — leaderboard submission, per-difficulty IDs needed
- AVFoundation — FM synthesis audio engine
- UIKit haptics — UIImpactFeedbackGenerator, UINotificationFeedbackGenerator

## Open Questions

- Empty-tap handling: remove penalty entirely, or only penalize wrong-ball taps? — leaning toward only wrong-ball penalty
- Color-blind mode: shapes on balls (triangle, square, circle, star) or patterns (stripes, dots)? — leaning toward shapes for clarity at speed
