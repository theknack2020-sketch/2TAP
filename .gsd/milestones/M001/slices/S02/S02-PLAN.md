# S02: Scoring, Lives & Game Polish

**Goal:** Implement proper scoring with combo multiplier, difficulty progression (more balls at score thresholds), pause system, frame feedback (green/red flash), and 3D metallic ball rendering.
**Demo:** Score increases with combo, difficulty ramps up, pause works, frame flashes on result, balls look 3D metallic.

## Must-Haves
- Combo multiplier: consecutive correct rounds increase multiplier (x2, x3...), mistake resets to x1
- +1 life bonus every 10 consecutive perfect rounds
- Difficulty progression: ball count increases at score thresholds
- Pause system: 3 pauses per game, button on screen, freezes timer and hides balls
- Frame feedback: green flash on correct match, red flash on wrong/timeout
- 3D metallic ball rendering with shading, highlights, depth

## Tasks

- [x] **T01: Scoring Engine & Difficulty Progression**
  Proper combo multiplier scoring, +1 life every 10 perfect rounds, ball count increase at score thresholds.

- [x] **T02: Pause System**
  Pause button on game screen, 3 pauses per game, freezes timer, dims/hides balls.

- [x] **T03: Frame Feedback**
  Screen border green flash on correct, red flash on wrong/timeout. Brief, non-blocking.

- [x] **T04: 3D Metallic Ball Rendering**
  Replace basic circles with metallic-looking balls — radial gradient, specular highlight, shadow, depth.

## Files Likely Touched
- TwoTapGame/Game/GameScene.swift
- TwoTapGame/Game/GameState.swift
- TwoTapGame/Game/BallNode.swift
- TwoTapGame/Game/ScoreEngine.swift (new)
- TwoTapGame/Game/DifficultyEngine.swift (new)
- TwoTapGame/Views/GameView.swift
- TwoTapGame/Views/FrameFlashView.swift (new)
