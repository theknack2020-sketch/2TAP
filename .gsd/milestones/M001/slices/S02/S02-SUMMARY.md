---
id: S02
parent: M001
provides:
  - ScoreEngine — combo multiplier (x1-x10), base 100pts, bonus life every 10 perfect
  - DifficultyEngine — ball count 5→12 at score thresholds
  - Pause system — 3 pauses per game, overlay, freezes scene
  - Frame flash feedback — green border on success, red on failure
  - 3D metallic ball rendering — layered circles, specular highlight, shadow, depth
requires:
  - slice: S01
    provides: GameScene, GameState, BallNode, ColorMatchEngine, BallPlacementEngine
affects: [S04]
key_files:
  - TwoTapGame/Game/ScoreEngine.swift
  - TwoTapGame/Game/DifficultyEngine.swift
  - TwoTapGame/Game/BallNode.swift
  - TwoTapGame/Game/GameScene.swift
  - TwoTapGame/Game/GameState.swift
  - TwoTapGame/Views/GameView.swift
key_decisions:
  - "Base points 100, combo multiplier capped at x10"
  - "Difficulty thresholds: 0→5balls, 500→6, 1200→7, 2500→8, 4000→9, 6000→10, 9000→11, 13000→12"
  - "3D balls via layered SKShapeNodes (shadow + base + darkEdge + gradient + specular)"
  - "Always 3 matching balls per round (2 removed as too easy)"
patterns_established:
  - "Engine structs for game logic (ScoreEngine, DifficultyEngine) — stateless, testable"
  - "GameState.flashColor triggers SwiftUI onChange → frame flash animation"
drill_down_paths:
  - .gsd/milestones/M001/slices/S02/S02-PLAN.md
duration: ~25min
verification_result: pass
completed_at: 2026-03-14T01:08:00Z
---

# S02: Scoring, Lives & Game Polish

**Combo scoring (x1-x10), difficulty progression (5→12 balls), pause system, frame flash feedback, and 3D metallic ball rendering — all deployed to device.**

## What Happened

Added ScoreEngine (100 base × combo, capped at x10, bonus life every 10 perfect) and DifficultyEngine (ball count increases at 7 score thresholds from 5 to 12). Pause system gives 3 pauses per game with overlay. Frame flashes green/red on success/failure via SwiftUI border animation.

BallNode rebuilt with 6 layered SKShapeNodes: shadow underneath, base color, darker edge ring, lighter gradient overlay, elliptical specular highlight, secondary highlight — creates convincing 3D metallic appearance. UIColor helpers (darker/lighter by percentage) support the shading.

Game over screen now shows score, best combo, rounds survived, and difficulty level name.

## Deviations
- Always 3 matching balls (removed 2-match option — user confirmed too easy)

## Files Created/Modified
- `TwoTapGame/Game/ScoreEngine.swift` — scoring logic (35 lines)
- `TwoTapGame/Game/DifficultyEngine.swift` — difficulty progression (55 lines)
- `TwoTapGame/Game/BallNode.swift` — rebuilt with 3D metallic rendering (190 lines)
- `TwoTapGame/Game/GameScene.swift` — integrated ScoreEngine + DifficultyEngine
- `TwoTapGame/Game/GameState.swift` — added consecutivePerfect, flashColor
- `TwoTapGame/Views/GameView.swift` — pause overlay, frame flash, combo badge, dynamic lives
- `TwoTapGameTests/ScoreEngineTests.swift` — 4 tests
