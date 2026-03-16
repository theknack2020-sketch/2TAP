# Requirements

## Active

### R001 — Fix broken App Store review prompt
- Class: launchability
- Status: active
- Description: Review prompt counter must persist across sessions (currently resets every GameView creation due to @State)
- Why it matters: App Store reviews are critical for discoverability — prompt never fires currently
- Source: execution
- Primary owning slice: M001/S01
- Supporting slices: none
- Validation: unmapped
- Notes: Move gamesPlayed to UserDefaults via SettingsManager

### R002 — Fix race condition in round failure handling
- Class: core-capability
- Status: active
- Description: handleRoundFailure uses Task.sleep then checks state.phase — startGame() can be called during sleep creating a race
- Why it matters: Can cause phantom life loss or state corruption
- Source: execution
- Primary owning slice: M001/S01
- Supporting slices: none
- Validation: unmapped
- Notes: Use task cancellation pattern

### R003 — Add Home button to pause screen
- Class: primary-user-loop
- Status: active
- Description: Player must be able to exit to main menu from pause screen without losing all lives
- Why it matters: Players feel trapped — no way to exit mid-game
- Source: inferred
- Primary owning slice: M001/S01
- Supporting slices: none
- Validation: unmapped
- Notes: none

### R004 — Soften empty-space tap penalty
- Class: primary-user-loop
- Status: active
- Description: Tapping empty space between balls should not cost a life — only tapping a wrong-colored ball should penalize
- Why it matters: Moving balls + tight spacing = many accidental "misses" that feel unfair
- Source: inferred
- Primary owning slice: M001/S01
- Supporting slices: none
- Validation: unmapped
- Notes: Consider grace period or only penalize wrong-ball taps

### R005 — Fix deprecated UIScreen.main usage
- Class: quality-attribute
- Status: active
- Description: Replace UIScreen.main.bounds with GeometryReader for scene sizing
- Why it matters: Deprecated in iOS 16, may break in future OS versions
- Source: execution
- Primary owning slice: M001/S01
- Supporting slices: none
- Validation: unmapped
- Notes: none

### R006 — Clean up dead musicEnabled code
- Class: quality-attribute
- Status: active
- Description: Remove musicEnabled property and related no-op methods from AudioManager and SettingsManager
- Why it matters: Dead code confuses future maintenance
- Source: execution
- Primary owning slice: M001/S01
- Supporting slices: none
- Validation: unmapped
- Notes: startMusic/stopMusic/updateMusicState are all no-ops

### R007 — GameState unit tests
- Class: quality-attribute
- Status: active
- Description: Unit tests for reset(), markBallTapped(), allMatchesTapped, matchCount, tappedMatchCount
- Why it matters: Central state machine with zero tests — bugs here break every game
- Source: inferred
- Primary owning slice: M001/S02
- Supporting slices: none
- Validation: unmapped
- Notes: Pure logic, trivially testable

### R008 — SettingsManager streak logic tests
- Class: quality-attribute
- Status: active
- Description: Tests for recordGamePlayed(), updateStreak(), date edge cases
- Why it matters: Date arithmetic bugs are classic — "my streak reset for no reason" App Store reviews
- Source: inferred
- Primary owning slice: M001/S02
- Supporting slices: none
- Validation: unmapped
- Notes: Inject Date provider for testability

### R009 — BallNode hit testing tests
- Class: quality-attribute
- Status: active
- Description: Tests for hitTest(at:) including 44pt minimum touch target, edge cases
- Why it matters: Determines if player taps register correctly
- Source: inferred
- Primary owning slice: M001/S02
- Supporting slices: none
- Validation: unmapped
- Notes: none

### R010 — Edge case tests for engines
- Class: quality-attribute
- Status: active
- Description: Tests for zero/negative combos, boundary score thresholds, palette size validation, impossible placements
- Why it matters: Untested edge cases silently produce wrong results
- Source: inferred
- Primary owning slice: M001/S02
- Supporting slices: none
- Validation: unmapped
- Notes: none

### R011 — Per-difficulty high scores and leaderboards
- Class: primary-user-loop
- Status: active
- Description: Separate high score tracking and Game Center leaderboards for Easy, Normal, and Insane
- Why it matters: Single leaderboard unfairly mixes difficulty levels
- Source: user
- Primary owning slice: M001/S03
- Supporting slices: none
- Validation: unmapped
- Notes: Requires 3 leaderboard IDs in Game Center

### R012 — Enlarge target color indicator
- Class: primary-user-loop
- Status: active
- Description: Make the "FIND [color] ×N" indicator larger and more prominent
- Why it matters: 22pt circle on busy screen — players miss it especially on first plays
- Source: inferred
- Primary owning slice: M001/S03
- Supporting slices: none
- Validation: unmapped
- Notes: none

