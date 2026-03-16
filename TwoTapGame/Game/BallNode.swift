import SpriteKit
import UIKit

/// A SpriteKit node representing a single colored ball with 3D metallic appearance.
///
/// Uses layered circles with gradients and highlights to create depth:
/// - Base circle with the ball color
/// - Dark edge ring for depth
/// - Radial gradient overlay for curvature
/// - Specular highlight (bright spot) for metallic shine
/// - Shadow underneath
class BallNode: SKNode {

    let ballId: Int
    let ballColor: UIColor
    let radius: CGFloat
    let isMatch: Bool
    private(set) var isTapped: Bool = false

    /// Speed multiplier for physics movement — set before animateAppear.
    var speedMultiplier: CGFloat = 1.0

    /// Shape index for color-blind mode — each unique color gets a different shape.
    var shapeIndex: Int = 0

    /// Whether to show shape overlay for accessibility.
    var showAccessibilityShape: Bool = false {
        didSet { updateAccessibilityShape() }
    }

    private let shadowNode: SKShapeNode
    private let baseCircle: SKShapeNode
    private let darkEdge: SKShapeNode
    private let gradientOverlay: SKShapeNode
    private let specularHighlight: SKShapeNode
    private let secondaryHighlight: SKShapeNode
    private var shapeOverlay: SKShapeNode?

