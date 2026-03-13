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

    private let shadowNode: SKShapeNode
    private let baseCircle: SKShapeNode
    private let darkEdge: SKShapeNode
    private let gradientOverlay: SKShapeNode
    private let specularHighlight: SKShapeNode
    private let secondaryHighlight: SKShapeNode

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
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Interaction

    func tap() {
        guard !isTapped else { return }
        isTapped = true

        let scaleUp = SKAction.scale(to: 1.15, duration: 0.06)
        let scaleDown = SKAction.scale(to: 0.92, duration: 0.08)
        let scaleNormal = SKAction.scale(to: 1.0, duration: 0.05)
        let dim = SKAction.fadeAlpha(to: 0.55, duration: 0.12)

        let bounceSequence = SKAction.sequence([scaleUp, scaleDown, scaleNormal])
        run(SKAction.group([bounceSequence, dim]))
    }

    func celebrateMatch() {
        let scaleUp = SKAction.scale(to: 1.3, duration: 0.15)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        run(SKAction.sequence([scaleUp, fadeOut]))
    }

    func showError() {
        let originalColor = baseCircle.fillColor

        let toRed = SKAction.run { [weak self] in
            self?.baseCircle.fillColor = .red
            self?.darkEdge.fillColor = UIColor.red.darker(by: 0.2)
            self?.gradientOverlay.fillColor = UIColor.red.lighter(by: 0.1)
        }
        let wait = SKAction.wait(forDuration: 0.15)
        let restore = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.baseCircle.fillColor = originalColor
            self.darkEdge.fillColor = originalColor.darker(by: 0.15)
            self.gradientOverlay.fillColor = originalColor.lighter(by: 0.1)
        }

        let moveLeft = SKAction.moveBy(x: -8, y: 0, duration: 0.04)
        let moveRight = SKAction.moveBy(x: 16, y: 0, duration: 0.08)
        let moveCenter = SKAction.moveBy(x: -8, y: 0, duration: 0.04)
        let shake = SKAction.sequence([moveLeft, moveRight, moveCenter])

        run(SKAction.group([
            SKAction.sequence([toRed, wait, restore]),
            shake
        ]))
    }

    func animateAppear(delay: TimeInterval = 0) {
        self.setScale(0)
        self.alpha = 0

        let wait = SKAction.wait(forDuration: delay)
        let scaleIn = SKAction.scale(to: 1.0, duration: 0.25)
        scaleIn.timingMode = .easeOut
        let fadeIn = SKAction.fadeIn(withDuration: 0.2)

        run(SKAction.sequence([wait, SKAction.group([scaleIn, fadeIn])]))
    }

    func animateDisappear(completion: @escaping () -> Void = {}) {
        let scaleOut = SKAction.scale(to: 0, duration: 0.2)
        scaleOut.timingMode = .easeIn
        let fadeOut = SKAction.fadeOut(withDuration: 0.15)
        let remove = SKAction.run { completion() }

        run(SKAction.sequence([SKAction.group([scaleOut, fadeOut]), remove]))
    }

    func hitTest(at point: CGPoint) -> Bool {
        let dx = point.x - position.x
        let dy = point.y - position.y
        let distance = sqrt(dx * dx + dy * dy)
        return distance <= radius
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
