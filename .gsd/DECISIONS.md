# Decisions Register

<!-- Append-only. Never edit or remove existing rows.
     To reverse a decision, add a new row that supersedes it.
     Read this file at the start of any planning or research phase. -->

| # | When | Scope | Decision | Choice | Rationale | Revisable? |
|---|------|-------|----------|--------|-----------|------------|
| D001 | M001 | arch | UI framework split | SwiftUI (menus/settings/HUD) + SpriteKit (game scene via SpriteView) | SwiftUI for declarative UI, SpriteKit for performant game rendering with touch detection | No |
| D002 | M001 | arch | State management | @Observable game manager shared between SwiftUI and SpriteKit | Modern iOS 17+ pattern, single source of truth | No |
| D003 | M001 | arch | Persistence | UserDefaults for scores and settings | Simple key-value storage sufficient for this scope, no relational data | Yes — if data grows complex |
| D004 | M001 | convention | Timer duration | 2 seconds, never changes | Game identity — "2TAP = 2 seconds". Sacred constraint. | No |
| D005 | M001 | convention | Max same-color balls | 3 per round maximum | User constraint — more than 3 same-color is too hard to tap in 2s | No |
| D006 | M001 | convention | Default color palette | Metallic/glossy 3D appearance | User preference for "craft feel", not flat circles | Yes — if user dislikes result |
| D007 | M001 | scope | Bölüm/level system | None — endless rounds | User explicitly rejected level structure. Difficulty via ball count increase at score thresholds | No |
| D008 | M001 | convention | Pause system | 3 pauses per game session total | Limited pauses prevent abuse, enough for real interruptions | No |
| D009 | M001 | convention | Life bonus | +1 life every 10 consecutive perfect rounds | Reward loop — keeps hope alive without making game too easy | Yes — if balance is off |
| D010 | M001 | arch | Asset generation | Gemini API at build time only | Game works offline. No runtime API dependency. | No |
| D011 | M001 | convention | UI language | English | User confirmed English UI | No |
| D012 | M001 | convention | Frame feedback | Green flash correct, red flash wrong — no rainbow/decorative borders | Feedback-driven design, not decorative. User chose function over aesthetics for border. | No |
| D013 | M001 | convention | Countdown | 3-2-1 at game start only, not between rounds | Between rounds: balls disappear → new balls appear immediately | Yes — if pacing feels wrong |
| D014 | M001 | convention | Tap order | No order required — tap all matching within 2s in any sequence | User confirmed sırasız dokunma | No |
