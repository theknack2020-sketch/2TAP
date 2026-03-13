# T05: Timer, Countdown & Round Cycling

**Slice:** S01
**Milestone:** M001

## Goal
Implement the complete round lifecycle: 3-2-1 countdown → balls appear → 2-second timer → tap validation → result → next round. Timer bar visually shows remaining time.

## Must-Haves

### Truths
- 3-2-1 countdown appears as large green text, center screen, before first round
- After countdown, balls appear and 2-second timer starts immediately
- Timer bar at top of screen drains from full to empty over exactly 2 seconds
- Tapping all matching-color balls before timeout = round success → new balls appear
- Timer expiring before all matches tapped = round failure
- Tapping a wrong ball (non-matching color) = immediate round failure
- Between rounds: balls disappear → new balls appear (no countdown between rounds, only at game start)
- Round state machine: idle → countdown → playing → success/failure → playing (next round)

### Artifacts
- `TwoTapGame/Views/TimerBarView.swift` — SwiftUI timer bar overlay (min 30 lines)
- `TwoTapGame/Views/CountdownView.swift` — SwiftUI countdown overlay (min 25 lines)
- Updates to `GameScene.swift` — round lifecycle management, timer logic
- Updates to `GameState.swift` — round phase enum, timer value, round results

### Key Links
- `GameScene.swift` → `GameState.swift` via phase transitions (countdown → playing → result)
- `TimerBarView.swift` → `GameState.swift` via timerProgress binding
- `CountdownView.swift` → `GameState.swift` via phase == .countdown
- `GameView.swift` → `TimerBarView.swift` + `CountdownView.swift` as overlays

## Steps
1. Add RoundPhase enum to GameState: idle, countdown, playing, success, failure
2. Add timer properties: timerProgress (1.0 → 0.0), timerDuration = 2.0
3. Implement countdown: large "3", "2", "1" text with scale animation, then transition to playing
4. Implement timer in GameScene update loop: decrement based on deltaTime, update GameState
5. Create TimerBarView: horizontal bar that shrinks based on timerProgress, color gradient
6. Create CountdownView: large centered number with animation
7. Implement tap validation in GameScene: track which balls are tapped, check if all matches found
8. Implement round cycling: on success → clear balls → generate new round → start timer; on failure → flash feedback
9. Wire overlays into GameView as ZStack layers
10. Build and test full cycle: countdown → play → tap → next round

## Context
- D004: Timer is always 2 seconds, sacred
- D013: Countdown only at game start, not between rounds
- D014: Tap order doesn't matter — all matches within 2s
- Timer precision matters — use SKScene update deltaTime, not Foundation Timer
- TimerBar and Countdown are SwiftUI overlays on top of SpriteView for smooth rendering
