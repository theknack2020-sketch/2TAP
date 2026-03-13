# T04: Game Scene & Ball Rendering

**Slice:** S01
**Milestone:** M001

## Goal
Create the SpriteKit game scene with ball nodes, touch detection, and visual feedback on tap. Wire into SwiftUI via SpriteView. Balls appear using placement engine positions and colors from color engine.

## Must-Haves

### Truths
- SpriteKit scene renders balls at positions from BallPlacementEngine
- Each ball displays its assigned color from ColorMatchEngine
- Tapping a ball triggers visual feedback (scale/opacity animation)
- Tapping empty space does nothing
- Scene is embedded in SwiftUI view via SpriteView
- Balls render as circles with basic shading (full 3D metallic in S02)

### Artifacts
- `TwoTapGame/Game/GameScene.swift` — SKScene subclass with ball management and touch handling (min 100 lines)
- `TwoTapGame/Game/BallNode.swift` — SKNode subclass for individual balls with tap state (min 40 lines)
- `TwoTapGame/Game/GameState.swift` — @Observable game state shared between SpriteKit and SwiftUI (min 30 lines)
- `TwoTapGame/Views/GameView.swift` — SwiftUI wrapper with SpriteView (min 20 lines)

### Key Links
- `GameScene.swift` → `BallPlacementEngine.swift` via generatePositions call
- `GameScene.swift` → `ColorMatchEngine.swift` via generateRound call
- `GameScene.swift` → `BallNode.swift` via addChild for each ball
- `GameView.swift` → `GameScene.swift` via SpriteView embedding
- `GameView.swift` → `GameState.swift` via @State/@Environment binding

## Steps
1. Create GameState @Observable class: roundActive, tappedBalls, currentRound colors/positions
2. Create BallNode: SKShapeNode circle with fill color, name tag, tap state, scale animation on tap
3. Create GameScene: spawn balls using both engines, handle touchesBegan, track tapped balls
4. Create GameView: SpriteView wrapper, pass GameState
5. Wire ContentView to show GameView
6. Build and verify: balls appear, tapping works, visual feedback shows

## Context
- SpriteKit coordinate system: origin at bottom-left (flip Y from SwiftUI)
- SpriteView isPaused control for future pause system
- GameState is the bridge between SpriteKit and SwiftUI worlds
- Basic circle rendering now; 3D metallic shader added in S02/T01
