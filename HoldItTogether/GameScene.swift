import SpriteKit
import UIKit          // ⬅︎ for UIImpactFeedbackGenerator

class GameScene: SKScene {

    // MARK: – Nodes
    private var orb:        SKShapeNode!
    private var glowLayer:  SKShapeNode!
    private var cursor:     SKShapeNode!
    private var arrow:      SKShapeNode!
    private var scoreLabel: SKLabelNode!
    private var statusLabel:SKLabelNode!

    // MARK: – State
    private var isTouching    = false
    private var touchLocation = CGPoint.zero
    private var gameStarted   = false

    private var score           = 0
    private var scoreMultiplier = 1
    private var chaosMagnitude:  CGFloat = 2
    private var chaosTimer:      TimeInterval = 0
    private var scoreTimer:      TimeInterval = 0
    private var colourIndex      = 0
    private var frameCounter     = 0
    // MARK: – Tunables
    private let holdRadius: CGFloat = 120
    private let orbRadius:  CGFloat = 50
    private let maxPush:    CGFloat = 0.06

    // Glow colour cycle
    private let chaosColours: [SKColor] = [
        .cyan, .systemTeal, .systemYellow,
        .systemOrange, .systemRed, .systemPurple
    ]

    // MARK: – Haptics helper
    private enum Haptic {
        static let light  = UIImpactFeedbackGenerator(style: .light)
        static let medium = UIImpactFeedbackGenerator(style: .medium)
        static let heavy  = UIImpactFeedbackGenerator(style: .heavy)
        static func prepareAll() {
            light.prepare(); medium.prepare(); heavy.prepare()
        }
    }

    // MARK: – Scene setup
    override func didMove(to view: SKView) {
        backgroundColor = .black
        Haptic.prepareAll()          // prime the generators
        setupOrb()
        setupCursor()
        setupArrow()
        setupLabels()
    }

    // ────────────── Orb & Glow ─────────────────────────────────────────
    private func setupOrb() {
        orb = SKShapeNode(circleOfRadius: orbRadius)
        orb.fillColor   = .cyan
        orb.strokeColor = .white
        orb.lineWidth   = 4
        orb.position    = center
        addChild(orb)

        let ring = SKShapeNode(circleOfRadius: holdRadius)
        ring.strokeColor = .cyan
        ring.lineWidth   = 1
        ring.alpha       = 0.15
        ring.zPosition   = -1
        orb.addChild(ring)

        addGlowLayer()
    }

    private func addGlowLayer() {
        glowLayer = SKShapeNode(circleOfRadius: orbRadius + 38)
        glowLayer.fillColor   = chaosColours[0]
        glowLayer.strokeColor = .clear
        glowLayer.alpha       = 0.25
        glowLayer.zPosition   = -0.5
        orb.addChild(glowLayer)

        let pulse = SKAction.sequence([
            .group([ .scale(to: 1.18, duration: 0.6),
                     .fadeAlpha(to: 0.10, duration: 0.6) ]),
            .group([ .scale(to: 1.00, duration: 0.6),
                     .fadeAlpha(to: 0.25, duration: 0.6) ])
        ])
        glowLayer.run(.repeatForever(pulse))
    }

    private func shiftGlowColour() {
        colourIndex = (colourIndex + 1) % chaosColours.count
        let newCol = chaosColours[colourIndex]
        let tint = SKAction.customAction(withDuration: 0.4) { node, _ in
            (node as? SKShapeNode)?.fillColor = newCol
        }
        glowLayer.run(tint)
    }

    // ────────────── Cursor & Arrow ─────────────────────────────────────
    private func setupCursor() {
        cursor = SKShapeNode(circleOfRadius: 15)
        cursor.strokeColor = .white
        cursor.lineWidth   = 2
        cursor.alpha       = 0.3
        cursor.zPosition   = 10
        cursor.isHidden    = true
        addChild(cursor)
    }

    private func chevronPath() -> CGPath {
        let arm: CGFloat = 8, gap: CGFloat = 18
        let p = CGMutablePath()
        p.move(to: CGPoint(x: -gap, y: 0))
        p.addLine(to: CGPoint(x:  0, y: -arm))
        p.addLine(to: CGPoint(x:  gap, y: 0))
        return p
    }

    private func setupArrow() {
        arrow = SKShapeNode(path: chevronPath())
        arrow.setScale(1.2)
        arrow.lineWidth   = 4
        arrow.strokeColor = .white
        arrow.fillColor   = .clear
        arrow.alpha       = 0
        arrow.zPosition   = 5
        addChild(arrow)
    }