    init(id: Int, color: UIColor, radius: CGFloat, isMatch: Bool) {
        self.ballId = id
        self.ballColor = color
        self.radius = radius
        self.isMatch = isMatch

        // Shadow underneath (offset down-right)
        shadowNode = SKShapeNode(circleOfRadius: radius * 0.92)
        shadowNode.fillColor = UIColor.black.withAlphaComponent(0.3)
        shadowNode.strokeColor = .clear
        shadowNode.position = CGPoint(x: radius * 0.08, y: -radius * 0.12)
        shadowNode.zPosition = -1

        // Base circle — main ball color
        baseCircle = SKShapeNode(circleOfRadius: radius)
        baseCircle.fillColor = color
        baseCircle.strokeColor = color.darker(by: 0.3)
        baseCircle.lineWidth = 1.5
        baseCircle.zPosition = 0

        // Dark edge ring — darker version of color around the perimeter
        darkEdge = SKShapeNode(circleOfRadius: radius * 0.95)
        darkEdge.fillColor = color.darker(by: 0.15)
        darkEdge.strokeColor = .clear
        darkEdge.zPosition = 1

        // Inner lighter area — creates the 3D curvature illusion
        gradientOverlay = SKShapeNode(circleOfRadius: radius * 0.82)
        gradientOverlay.fillColor = color.lighter(by: 0.1)
        gradientOverlay.strokeColor = .clear
        gradientOverlay.position = CGPoint(x: -radius * 0.05, y: radius * 0.05)
        gradientOverlay.zPosition = 2

        // Specular highlight — bright white spot (top-left)
        specularHighlight = SKShapeNode(ellipseOf: CGSize(
            width: radius * 0.45,
            height: radius * 0.3
        ))
        specularHighlight.fillColor = UIColor.white.withAlphaComponent(0.55)
        specularHighlight.strokeColor = .clear
        specularHighlight.position = CGPoint(x: -radius * 0.22, y: radius * 0.32)
        specularHighlight.zRotation = 0.3
        specularHighlight.zPosition = 3

        // Secondary smaller highlight
        secondaryHighlight = SKShapeNode(ellipseOf: CGSize(
            width: radius * 0.18,
            height: radius * 0.12
        ))
        secondaryHighlight.fillColor = UIColor.white.withAlphaComponent(0.3)
        secondaryHighlight.strokeColor = .clear
        secondaryHighlight.position = CGPoint(x: -radius * 0.35, y: radius * 0.15)
        secondaryHighlight.zPosition = 4

        super.init()

        self.name = "ball_\(id)"
        self.isUserInteractionEnabled = false

        addChild(shadowNode)
        addChild(baseCircle)
        addChild(darkEdge)
        addChild(gradientOverlay)
        addChild(specularHighlight)
        addChild(secondaryHighlight)

        // Physics body — for billiard-style wall bouncing
        let body = SKPhysicsBody(circleOfRadius: radius)
        body.isDynamic = true
        body.friction = 0
        body.restitution = 1.0       // perfect bounce off walls
        body.linearDamping = 0       // no slowdown
        body.angularDamping = 0
        body.allowsRotation = false
        body.mass = 1.0

        // Category: ball. Collide with walls only, not other balls.
        body.categoryBitMask =    0x1  // ball
        body.collisionBitMask =   0x2  // walls only
        body.contactTestBitMask = 0x0  // no contact events needed

        self.physicsBody = body
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Interaction

    /// Correct match tap: ball explodes with golden particle burst
    func tapCorrect() {
        guard !isTapped else { return }
        isTapped = true
        explode(particleColor: .systemYellow, burstColor: ballColor, style: .correct)
    }

    /// Wrong tap: ball explodes with red puff
    func tapWrong() {
        guard !isTapped else { return }
        isTapped = true
        explode(particleColor: .systemRed, burstColor: .red, style: .wrong)
    }

    /// Legacy — calls correct or wrong based on isMatch
    func tap() {
        if isMatch { tapCorrect() } else { tapWrong() }
    }

    func celebrateMatch() {
        // Already exploded via tapCorrect — no-op
        guard !isTapped else { return }
        tapCorrect()
    }

    func showError() {
        // Already exploded via tapWrong — shake the remains
        guard !isTapped else { return }
        tapWrong()
    }

    // MARK: - Explosion Effect

    private enum ExplosionStyle {
        case correct, wrong
    }

    private func explode(particleColor: UIColor, burstColor: UIColor, style: ExplosionStyle) {
        guard let parent = self.parent else { return }
        stopMoving() // freeze physics before explosion
        let worldPos = position

        // 1. Quick scale-up flash
        let flash = SKAction.scale(to: 1.4, duration: 0.06)
        flash.timingMode = .easeOut

        // 2. Fade out the ball itself
        let disappear = SKAction.group([
            SKAction.scale(to: 0.1, duration: 0.12),
            SKAction.fadeOut(withDuration: 0.1)
        ])

        run(SKAction.sequence([flash, disappear]))

        // 3. Burst ring (comic book style expanding circle)
        let ringRadius = radius * 2.5
        let ring = SKShapeNode(circleOfRadius: ringRadius)
        ring.strokeColor = burstColor.withAlphaComponent(0.8)
        ring.fillColor = .clear
        ring.lineWidth = style == .correct ? 3 : 2
        ring.position = worldPos
        ring.setScale(0.3)
        ring.alpha = 0.9
        ring.zPosition = 100
        parent.addChild(ring)

        let expandRing = SKAction.scale(to: 1.2, duration: 0.2)
        expandRing.timingMode = .easeOut
        let fadeRing = SKAction.fadeOut(withDuration: 0.15)
        ring.run(SKAction.sequence([
            SKAction.group([expandRing, fadeRing]),
            SKAction.removeFromParent()
        ]))

        // 4. Particle burst — small colored circles flying outward
        let particleCount = style == .correct ? 10 : 6
        for i in 0..<particleCount {
            let angle = (CGFloat(i) / CGFloat(particleCount)) * .pi * 2
                + CGFloat.random(in: -0.3...0.3)

            let particleSize = CGFloat.random(in: 3...7)
            let particle = SKShapeNode(circleOfRadius: particleSize)
            particle.fillColor = i % 3 == 0 ? .white : particleColor
            particle.strokeColor = .clear
            particle.position = worldPos
            particle.alpha = 0.9
            particle.zPosition = 101
            parent.addChild(particle)

            let distance = radius * CGFloat.random(in: 1.5...3.0)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance
            let dur = Double.random(in: 0.15...0.3)

            let move = SKAction.moveBy(x: dx, y: dy, duration: dur)
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: dur * 0.8)
            let shrink = SKAction.scale(to: 0.2, duration: dur)

            particle.run(SKAction.sequence([
                SKAction.group([move, fade, shrink]),
                SKAction.removeFromParent()
            ]))
        }

        // 5. Comic "starburst" spikes (correct only)
        if style == .correct {
            let spikeCount = 6
            for i in 0..<spikeCount {
                let angle = (CGFloat(i) / CGFloat(spikeCount)) * .pi * 2

                let spike = SKShapeNode()
                let path = CGMutablePath()
                // Thin triangle spike
                let length = radius * 1.8
                let width: CGFloat = 3
                path.move(to: CGPoint(x: 0, y: -width))
                path.addLine(to: CGPoint(x: length, y: 0))
                path.addLine(to: CGPoint(x: 0, y: width))
                path.closeSubpath()
                spike.path = path
                spike.fillColor = UIColor.white.withAlphaComponent(0.7)
                spike.strokeColor = .clear
                spike.position = worldPos
                spike.zRotation = angle
                spike.setScale(0.3)
                spike.alpha = 0.8
                spike.zPosition = 99
                parent.addChild(spike)

                let expand = SKAction.scale(to: 1.0, duration: 0.1)
                expand.timingMode = .easeOut
                let fade = SKAction.group([
                    SKAction.fadeOut(withDuration: 0.15),
                    SKAction.scale(to: 1.5, duration: 0.15)
                ])

                spike.run(SKAction.sequence([expand, fade, SKAction.removeFromParent()]))
            }
        }
    }

