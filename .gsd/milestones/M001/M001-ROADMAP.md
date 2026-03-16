# M001: 2TAP Audit & Improvement

**Vision:** Transform 2TAP from a functional prototype into a polished, accessible, well-tested iOS game ready for App Store. Fix all known bugs, harden test coverage on critical paths, polish UX from a real player's perspective, add accessibility and social features, and clean up the codebase for maintainability.

## Success Criteria

- All 6 known bugs fixed and verified in simulator
- Test count ≥60 with GameState, SettingsManager, BallNode covered
- Game plays correctly on iPhone SE through iPhone 16 Pro Max
- Color-blind players can play with shape overlays on balls
- No god-classes >200 lines
- Full game loop (menu → play → game over → restart) verified on simulator
- Per-difficulty high scores tracked and displayed

## Key Risks / Unknowns

- SpriteKit ↔ SwiftUI threading — race condition fix must not introduce new timing issues
- GameScene refactor — 380-line class must split without behavior change
- Color-blind shape overlays in SpriteKit — performance with 12 moving shaped balls unknown

## Proof Strategy

- Threading risk → retire in S01 by fixing race condition and verifying no phantom life loss in simulator
- GameScene refactor risk → retire in S05 by splitting class and confirming all existing tests still pass
- Shape overlay risk → retire in S04 by implementing and verifying 12 balls with shapes run at 60fps

## Verification Classes

- Contract verification: xcodebuild test (unit tests), build clean check
- Integration verification: Simulator launch + gameplay verification via screenshots
- Operational verification: App lifecycle (background/foreground), Game Center submission format
- UAT / human verification: Visual polish, game feel, color-blind mode usability

## Milestone Definition of Done

This milestone is complete only when all are true:

- All 6 bugs from audit are fixed and verified
- 60+ unit tests pass
- Game plays correctly on simulator (menu → play → game over → restart → share)
- Color-blind mode shows shape overlays
- Per-difficulty high scores work
- No source file exceeds 200 lines (GameScene split)
- All success criteria re-checked against live simulator behavior
- Final integrated acceptance scenarios pass

## Requirement Coverage

- Covers: R001, R002, R003, R004, R005, R006, R007, R008, R009, R010, R011, R012, R013, R014, R015, R016, R017, R018, R019, R020, R021, R022, R023
- Partially covers: none
- Leaves for later: R024, R025, R026, R027, R028, R029
- Orphan risks: none

## Slices

- [ ] **S01: Bug Fixes & Critical UX** `risk:high` `depends:[]`
  > After this: Game plays without race conditions or phantom life loss. Review prompt persists across sessions. Player can exit to menu from pause. Empty-space taps don't cost lives. Verified on simulator.

- [ ] **S02: Test Coverage Hardening** `risk:medium` `depends:[S01]`
  > After this: 30+ new unit tests covering GameState state machine, SettingsManager streak logic, BallNode hit testing, and engine edge cases. All 60+ tests green.

- [ ] **S03: UX Polish & Device Compatibility** `risk:medium` `depends:[S01]`
  > After this: Per-difficulty high scores display in menu. Target color indicator is prominent. Timer transitions are smooth. Layout works correctly from iPhone SE to Pro Max. Verified via simulator screenshots on multiple devices.

- [ ] **S04: Player Features** `risk:medium` `depends:[S01,S03]`
  > After this: Color-blind mode shows shape overlays on balls. Score sharing via share sheet works. Haptic toggle in settings. Quick restart skips countdown. Verified on simulator.

- [ ] **S05: Code Quality & Maintainability** `risk:low` `depends:[S01,S02]`
  > After this: GameScene split into focused modules (none >200 lines). Singletons replaced with protocols. DispatchQueue migrated to Task. All tests still pass after refactor.

## Boundary Map

### S01 → S02

Produces:
- Fixed `GameState` with clean phase transitions (no race conditions)
- Fixed `SettingsManager` with `gamesPlayed` persisted in UserDefaults
- Removed `musicEnabled` dead code from `AudioManager` and `SettingsManager`
- `GameScene.touchesBegan` only penalizes wrong-ball taps (not empty space)
- `GameView` uses GeometryReader instead of UIScreen.main
- Pause overlay includes "Home" button that navigates to main menu

Consumes:
- nothing (first slice)

### S01 → S03

Produces:
- Clean `SettingsManager` with persisted game counter
- `GameView` with GeometryReader-based sizing (S03 builds on this for device layouts)

Consumes:
- nothing (first slice)

### S01 → S04

Produces:
- Clean `GameState` phase transitions (S04 adds quick restart path)
- Clean `SettingsManager` (S04 adds haptic toggle property)

Consumes:
- nothing (first slice)

### S01 → S05

Produces:
- Fixed `GameScene` with correct touch handling and phase management
- All bug fixes in place so refactor doesn't need to work around bugs

Consumes:
- nothing (first slice)

### S02 → S05

Produces:
- Comprehensive test suite that serves as regression safety net for refactoring
- Tests for GameState, SettingsManager, BallNode, engine edge cases

Consumes from S01:
- Fixed GameState (tests validate the fixed behavior)
- Fixed SettingsManager (tests validate persisted gamesPlayed)

### S03 → S04

Produces:
- Per-difficulty high score infrastructure in SettingsManager
- Enlarged target color indicator (S04 adds color-blind shape overlay nearby)
- Device-adaptive layout (S04 features must work across devices)

Consumes from S01:
- GeometryReader-based GameView sizing
- Clean SettingsManager
