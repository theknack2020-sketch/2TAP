# T02: Critical UX — pause Home button, empty-tap penalty removal

**Slice:** S01
**Milestone:** M001

## Goal
Fix 2 critical UX issues: add Home button to pause screen (R003), remove empty-space tap penalty (R004).

## Must-Haves

### Truths
- Pause overlay shows "Home" button that navigates to main menu
- Tapping empty space during gameplay does NOT cost a life
- Tapping a wrong-colored ball still costs a life
- Tapping a correct ball still works normally
- All 30+ existing tests pass

### Artifacts
- `Views/GameView.swift` — pause overlay includes Home button
- `Game/GameScene.swift` — touchesBegan ignores empty-space taps

### Key Links
- GameView.pauseOverlay → onHome callback
- GameScene.touchesBegan → only calls handleRoundFailure for wrong-ball taps

## Steps
1. Edit GameScene.touchesBegan — remove empty-space handleRoundFailure call, keep wrong-ball penalty
2. Edit GameView pauseOverlay — add Home button using onHome callback
3. Build and test
4. Install on simulator, verify: pause shows Home, empty taps do nothing, wrong ball still penalizes

## Context
- D001 decision: only penalize wrong-ball taps, not empty space
- GameView already has onHome callback — just need to wire it into pause overlay
- Pause overlay currently only has Resume button
