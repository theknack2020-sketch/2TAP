import SpriteKit
import UIKit

/// A SpriteKit node representing a single colored ball.
///
/// Renders as a filled circle with basic gradient shading.
/// Full 3D metallic rendering is added in S02.
class BallNode: SKNode {

    let ballId: Int
    let ballColor: UIColor
    let radius: CGFloat
    let isMatch: Bool
    private(set) var isTapped: Bool = false

    private let circleNode: SKShapeNode
    private let highlightNode: SKShapeNode

    init(id: Int, color: UIColor, radius: CGFloat, isMatch: Bool) {
        self.ballId = id
        self.ballColor = color
        self.radius = radius
        self.isMatch = isMatch

        // Main circle
        circleNode = SKShapeNode(circleOfRadius: radius)
        circleNode.fillColor = color
        circleNode.strokeColor = color.withAlphaComponent(0.6)
        circleNode.lineWidth = 2.0

        // Simple highlight for 3D-ish effect (top-left bright spot)
        let highlightRadius = radius * 0.35
        highlightNode = SKShapeNode(circleOfRadius: highlightRadius)
        highlightNode.fillColor = UIColor.white.withAlphaComponent(0.35)
        highlightNode.strokeColor = .clear
        highlightNode.position = CGPoint(x: -radius * 0.25, y: radius * 0.25)

        super.init()

        self.name = "ball_\(id)"
        self.isUserInteractionEnabled = false // Scene handles touches

        addChild(circleNode)
        addChild(highlightNode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Interaction

    /// Marks this ball as tapped and plays feedback animation.
    func tap() {
        guard !isTapped else { return }
        isTapped = true

        // Scale bounce feedback
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.08)
        let scaleDown = SKAction.scale(to: 0.9, duration: 0.1)
        let scaleNormal = SKAction.scale(to: 1.0, duration: 0.06)

        // Slight opacity change to show it's been tapped
        let dim = SKAction.fadeAlpha(to: 0.6, duration: 0.15)

        let bounceSequence = SKAction.sequence([scaleUp, scaleDown, scaleNormal])
        run(SKAction.group([bounceSequence, dim]))
    }

    /// Plays the "correct match" celebration animation.
    func celebrateMatch() {
        let scaleUp = SKAction.scale(to: 1.3, duration: 0.15)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        run(SKAction.sequence([scaleUp, fadeOut]))
    }

    /// Plays the "wrong tap" error animation.
    func showError() {
        let originalColor = circleNode.fillColor

        // Flash red
        let toRed = SKAction.run { [weak self] in
            self?.circleNode.fillColor = .red
        }
        let wait = SKAction.wait(forDuration: 0.15)
        let restore = SKAction.run { [weak self] in
            self?.circleNode.fillColor = originalColor
        }

        // Shake
        let moveLeft = SKAction.moveBy(x: -8, y: 0, duration: 0.04)
        let moveRight = SKAction.moveBy(x: 16, y: 0, duration: 0.08)
        let moveCenter = SKAction.moveBy(x: -8, y: 0, duration: 0.04)
        let shake = SKAction.sequence([moveLeft, moveRight, moveCenter])

        run(SKAction.group([
            SKAction.sequence([toRed, wait, restore]),
            shake
        ]))
    }

    /// Appear animation when spawning.
    func animateAppear(delay: TimeInterval = 0) {
        self.setScale(0)
        self.alpha = 0

        let wait = SKAction.wait(forDuration: delay)
        let scaleIn = SKAction.scale(to: 1.0, duration: 0.25)
        scaleIn.timingMode = .easeOut
        let fadeIn = SKAction.fadeIn(withDuration: 0.2)

        run(SKAction.sequence([wait, SKAction.group([scaleIn, fadeIn])]))
    }

    /// Disappear animation.
    func animateDisappear(completion: @escaping () -> Void = {}) {
        let scaleOut = SKAction.scale(to: 0, duration: 0.2)
        scaleOut.timingMode = .easeIn
        let fadeOut = SKAction.fadeOut(withDuration: 0.15)
        let remove = SKAction.run { completion() }

        run(SKAction.sequence([SKAction.group([scaleOut, fadeOut]), remove]))
    }

    /// Check if a point (in parent coordinates) is within this ball's radius.
    func hitTest(at point: CGPoint) -> Bool {
        let dx = point.x - position.x
        let dy = point.y - position.y
        let distance = sqrt(dx * dx + dy * dy)
        return distance <= radius
    }
}
