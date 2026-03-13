# T03: Color Matching Engine

**Slice:** S01
**Milestone:** M001

## Goal
Implement round color generation — each round produces a set of colors where exactly one color repeats (2 or 3 times) and all others are unique. Support multiple color palettes with metallic as default.

## Must-Haves

### Truths
- Each generated round has exactly one color repeated 2 or 3 times
- All non-repeated colors are visually distinct from each other and from the repeated color
- Color palette system supports switching palettes
- Metallic palette is default with rich, complex colors (not primary-only)

### Artifacts
- `TwoTapGame/Game/ColorMatchEngine.swift` — color generation logic (min 80 lines)
- `TwoTapGame/Models/ColorPalette.swift` — palette definitions with metallic default

### Key Links
- `ColorMatchEngine.swift` consumed by `GameScene.swift` in T04 for ball coloring
- `ColorPalette.swift` consumed by settings (S03) for palette selection

## Steps
1. Define ColorPalette struct with array of base colors + name
2. Create metallic palette: 15-20 rich, distinguishable colors (gold, copper, emerald, sapphire, ruby, etc.)
3. Implement `generateRound(ballCount:palette:) -> [ColorAssignment]` that picks colors ensuring exactly one repeat
4. Add minimum color distance check (in HSB space) to prevent too-similar colors in same round
5. Write unit tests: verify exactly one repeat per round, verify uniqueness of non-repeats, verify color distance

## Context
- D005: Max 3 of same color per round
- D006: Default palette is metallic/glossy
- Color distance matters for difficulty — closer colors = harder (future S02 will add difficulty-based similarity)
- Colors defined as UIColor/Color values for both SpriteKit and SwiftUI consumption
