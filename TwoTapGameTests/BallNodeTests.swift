import XCTest
@testable import TwoTapGame

final class BallNodeTests: XCTestCase {

    // MARK: - hitTest

    func testHitTestExactCenter() {
        let node = BallNode(id: 0, color: .red, radius: 30, isMatch: true)
        node.position = CGPoint(x: 100, y: 100)

        XCTAssertTrue(node.hitTest(at: CGPoint(x: 100, y: 100)))
    }

    func testHitTestAtEdge() {
        let node = BallNode(id: 0, color: .red, radius: 30, isMatch: true)
        node.position = CGPoint(x: 100, y: 100)

        // Exactly at radius distance
        XCTAssertTrue(node.hitTest(at: CGPoint(x: 130, y: 100)))
    }

    func testHitTestJustOutside() {
        let node = BallNode(id: 0, color: .red, radius: 30, isMatch: true)
        node.position = CGPoint(x: 100, y: 100)

        // Just beyond radius
        XCTAssertFalse(node.hitTest(at: CGPoint(x: 131, y: 100)))
    }

    func testHitTestMinimum44ptTouchTarget() {
        // Small ball (radius 15 = 30pt diameter) should still have 44pt touch target
        let node = BallNode(id: 0, color: .red, radius: 15, isMatch: true)
        node.position = CGPoint(x: 100, y: 100)

        // 22pt from center (44pt diameter / 2) — should still hit
        XCTAssertTrue(node.hitTest(at: CGPoint(x: 122, y: 100)))
    }

    func testHitTestMinimumTargetJustOutside() {
        let node = BallNode(id: 0, color: .red, radius: 15, isMatch: true)
        node.position = CGPoint(x: 100, y: 100)

        // 23pt from center — should miss
        XCTAssertFalse(node.hitTest(at: CGPoint(x: 123, y: 100)))
    }

    func testHitTestLargeBallUsesActualRadius() {
        // Large ball (radius 40) should use actual radius, not 22
        let node = BallNode(id: 0, color: .red, radius: 40, isMatch: true)
        node.position = CGPoint(x: 100, y: 100)

        XCTAssertTrue(node.hitTest(at: CGPoint(x: 140, y: 100)))
        XCTAssertFalse(node.hitTest(at: CGPoint(x: 141, y: 100)))
    }

    func testHitTestDiagonalDistance() {
        let node = BallNode(id: 0, color: .red, radius: 30, isMatch: true)
        node.position = CGPoint(x: 100, y: 100)

        // Point at (121, 121) — distance = sqrt(21^2 + 21^2) ≈ 29.7 < 30
        XCTAssertTrue(node.hitTest(at: CGPoint(x: 121, y: 121)))

        // Point at (122, 122) — distance = sqrt(22^2 + 22^2) ≈ 31.1 > 30
        XCTAssertFalse(node.hitTest(at: CGPoint(x: 122, y: 122)))
    }

    // MARK: - isTapped guard

    func testTapCorrectSetsIsTapped() {
        let node = BallNode(id: 0, color: .red, radius: 30, isMatch: true)
        // Need to add to a scene for explosion to work
        let scene = SKScene(size: CGSize(width: 400, height: 400))
        scene.addChild(node)

        XCTAssertFalse(node.isTapped)
        node.tapCorrect()
        XCTAssertTrue(node.isTapped)
    }

    func testTapWrongSetsIsTapped() {
        let node = BallNode(id: 0, color: .red, radius: 30, isMatch: false)
        let scene = SKScene(size: CGSize(width: 400, height: 400))
        scene.addChild(node)

        node.tapWrong()
        XCTAssertTrue(node.isTapped)
    }

    func testDoubleTapCorrectIsIdempotent() {
        let node = BallNode(id: 0, color: .red, radius: 30, isMatch: true)
        let scene = SKScene(size: CGSize(width: 400, height: 400))
        scene.addChild(node)

        node.tapCorrect()
        node.tapCorrect() // second call — should be no-op
        XCTAssertTrue(node.isTapped)
    }

    // MARK: - Properties

    func testBallNodeProperties() {
        let node = BallNode(id: 5, color: .blue, radius: 25, isMatch: false)

        XCTAssertEqual(node.ballId, 5)
        XCTAssertEqual(node.ballColor, .blue)
        XCTAssertEqual(node.radius, 25)
        XCTAssertFalse(node.isMatch)
        XCTAssertFalse(node.isTapped)
    }

    func testBallNodePhysicsBody() {
        let node = BallNode(id: 0, color: .red, radius: 30, isMatch: true)

        XCTAssertNotNil(node.physicsBody)
        XCTAssertEqual(node.physicsBody?.friction, 0)
        XCTAssertEqual(node.physicsBody?.restitution, 1.0)
        XCTAssertEqual(node.physicsBody?.linearDamping, 0)
        XCTAssertFalse(node.physicsBody?.allowsRotation ?? true)
    }
}

import SpriteKit
