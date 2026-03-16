# S02: Test Coverage Hardening

**Goal:** Add 30+ new unit tests covering GameState, SettingsManager, BallNode, and engine edge cases.
**Demo:** 60+ total tests all green. Critical state machine, streak logic, hit testing, and edge cases covered.

## Must-Haves
- GameState tests: reset(), markBallTapped(), allMatchesTapped, matchCount, tappedMatchCount
- SettingsManager tests: recordGamePlayed() streak logic, updateHighScore, date edge cases
- BallNode tests: hitTest including 44pt minimum, edge cases
- Engine edge cases: zero/negative combos, boundary thresholds, palette validation, impossible placements
- Total test count ≥60
- All tests pass

## Tasks

- [ ] **T01: GameState + SettingsManager tests**
  Unit tests for the two critical untested @Observable classes.

- [ ] **T02: BallNode + engine edge case tests**
  Hit testing validation and edge cases for all four engines.

## Files Likely Touched
- TwoTapGameTests/GameStateTests.swift (new)
- TwoTapGameTests/SettingsManagerTests.swift (new)
- TwoTapGameTests/BallNodeTests.swift (new)
- TwoTapGameTests/ScoreEngineTests.swift (additions)
- TwoTapGameTests/DifficultyEngineTests.swift (additions)
- TwoTapGameTests/BallPlacementEngineTests.swift (additions)
- TwoTapGameTests/ColorMatchEngineTests.swift (additions)
