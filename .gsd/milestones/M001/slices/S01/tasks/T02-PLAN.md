# T02: Ball Placement Engine

**Slice:** S01
**Milestone:** M001

## Goal
Implement a non-overlapping random ball placement algorithm that positions 5-12+ balls within the playable area, ensuring at least a finger-tap gap between each ball and screen edges.

## Must-Haves

### Truths
- Given a screen size and ball count (5-12), placement always produces valid non-overlapping positions
- Minimum gap between any two ball edges >= 44pt (finger tap target)
- No ball clips the screen edges (minimum 20pt margin from safe area)
- Algorithm completes in < 50ms for 12 balls (no perceptible lag)

### Artifacts
- `TwoTapGame/Game/BallPlacementEngine.swift` — placement algorithm (min 60 lines, pure logic, no UI dependencies)

### Key Links
- `BallPlacementEngine.swift` is pure logic — consumed by `GameScene.swift` in T04

## Steps
1. Define BallPlacementEngine struct with `generatePositions(count:ballRadius:screenSize:safeArea:) -> [CGPoint]`
2. Implement rejection-sampling placement: pick random position, check against all placed balls for minimum distance, retry if overlap
3. Add max-retry limit with fallback grid-based placement if random fails
4. Add screen edge margin enforcement
5. Write unit tests for: 5 balls, 7 balls, 12 balls, edge cases (tiny screen)
6. Verify performance with 12 balls

## Context
- Ball radius ~30-40pt depending on screen size
- Minimum gap between ball edges: 44pt (Apple's touch target minimum)
- Playable area excludes top (timer bar) and any HUD elements
- Must work on iPhone SE (smallest screen) through iPhone Pro Max
