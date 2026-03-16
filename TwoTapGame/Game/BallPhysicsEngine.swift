import SpriteKit

/// Handles ball-to-ball repulsion physics and speed clamping.
///
/// Two-layer separation: soft repulsion field + hard position correction.
/// Balls never touch — they repel like same-pole magnets.
struct BallPhysicsEngine {

    /// Minimum gap between ball edges.
    static let repulsionBuffer: CGFloat = 14

    /// Soft field range multiplier.
    static let softFieldRange: CGFloat = 2.5

    /// Base max speed before difficulty scaling.
    static let baseMaxSpeed: CGFloat = 55

    /// Apply repulsion between all active (non-tapped) balls.
    /// Also clamps speed and keeps balls within playable bounds.
    static func applyRepulsion(
        balls: [BallNode],
        sceneSize: CGSize,
        hudTopInset: CGFloat,
        difficultyMode: DifficultyMode?
    ) {
        let activeBalls = balls.filter { !$0.isTapped }
        guard activeBalls.count > 1 else { return }

        let buffer = repulsionBuffer

        for i in 0..<activeBalls.count {
            for j in (i + 1)..<activeBalls.count {
                let a = activeBalls[i]
                let b = activeBalls[j]

                let dx = b.position.x - a.position.x
                let dy = b.position.y - a.position.y
                let dist = sqrt(dx * dx + dy * dy)
                guard dist > 0.01 else { continue }

                let minDist = a.radius + b.radius + buffer
                let nx = dx / dist
                let ny = dy / dist

                if dist < minDist {
                    // HARD CORRECTION: push apart immediately so they never overlap
                    let overlap = (minDist - dist) * 0.55
                    a.position.x -= nx * overlap
                    a.position.y -= ny * overlap
                    b.position.x += nx * overlap
                    b.position.y += ny * overlap

                    // Deflect velocities apart (magnetic repulsion bounce)
                    guard let bodyA = a.physicsBody, let bodyB = b.physicsBody else { continue }

                    let relVx = bodyB.velocity.dx - bodyA.velocity.dx
                    let relVy = bodyB.velocity.dy - bodyA.velocity.dy
                    let relDotN = relVx * nx + relVy * ny

                    if relDotN < 0 {
                        let impulse = relDotN * 1.1
                        bodyA.velocity.dx += impulse * nx
                        bodyA.velocity.dy += impulse * ny
                        bodyB.velocity.dx -= impulse * nx
                        bodyB.velocity.dy -= impulse * ny
                    }
                }

                // SOFT FIELD: gentle push when within range
                let fieldDist = a.radius + b.radius + buffer * softFieldRange
                if dist < fieldDist {
                    let strength = (fieldDist - dist) / fieldDist
                    let push = strength * strength * 120
                    a.physicsBody?.applyForce(CGVector(dx: -nx * push, dy: -ny * push))
                    b.physicsBody?.applyForce(CGVector(dx:  nx * push, dy:  ny * push))
                }
            }
        }

        // Speed and position clamping
        let diffMultiplier: CGFloat = {
            guard let mode = difficultyMode else { return 1.0 }
            switch mode {
            case .easy:   return 0.6
            case .normal: return 1.0
            case .insane: return 1.6
            }
        }()
        let maxSpeed = baseMaxSpeed * diffMultiplier

        let wallInset: CGFloat = 40
        let ceilingY = sceneSize.height - hudTopInset
        let minX = wallInset
        let maxX = sceneSize.width - wallInset
        let minY = wallInset
        let maxY = ceilingY

        for ball in activeBalls {
            guard let body = ball.physicsBody else { continue }

            // Speed clamp
            let speed = sqrt(body.velocity.dx * body.velocity.dx + body.velocity.dy * body.velocity.dy)
            if speed > maxSpeed {
                let scale = maxSpeed / speed
                body.velocity = CGVector(dx: body.velocity.dx * scale, dy: body.velocity.dy * scale)
            }

            // Hard position clamp
            var pos = ball.position
            var bounced = false

            if pos.x < minX {
                pos.x = minX
                body.velocity.dx = abs(body.velocity.dx)
                bounced = true
            } else if pos.x > maxX {
                pos.x = maxX
                body.velocity.dx = -abs(body.velocity.dx)
                bounced = true
            }

            if pos.y < minY {
                pos.y = minY
                body.velocity.dy = abs(body.velocity.dy)
                bounced = true
            } else if pos.y > maxY {
                pos.y = maxY
                body.velocity.dy = -abs(body.velocity.dy)
                bounced = true
            }

            if bounced {
                ball.position = pos
            }
        }
    }
}