### R013 — Smooth timer bar transitions between rounds
- Class: quality-attribute
- Status: active
- Description: Timer bar should transition smoothly between rounds instead of blinking in/out
- Why it matters: Jarring visual gap breaks immersion
- Source: inferred
- Primary owning slice: M001/S03
- Supporting slices: none
- Validation: unmapped
- Notes: none

### R014 — Replace magic numbers with named constants
- Class: quality-attribute
- Status: active
- Description: Extract hudTopInset=160, wallInset=40, Spacer(58), timing values into named constants
- Why it matters: Readability, maintainability, device adaptability
- Source: execution
- Primary owning slice: M001/S03
- Supporting slices: M001/S05
- Validation: unmapped
- Notes: none

### R015 — Fix device-specific layout issues
- Class: launchability
- Status: active
- Description: Replace hardcoded Spacer(height:58) with safe area-aware layout that works on SE through Pro Max
- Why it matters: Current layout breaks on different device sizes
- Source: execution
- Primary owning slice: M001/S03
- Supporting slices: none
- Validation: unmapped
- Notes: none

### R016 — Color-blind accessibility mode
- Class: differentiator
- Status: active
- Description: Add shape/pattern overlays to balls so color-blind players can distinguish them. Respect system Differentiate Without Color setting.
- Why it matters: Color-matching game is unplayable for ~8% of male players without this
- Source: inferred
- Primary owning slice: M001/S04
- Supporting slices: none
- Validation: unmapped
- Notes: Use Apple's accessibilityDifferentiateWithoutColor API

### R017 — Score sharing via share sheet
- Class: primary-user-loop
- Status: active
- Description: Share score card image via iOS share sheet from game over screen
- Why it matters: Social sharing drives organic installs
- Source: inferred
- Primary owning slice: M001/S04
- Supporting slices: none
- Validation: unmapped
- Notes: none

### R018 — Haptic feedback toggle in settings
- Class: primary-user-loop
- Status: active
- Description: Add on/off toggle for haptic feedback in Settings
- Why it matters: Some players find haptics distracting; currently no way to disable
- Source: inferred
- Primary owning slice: M001/S04
- Supporting slices: none
- Validation: unmapped
- Notes: none

### R019 — Quick restart from game over
- Class: primary-user-loop
- Status: active
- Description: One-tap restart button on game over screen that skips countdown
- Why it matters: Repeated deaths + countdown = friction that makes players quit
- Source: inferred
- Primary owning slice: M001/S04
- Supporting slices: none
- Validation: unmapped
- Notes: none

### R020 — Break up GameScene god-class
- Class: quality-attribute
- Status: active
- Description: Extract timer management, touch handling, ball spawning, and physics into focused modules
- Why it matters: 380-line class doing everything — unmaintainable
- Source: execution
- Primary owning slice: M001/S05
- Supporting slices: none
- Validation: unmapped
- Notes: Must not change behavior — refactor only

### R021 — Replace singletons with protocol-based DI
- Class: quality-attribute
- Status: active
- Description: AudioManager, HapticManager, GameCenterManager should be protocol-based and injectable
- Why it matters: Singletons block testing and make behavior unpredictable
- Source: execution
- Primary owning slice: M001/S05
- Supporting slices: M001/S02
- Validation: unmapped
- Notes: SettingsManager already uses .environment() — extend pattern

### R022 — Migrate DispatchQueue.main.asyncAfter to Task
- Class: quality-attribute
- Status: active
- Description: Replace DispatchQueue.main.asyncAfter calls in SwiftUI views with Task.sleep for cancellation safety
- Why it matters: Non-cancellable timers can fire after view dismissal
- Source: execution
- Primary owning slice: M001/S05
- Supporting slices: none
- Validation: unmapped
- Notes: none

### R023 — Reuse HapticManager generators
- Class: quality-attribute
- Status: active
- Description: Create haptic generators once and reuse them instead of creating new ones per event
- Why it matters: Apple recommends reuse for performance
- Source: execution
- Primary owning slice: M001/S05
- Supporting slices: none
- Validation: unmapped
- Notes: none

## Deferred

### R024 — Background music implementation
- Class: differentiator
- Status: deferred
- Description: Implement the stubbed background music system
- Why it matters: Adds atmosphere, but gameplay works without it
- Source: execution
- Primary owning slice: none
- Supporting slices: none
- Validation: unmapped
- Notes: Stubs exist in AudioManager — low priority vs gameplay fixes

### R025 — Localization / multi-language
- Class: launchability
- Status: deferred
- Description: Extract hardcoded English strings to Localizable.strings
- Why it matters: Limits international reach
- Source: inferred
- Primary owning slice: none
- Supporting slices: none
- Validation: unmapped
- Notes: English-only acceptable for initial improvement pass