    func animateAppear(delay: TimeInterval = 0) {
        self.setScale(0)
        self.alpha = 0

        let wait = SKAction.wait(forDuration: delay)
        let scaleIn = SKAction.scale(to: 1.0, duration: 0.25)
        scaleIn.timingMode = .easeOut
        let fadeIn = SKAction.fadeIn(withDuration: 0.2)

        run(SKAction.sequence([
            wait,
            SKAction.group([scaleIn, fadeIn]),
            SKAction.run { [weak self] in
                guard let self else { return }
                self.startMoving(speedMultiplier: self.speedMultiplier)
                self.startShimmer()
            }
        ]))
    }

    // MARK: - Billiard Physics

    /// Give the ball a random initial velocity.
    /// Speed scales with difficulty mode — insane balls move faster.
    func startMoving(speedMultiplier: CGFloat = 1.0) {
        let baseMin: CGFloat = 25
        let baseMax: CGFloat = 50
        let speed = CGFloat.random(in: baseMin...baseMax) * speedMultiplier
        let angle = CGFloat.random(in: 0...(2 * .pi))
        physicsBody?.velocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
    }

    /// Stop all physics movement (for when ball is tapped/removed).
    func stopMoving() {
        physicsBody?.velocity = .zero
        physicsBody?.isDynamic = false
    }

    // MARK: - Specular Shimmer