    // ────────────── Labels ─────────────────────────────────────────────
    private func setupLabels() {
        statusLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        statusLabel.fontSize = 26
        statusLabel.fontColor = .white
        statusLabel.position  = CGPoint(x: center.x, y: size.height - 100)
        addChild(statusLabel)

        scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.fontSize = 22
        scoreLabel.fontColor = .white
        scoreLabel.position  = CGPoint(x: center.x, y: statusLabel.position.y - 35)
        scoreLabel.text      = "Score: 0"
        addChild(scoreLabel)
    }

    // ────────────── Touches ────────────────────────────────────────────
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        isTouching      = true
        touchLocation   = t.location(in: self)
        cursor.position = touchLocation
        cursor.isHidden = false
        if !gameStarted { restartGame() }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        touchLocation   = t.location(in: self)
        cursor.position = touchLocation
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)   { stopTouch() }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { stopTouch() }

    private func stopTouch() {
        isTouching = false
        cursor.isHidden = true
        arrow.alpha = 0
        endGame(reason: "Let go")
    }

    // ────────────── Game Loop ──────────────────────────────────────────
    override func update(_ currentTime: TimeInterval) {
        guard gameStarted else { return }
        frameCounter += 1

        // 1. Steering influence
        if isTouching {
            let dx = touchLocation.x - orb.position.x
            let dy = touchLocation.y - orb.position.y
            let dist = hypot(dx, dy)
            if dist > 20 {
                let push = min(maxPush, pow(dist / holdRadius, 2) * maxPush)
                orb.position.x -= dx * push
                orb.position.y -= dy * push

                let inv = 1 / dist
                let ux = dx*inv, uy = dy*inv
                let offset = orbRadius + 14
                arrow.position = CGPoint(x: orb.position.x - ux*offset,
                                         y: orb.position.y - uy*offset)
                arrow.zRotation = atan2(-dy, -dx) + .pi/2
                arrow.alpha = min(0.6, push*50)
            } else { arrow.alpha = 0 }
        }

        // 2. Score every 0.25 s
        scoreTimer += 1/60
        if scoreTimer >= 0.25 {
            scoreTimer = 0
            score += scoreMultiplier
            scoreLabel.text = "Score: \(score)"
        }

        // 3. Chaos escalation + medium haptic
        chaosTimer += 1/60
        if chaosTimer >= 2 {
            chaosTimer = 0
            chaosMagnitude += 0.5
            scoreMultiplier += 1
            shiftGlowColour()
            Haptic.medium.impactOccurred()
        }

        // 4. Random jitter + light haptic every 4 frames (if chaos > 2)
        orb.position.x += CGFloat.random(in: -chaosMagnitude...chaosMagnitude)
        orb.position.y += CGFloat.random(in: -chaosMagnitude...chaosMagnitude)
        if chaosMagnitude > 2 && frameCounter % 4 == 0 {
            Haptic.light.impactOccurred()
        }

        // 5. Edge escape
        if orb.position.x < orbRadius ||
           orb.position.x > size.width - orbRadius ||
           orb.position.y < orbRadius ||
           orb.position.y > size.height - orbRadius {
            endGame(reason: "Orb escaped")
        }
    }

    // ────────────── Restart & End ──────────────────────────────────────
    private func restartGame() {
        gameStarted     = true
        score           = 0
        scoreMultiplier = 1
        chaosMagnitude  = 2
        chaosTimer      = 0
        scoreTimer      = 0
        colourIndex     = 0
        frameCounter    = 0

        glowLayer.removeFromParent()
        addGlowLayer()

        statusLabel.text = ""
        scoreLabel.text  = "Score: 0"
        orb.position     = center
        arrow.alpha      = 0
    }

    private func endGame(reason: String) {
        guard gameStarted else { return }
        gameStarted = false
        Haptic.heavy.impactOccurred()

        let flash = SKSpriteNode(color: .white, size: size)
        flash.alpha = 0.8; flash.zPosition = 999; flash.position = center
        addChild(flash)
        flash.run(.sequence([.fadeOut(withDuration: 0.4), .removeFromParent()]))

        statusLabel.text = "\(reason)!"
        scoreLabel.text  = "Score: \(score) • Tap to restart"
        orb.position     = center
        cursor.isHidden  = true
        arrow.alpha      = 0
    }

    // Helper
    private var center: CGPoint { CGPoint(x: size.width/2, y: size.height/2) }
}
