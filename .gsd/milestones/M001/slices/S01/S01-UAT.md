# S01: Bug Fixes & Critical UX — UAT

## Test Script

1. **Review prompt persistence:** Play 4 games, force-quit app, relaunch, play 1 more game with score ≥500 — review prompt should appear
2. **No race condition:** Die on a round, immediately tap "Play Again" from game over — no phantom life loss on new game
3. **Pause Home button:** During gameplay, tap pause → verify "Home" button appears → tap it → returns to main menu
4. **Empty-space tap:** During gameplay, tap empty space between balls — no life lost, no penalty sound
5. **Wrong-ball tap:** During gameplay, tap a wrong-colored ball — life lost, penalty sound plays
6. **Scene sizing:** Verify game fills the full screen correctly on different devices (SE, Pro, Pro Max)