### R026 — Analytics / crash reporting
- Class: operability
- Status: deferred
- Description: Add Firebase/Sentry for crash reporting and usage analytics
- Why it matters: Invisible crashes and usage patterns
- Source: inferred
- Primary owning slice: none
- Supporting slices: none
- Validation: unmapped
- Notes: Post-launch concern

### R027 — Game Center achievements
- Class: differentiator
- Status: deferred
- Description: Add achievements for milestones (first 100 score, 10 combo streak, etc.)
- Why it matters: Engagement and retention driver
- Source: inferred
- Primary owning slice: none
- Supporting slices: none
- Validation: unmapped
- Notes: Nice-to-have after core improvements

### R028 — Practice / tutorial mode
- Class: primary-user-loop
- Status: deferred
- Description: Slow-paced practice round for new players
- Why it matters: Onboarding explains but doesn't let you try
- Source: inferred
- Primary owning slice: none
- Supporting slices: none
- Validation: unmapped
- Notes: Existing onboarding is sufficient for now

### R029 — Widget / Live Activity
- Class: differentiator
- Status: deferred
- Description: Home screen widget showing daily streak or high score
- Why it matters: Re-engagement surface
- Source: inferred
- Primary owning slice: none
- Supporting slices: none
- Validation: unmapped
- Notes: Post-launch feature

## Out of Scope

### R030 — In-app purchases / monetization
- Class: anti-feature
- Status: out-of-scope
- Description: No ads, IAP, or premium content
- Why it matters: Not requested, would change product direction
- Source: inferred
- Primary owning slice: none
- Supporting slices: none
- Validation: n/a
- Notes: Free game, no monetization

### R031 — Multiplayer / friend challenges
- Class: core-capability
- Status: out-of-scope
- Description: No real-time or async multiplayer
- Why it matters: Different product direction entirely
- Source: inferred
- Primary owning slice: none
- Supporting slices: none
- Validation: n/a
- Notes: Single-player focus

### R032 — CloudKit sync
- Class: continuity
- Status: out-of-scope
- Description: No cross-device score sync
- Why it matters: UserDefaults sufficient for current scale
- Source: inferred
- Primary owning slice: none
- Supporting slices: none
- Validation: n/a
- Notes: Game Center handles leaderboard persistence

## Traceability

| ID | Class | Status | Primary owner | Supporting | Proof |
|---|---|---|---|---|---|
| R001 | launchability | active | M001/S01 | none | unmapped |
| R002 | core-capability | active | M001/S01 | none | unmapped |
| R003 | primary-user-loop | active | M001/S01 | none | unmapped |
| R004 | primary-user-loop | active | M001/S01 | none | unmapped |
| R005 | quality-attribute | active | M001/S01 | none | unmapped |
| R006 | quality-attribute | active | M001/S01 | none | unmapped |
| R007 | quality-attribute | active | M001/S02 | none | unmapped |
| R008 | quality-attribute | active | M001/S02 | none | unmapped |
| R009 | quality-attribute | active | M001/S02 | none | unmapped |
| R010 | quality-attribute | active | M001/S02 | none | unmapped |
| R011 | primary-user-loop | active | M001/S03 | none | unmapped |
| R012 | primary-user-loop | active | M001/S03 | none | unmapped |
| R013 | quality-attribute | active | M001/S03 | none | unmapped |
| R014 | quality-attribute | active | M001/S03 | M001/S05 | unmapped |
| R015 | launchability | active | M001/S03 | none | unmapped |
| R016 | differentiator | active | M001/S04 | none | unmapped |
| R017 | primary-user-loop | active | M001/S04 | none | unmapped |
| R018 | primary-user-loop | active | M001/S04 | none | unmapped |
| R019 | primary-user-loop | active | M001/S04 | none | unmapped |
| R020 | quality-attribute | active | M001/S05 | none | unmapped |
| R021 | quality-attribute | active | M001/S05 | M001/S02 | unmapped |
| R022 | quality-attribute | active | M001/S05 | none | unmapped |
| R023 | quality-attribute | active | M001/S05 | none | unmapped |
| R024 | differentiator | deferred | none | none | unmapped |
| R025 | launchability | deferred | none | none | unmapped |
| R026 | operability | deferred | none | none | unmapped |
| R027 | differentiator | deferred | none | none | unmapped |
| R028 | primary-user-loop | deferred | none | none | unmapped |
| R029 | differentiator | deferred | none | none | unmapped |
| R030 | anti-feature | out-of-scope | none | none | n/a |
| R031 | core-capability | out-of-scope | none | none | n/a |
| R032 | continuity | out-of-scope | none | none | n/a |

## Coverage Summary

- Active requirements: 23
- Mapped to slices: 23
- Validated: 0
- Unmapped active requirements: 0
