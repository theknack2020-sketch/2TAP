# M001: 2TAP Game

**Vision:** Build 2TAP — a fast-paced iOS reflex game where players have exactly 2 seconds to find and tap all matching-color balls. From empty project to App Store-ready, with AI-generated assets and optimized ASO.

## Success Criteria

- Player can complete a full game session: menu → play → rounds → game over → replay
- 2-second timer is precise and visually clear
- Balls render with convincing 3D metallic appearance
- Combo scoring and difficulty progression create engaging challenge curve
- Sound effects and music enhance the experience without annoying
- Settings (theme, sound, palette) persist across sessions
- AI-generated logo and assets look polished and professional
- App Store listing is fully optimized with keywords, description, screenshots

## Key Risks / Unknowns

- Ball placement at high counts — may be unsolvable with finger gaps on small screens
- 3D metallic rendering in SpriteKit — shader complexity vs pre-rendered approach
- Color similarity curves — making difficulty fair but challenging
- Gemini asset quality — may need many iterations for logo

## Proof Strategy

- Ball placement unsolvable → retire in S01 by proving placement works with 12+ balls on iPhone SE screen
- 3D rendering quality → retire in S02 by proving metallic shader/texture looks convincing on device
- Color fairness → retire in S02 by proving difficulty curve doesn't create impossible rounds

## Verification Classes

- Contract verification: xcodebuild build + unit tests for game logic (scoring, placement, color matching)
- Integration verification: SwiftUI ↔ SpriteKit ↔ UserDefaults ↔ Audio all wired and working
- Operational verification: app launches on simulator, plays end-to-end without crashes
- UAT / human verification: visual quality of 3D balls, "feel" of gameplay, ASO quality

## Milestone Definition of Done

This milestone is complete only when all are true:

- All 7 slice deliverables are complete
- Game plays end-to-end: menu → countdown → rounds → game over → replay
- Settings persist across app restarts
- Audio plays correctly (effects + music)
- AI-generated assets embedded and displaying
- App Store metadata complete and optimized
- App builds clean with no warnings
- Success criteria re-checked against running app on simulator

## Requirement Coverage

- Covers: R001, R002, R003, R004, R005, R006, R007, R008, R009, R010, R011, R012, R013, R014, R015, R016, R017, R018, R019, R020, R021
- Partially covers: none
- Leaves for later: R022 (rewarded ads), R023 (Game Center)
- Orphan risks: none

## Slices

- [ ] **S01: Core Game Engine** `risk:high` `depends:[]`
  > After this: Xcode project exists. Balls appear on screen with non-overlapping placement, 3-2-1 countdown plays, 2s timer bar counts down, tapping balls registers correctly, rounds cycle.

- [ ] **S02: Scoring, Lives & Game Polish** `risk:medium` `depends:[S01]`
  > After this: Score increases with combo multiplier, 3 lives with +1 bonus every 10 perfect rounds, difficulty increases (more balls), pause system works (3 uses), frame feedback (green/red flash), 3D metallic ball rendering.

- [ ] **S03: Menus, Settings & Theming** `risk:medium` `depends:[S01]`
  > After this: Main menu with animated background and logo placeholder, settings screen with sound/music/theme/palette toggles, dark/light/system theme works throughout app. Navigation between menu ↔ game ↔ settings.

- [ ] **S04: Game Over & Persistence** `risk:low` `depends:[S02,S03]`
  > After this: Game over screen shows score summary (final score, best combo, rounds survived), replay and home buttons work, high score persists across app restarts, double-confirm score reset in settings.

- [ ] **S05: Audio System** `risk:low` `depends:[S01]`
  > After this: Cartoon tap sound on ball touch, bomb sound on wrong/timeout, 10 background music loops play randomly, music toggleable in settings and via in-game icon.

- [ ] **S06: AI Asset Generation** `risk:medium` `depends:[S03]`
  > After this: Gemini-generated logo (multiple variations, best selected) with special care, app icon in all sizes, menu backgrounds, all embedded in the app. Logo displayed prominently on main menu.

- [ ] **S07: ASO & Store Readiness** `risk:low` `depends:[S06]`
  > After this: App Store listing fully prepared — optimized title, subtitle, keywords (100 chars used), description with hook + features, screenshots for all required sizes, privacy policy, category selection, EN + TR localization.

## Boundary Map

### S01 → S02

Produces:
- `TwoTapGame/Game/GameScene.swift` → SKScene subclass with ball spawning, touch detection, round cycling
- `TwoTapGame/Game/BallNode.swift` → SKShapeNode/SKSpriteNode subclass for individual balls
- `TwoTapGame/Game/BallPlacementEngine.swift` → non-overlapping random placement algorithm
- `TwoTapGame/Game/ColorMatchEngine.swift` → generates round colors (1 repeated, rest unique)
- `TwoTapGame/Game/GameState.swift` → @Observable game state (round, timer, tapped balls)
- `TwoTapGame/Game/TimerBar.swift` → 2-second visual countdown overlay
- `TwoTapGame/Views/GameView.swift` → SwiftUI view wrapping SpriteView

Consumes:
- nothing (first slice)

### S01 → S03

Produces:
- `TwoTapGame/Game/GameState.swift` → @Observable game state for SwiftUI binding
- `TwoTapGame/Views/GameView.swift` → SwiftUI game view for navigation

Consumes:
- nothing (first slice)

### S01 → S05

Produces:
- `TwoTapGame/Game/GameScene.swift` → touch events and round results that trigger sounds

Consumes:
- nothing (first slice)

### S02 → S04

Produces:
- `TwoTapGame/Game/GameState.swift` (extended) → score, combo, lives, rounds survived, isGameOver
- `TwoTapGame/Game/ScoreEngine.swift` → combo multiplier logic, score calculation
- `TwoTapGame/Game/DifficultyEngine.swift` → ball count thresholds, color similarity curves

Consumes from S01:
- `GameScene.swift` → base game loop to add scoring/lives hooks
- `GameState.swift` → base state to extend with score/lives fields
- `ColorMatchEngine.swift` → color generation to add similarity difficulty

### S03 → S04

Produces:
- `TwoTapGame/Views/MainMenuView.swift` → home navigation target
- `TwoTapGame/Models/SettingsManager.swift` → @Observable settings with UserDefaults persistence
- `TwoTapGame/App/AppTheme.swift` → theme definitions for consistent styling

Consumes from S01:
- `GameView.swift` → navigation target from menu

### S03 → S06

Produces:
- `TwoTapGame/Views/MainMenuView.swift` → has Image placeholder for logo asset
- `TwoTapGame/Resources/Assets.xcassets/` → asset catalog structure

Consumes from S01:
- `GameView.swift` → navigation integration

### S04 → S07

Produces:
- Complete running app — all screens, all mechanics, all navigation

Consumes from S02:
- `GameState.swift` → final score, combo, rounds for game over display
- `ScoreEngine.swift` → score formatting

Consumes from S03:
- `MainMenuView.swift` → home navigation from game over
- `SettingsManager.swift` → high score storage, reset functionality

### S06 → S07

Produces:
- `TwoTapGame/Resources/Assets.xcassets/AppIcon.appiconset/` → app icon in all sizes
- `TwoTapGame/Resources/Assets.xcassets/logo.imageset/` → game logo
- `TwoTapGame/Resources/Assets.xcassets/menu-bg.imageset/` → menu background

Consumes from S03:
- Asset catalog structure
- Main menu view (to embed logo and background)