    /// The specular highlight slowly drifts across the ball surface.
    private func startShimmer() {
        let dx = CGFloat.random(in: -3...3)
        let dy = CGFloat.random(in: -2...2)
        let dur = Double.random(in: 1.2...2.0)

        let shift = SKAction.sequence([
            SKAction.moveBy(x: dx, y: dy, duration: dur),
            SKAction.moveBy(x: -dx, y: -dy, duration: dur)
        ])
        shift.timingMode = .easeInEaseOut
        specularHighlight.run(SKAction.repeatForever(shift), withKey: "shimmer")

        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: dur * 0.7),
            SKAction.fadeAlpha(to: 0.6, duration: dur * 0.7)
        ])
        specularHighlight.run(SKAction.repeatForever(pulse), withKey: "shimmerPulse")
    }

    func animateDisappear(completion: @escaping () -> Void = {}) {
        let scaleOut = SKAction.scale(to: 0, duration: 0.2)
        scaleOut.timingMode = .easeIn
        let fadeOut = SKAction.fadeOut(withDuration: 0.15)
        let remove = SKAction.run { completion() }

        run(SKAction.sequence([SKAction.group([scaleOut, fadeOut]), remove]))
    }

    // MARK: - Color-Blind Shape Overlay

    /// Shapes for color-blind mode: each unique color gets a distinct geometric shape.
    private static let shapes: [(String, (CGFloat) -> CGPath)] = [
        ("circle", { r in CGPath(ellipseIn: CGRect(x: -r, y: -r, width: r*2, height: r*2), transform: nil) }),
        ("triangle", { r in
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: r))
            path.addLine(to: CGPoint(x: -r * 0.87, y: -r * 0.5))
            path.addLine(to: CGPoint(x: r * 0.87, y: -r * 0.5))
            path.closeSubpath()
            return path
        }),
        ("square", { r in
            let s = r * 0.7
            return CGPath(rect: CGRect(x: -s, y: -s, width: s*2, height: s*2), transform: nil)
        }),
        ("diamond", { r in
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: r))
            path.addLine(to: CGPoint(x: -r * 0.65, y: 0))
            path.addLine(to: CGPoint(x: 0, y: -r))
            path.addLine(to: CGPoint(x: r * 0.65, y: 0))
            path.closeSubpath()
            return path
        }),
        ("star", { r in
            let path = CGMutablePath()
            let points = 5
            for i in 0..<(points * 2) {
                let angle = CGFloat(i) * .pi / CGFloat(points) - .pi / 2
                let dist = i % 2 == 0 ? r : r * 0.4
                let pt = CGPoint(x: cos(angle) * dist, y: sin(angle) * dist)
                if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
            }
            path.closeSubpath()
            return path
        }),
        ("cross", { r in
            let path = CGMutablePath()
            let w = r * 0.25
            path.addRect(CGRect(x: -w, y: -r * 0.8, width: w*2, height: r*1.6))
            path.addRect(CGRect(x: -r * 0.8, y: -w, width: r*1.6, height: w*2))
            return path
        }),
        ("hexagon", { r in
            let path = CGMutablePath()
            for i in 0..<6 {
                let angle = CGFloat(i) * .pi / 3.0 - .pi / 6.0
                let pt = CGPoint(x: cos(angle) * r, y: sin(angle) * r)
                if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
            }
            path.closeSubpath()
            return path
        }),
        ("pentagon", { r in
            let path = CGMutablePath()
            for i in 0..<5 {
                let angle = CGFloat(i) * .pi * 2.0 / 5.0 - .pi / 2.0
                let pt = CGPoint(x: cos(angle) * r, y: sin(angle) * r)
                if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
            }
            path.closeSubpath()
            return path
        }),
    ]

    private func updateAccessibilityShape() {
        shapeOverlay?.removeFromParent()
        shapeOverlay = nil

        guard showAccessibilityShape else { return }

        let idx = shapeIndex % Self.shapes.count
        let shapeSize = radius * 0.5
        let path = Self.shapes[idx].1(shapeSize)

        let overlay = SKShapeNode(path: path)
        overlay.fillColor = .white.withAlphaComponent(0.85)
        overlay.strokeColor = .white
        overlay.lineWidth = 1.5
        overlay.zPosition = 5 // above specular highlight
        addChild(overlay)
        shapeOverlay = overlay
    }

    func hitTest(at point: CGPoint) -> Bool {
        let dx = point.x - position.x
        let dy = point.y - position.y
        let distance = sqrt(dx * dx + dy * dy)
        // Ensure minimum 44pt diameter touch target (Apple HIG)
        let touchRadius = max(radius, 22)
        return distance <= touchRadius
    }
}

// MARK: - UIColor Helpers

extension UIColor {
    /// Returns a darker version of the color.
    func darker(by percentage: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: s, brightness: max(b - percentage, 0), alpha: a)
    }

    /// Returns a lighter version of the color.
    func lighter(by percentage: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(
            hue: h,
            saturation: max(s - percentage * 0.3, 0),
            brightness: min(b + percentage, 1),
            alpha: a
        )
    }
}
