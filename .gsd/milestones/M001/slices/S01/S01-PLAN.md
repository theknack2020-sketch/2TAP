# S01: Core Game Engine

**Goal:** Build the foundational game engine — Xcode project, SpriteKit game scene, ball placement, color matching, touch detection, timer, countdown, and round cycling.
**Demo:** Balls appear on screen with non-overlapping placement, 3-2-1 countdown plays, 2s timer bar counts down, tapping balls registers correctly, rounds cycle.

## Must-Haves
- Xcode project builds clean with xcodebuild
- 5-7 balls appear on screen, non-overlapping, with finger-gap spacing
- One color repeats 2-3 times, rest are unique
- 3-2-1 countdown animates before game starts
- 2-second timer bar visually counts down
- Tapping a ball registers and provides visual feedback
- Tapping all matching balls within 2s triggers next round
- Timeout (2s expires) triggers round failure
- Rounds cycle: countdown → balls → play → result → next round

## Tasks

- [x] **T01: Xcode Project Scaffold**
  Set up the XcodeGen project with SwiftUI + SpriteKit, create directory structure, app entry point, and verify it builds on iOS simulator.

- [x] **T02: Ball Placement Engine**
  Implement the non-overlapping random ball placement algorithm with finger-gap spacing. Handles 5-12 balls within screen bounds.

- [x] **T03: Color Matching Engine**
  Implement round color generation — one color repeated 2-3 times, rest unique. Color palette system with metallic defaults.

- [x] **T04: Game Scene & Ball Rendering**
  Create SpriteKit game scene with ball nodes, touch detection, and basic visual feedback on tap. Wire into SwiftUI via SpriteView.

- [x] **T05: Timer, Countdown & Round Cycling**
  Implement 2-second timer bar, 3-2-1 countdown animation, round state machine (countdown → play → result → next), and basic tap validation (correct/wrong/timeout).

## Files Likely Touched
- project.yml (XcodeGen)
- TwoTapGame/App/TwoTapGameApp.swift
- TwoTapGame/Game/BallPlacementEngine.swift
- TwoTapGame/Game/ColorMatchEngine.swift
- TwoTapGame/Game/GameScene.swift
- TwoTapGame/Game/BallNode.swift
- TwoTapGame/Game/GameState.swift
- TwoTapGame/Views/GameView.swift
- TwoTapGame/Views/TimerBarView.swift
