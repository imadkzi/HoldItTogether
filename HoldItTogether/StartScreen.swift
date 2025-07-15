//
//  StartScreen.swift
//  HoldItTogether
//
//  Created by Imad Kazi on 15/07/2025.
//

import SpriteKit

class StartScene: SKScene {

    override func didMove(to view: SKView) {
        backgroundColor = .black

        // Title
        let title = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        title.text = "HOLD IT TOGETHER"
        title.fontSize = 40
        title.fontColor = .white
        title.position = CGPoint(x: size.width/2, y: size.height*0.65)
        addChild(title)

        // How‑to‑play blurb
        let blurb = """
        • Press & hold near the orb\n\
        • Nudge it back toward centre\n\
        • Survive the chaos as long as you can
        """
        let rules = SKLabelNode(fontNamed: "AvenirNext-Regular")
        rules.text = blurb
        rules.numberOfLines = 3
        rules.horizontalAlignmentMode = .center
        rules.fontSize = 20
        rules.fontColor = .white
        rules.position = CGPoint(x: size.width/2, y: size.height*0.45)
        addChild(rules)

        // Tap‑to‑play prompt
        let prompt = SKLabelNode(fontNamed: "AvenirNext-Bold")
        prompt.text = "TAP ANYWHERE TO PLAY"
        prompt.fontSize = 22
        prompt.fontColor = .systemTeal
        prompt.position = CGPoint(x: size.width/2, y: size.height*0.25)
        addChild(prompt)

        // Blink animation
        let fade = SKAction.sequence([.fadeOut(withDuration: 0.7),
                                      .fadeIn(withDuration: 0.7)])
        prompt.run(.repeatForever(fade))
    }

    // Transition on touch
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let game = GameScene(size: size)
        game.scaleMode = .aspectFill
        let transition = SKTransition.fade(withDuration: 0.6)
        view?.presentScene(game, transition: transition)
    }
}
