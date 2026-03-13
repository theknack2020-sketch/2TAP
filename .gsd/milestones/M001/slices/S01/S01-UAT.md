# S01: Core Game Engine — UAT

## Test Script

### 1. App Launch
- [ ] Open 2TAP on your iPhone
- [ ] App launches without crash

### 2. Countdown
- [ ] Large green "3" appears center screen
- [ ] Counts down: 3 → 2 → 1
- [ ] After "1", balls appear on screen

### 3. Balls
- [ ] 5 colored balls visible on screen
- [ ] Balls don't overlap each other
- [ ] Balls don't touch screen edges
- [ ] Each ball has a distinct color
- [ ] One color appears on exactly 2 (or 3) balls

### 4. Timer
- [ ] Timer bar visible at top of screen
- [ ] Timer bar shrinks over ~2 seconds
- [ ] Bar changes color: green → orange → red

### 5. Tapping
- [ ] Tapping a ball gives visual feedback (bounce + dim)
- [ ] Tapping empty space does nothing
- [ ] Tapping all matching-color balls within time → new balls appear
- [ ] Tapping a wrong color ball → life lost

### 6. Round Cycling
- [ ] After correct match, new set of balls appears immediately (no countdown)
- [ ] Score increases after correct match
- [ ] After wrong tap, brief pause then next round
- [ ] Lives display shows remaining hearts (3 hearts at start)

### 7. Game Over
- [ ] When all 3 lives lost, "GAME OVER" appears
- [ ] Score displayed
- [ ] "Play Again" button works — restarts the game
