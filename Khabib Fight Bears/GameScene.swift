//
//  GameScene.swift
//  Khabib Fight Bears
//
//  Created by Martin Nicola on 2023-03-17.
//

import SpriteKit
import GameplayKit

var gameScore = 0

class GameScene: SKScene, SKPhysicsContactDelegate {

    let scoreLabel = SKLabelNode(fontNamed: "Arial")
    
    var lives = 100
    let livesLabel = SKLabelNode(fontNamed: "Arial")
    
    var level = 0
    
    let player = SKSpriteNode(imageNamed: "khabib")
    let punchSound = SKAction.playSoundFileNamed("punchSound.mp3", waitForCompletion: false)
    let explosionSound = SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false)
    
    struct PhysicsCategories {
        static let None : UInt32 = 0
        static let Player : UInt32 = 0b1
        static let Punch : UInt32 = 0b10
        static let Bear : UInt32 = 0b100
    }
    
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / Float(0xFFFFFFFF))
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    let gameArea: CGRect
    
    override init(size: CGSize) {
        
        let maxAspectRatio: CGFloat = 16.0/9.0
        let playableWidth = size.height / maxAspectRatio
        let margin = (size.width - playableWidth)/2
        gameArea = CGRect(x: margin, y: 0, width: playableWidth, height: size.height)
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        
        self.physicsWorld.contactDelegate = self
        
        let background = SKSpriteNode(imageNamed: "background2")
        background.size = self.size
        background.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
        background.zPosition = 0
        self.addChild(background)
        
        spawnPlayer()
        
        scoreLabel.text = "Score: 0"
        scoreLabel.fontSize = 70
        scoreLabel.fontColor = SKColor.white
        scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabel.position = CGPoint(x: self.size.width*0.22, y: self.size.height*0.9)
        scoreLabel.zPosition = 100
        self.addChild(scoreLabel)
        
        livesLabel.text = "Health: 100"
        livesLabel.fontSize = 70
        livesLabel.fontColor = SKColor.white
        livesLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.right
        livesLabel.position = CGPoint(x: self.size.width*0.75, y: self.size.height*0.9)
        livesLabel.zPosition = 100
        self.addChild(livesLabel)
        
        startNewLevel()
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        var body1 = SKPhysicsBody()
        var body2 = SKPhysicsBody()
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            body1 = contact.bodyA
            body2 = contact.bodyB
        } else {
            body1 = contact.bodyB
            body2 = contact.bodyA
        }
        
        if body1.categoryBitMask == PhysicsCategories.Player && body2.categoryBitMask == PhysicsCategories.Bear {
            
            if body1.node != nil {
                spawnExplosion(spawnPosition: body1.node!.position)
            }
            
            if body2.node != nil {
                spawnExplosion(spawnPosition: body2.node!.position)
            }
            loseLife()
            body1.node?.removeFromParent()
            if lives != 0 {
                spawnPlayer()
            }
            body2.node?.removeFromParent()
        }
        
        if body1.categoryBitMask == PhysicsCategories.Punch && body2.categoryBitMask == PhysicsCategories.Bear && (body2.node?.position.y)! < self.size.height {
            
            if body2.node != nil {
                addScore()
                spawnExplosion(spawnPosition: body2.node!.position)
            }

            body1.node?.removeFromParent()
            body2.node?.removeFromParent()
        }
        
    }
    
    func spawnPlayer() {
        player.setScale(0.4)
        player.position = CGPoint(x: self.size.width/2, y: self.size.height * 0.2)
        player.zPosition = 2
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody!.affectedByGravity = false
        player.physicsBody!.categoryBitMask = PhysicsCategories.Player
        player.physicsBody!.collisionBitMask = PhysicsCategories.None
        player.physicsBody!.contactTestBitMask = PhysicsCategories.Bear
        self.addChild(player)
    }
    
    func addScore() {
        gameScore += 1
        scoreLabel.text = "Score: \(gameScore)"
        
        if gameScore == 5 || gameScore == 25 || gameScore == 75 {
            startNewLevel()
        }
    }
    
    func gameOver() {
            
        self.removeAllActions()
        
        self.enumerateChildNodes(withName: "Punch") {
            punch, stop in
            punch.removeAllActions()
        }
        
        self.enumerateChildNodes(withName: "Bear") {
            bear, stop in
            bear.removeAllActions()
        }
        
        let changeSceneAction = SKAction.run(changeScene)
        let waitToChangeScene = SKAction.wait(forDuration: 1)
        let changeSceneSequence = SKAction.sequence([waitToChangeScene, changeSceneAction])
        self.run(changeSceneSequence)
        
    }
    
    func changeScene() {
        
        let sceneToMoveTo = GameOverScene(size: self.size)
        sceneToMoveTo.scaleMode = self.scaleMode
        let transition = SKTransition.fade(withDuration: 0.5)
        self.view!.presentScene(sceneToMoveTo, transition: transition)
        
    }
    
    func loseLife() {
        
        lives -= 25
        livesLabel.text = "Lives: \(lives)"
        
        let scaleUp = SKAction.scale(to: 1.5, duration: 0.2)
        let scaleDown = SKAction.scale(to: 1, duration: 0.2)
        let scaleSequence = SKAction.sequence([scaleUp, scaleDown])
        livesLabel.run(scaleSequence)
        
        if lives == 0 {
            gameOver()
        }
        
    }
    
    func startNewLevel() {
        
        level += 1
        
        if self.action(forKey: "spawningBears") != nil {
            self.removeAction(forKey: "spawningBears")
        }
        
        var levelDuration = TimeInterval()
        
        switch level {
        case 1: levelDuration = 1.2
        case 2: levelDuration = 1
        case 3: levelDuration = 0.8
        case 4: levelDuration = 0.5
        default:
            levelDuration = 0.5
            print("Cannot find level info")
        }
        
        let spawn = SKAction.run(spawnBear)
        let waitToSpawn = SKAction.wait(forDuration: levelDuration)
        let spawnSequence = SKAction.sequence([waitToSpawn, spawn])
        let spawnForever = SKAction.repeatForever(spawnSequence)
        
        if lives != 0 {
            self.run(spawnForever, withKey: "spawningBears")
        }
        
    }
    
    func punch() {
        let punch = SKSpriteNode(imageNamed: "punch")
        punch.name = "Punch"
        punch.setScale(0.25)
        punch.position = player.position
        punch.zPosition = 1
        punch.physicsBody = SKPhysicsBody(rectangleOf: punch.size)
        punch.physicsBody!.affectedByGravity = false
        punch.physicsBody!.categoryBitMask = PhysicsCategories.Punch
        punch.physicsBody!.collisionBitMask = PhysicsCategories.None
        punch.physicsBody!.contactTestBitMask = PhysicsCategories.Bear
        self.addChild(punch)
        
        let movePunch = SKAction.moveTo(y: self.size.height + punch.size.height, duration: 1)
        let deletePunch = SKAction.removeFromParent()
        let punchSequence = SKAction.sequence([punchSound, movePunch, deletePunch])
        punch.run(punchSequence)
    }
    
    func spawnBear() {
        let randomXStart = random(min: CGRectGetMinX(gameArea), max: CGRectGetMaxX(gameArea))
        let randomXEnd = random(min: CGRectGetMinX(gameArea), max: CGRectGetMaxX(gameArea))
        let startPoint = CGPoint(x: randomXStart, y: self.size.height * 1.2)
        let endPoint = CGPoint(x: randomXEnd, y: -self.size.height*0.2)
        let enemy = SKSpriteNode(imageNamed: "bear")
        enemy.name = "Bear"
        enemy.setScale(0.4)
        enemy.position = startPoint
        enemy.zPosition = 2
        enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.size)
        enemy.physicsBody!.affectedByGravity = false
        enemy.physicsBody!.categoryBitMask = PhysicsCategories.Bear
        enemy.physicsBody!.collisionBitMask = PhysicsCategories.None
        enemy.physicsBody!.contactTestBitMask = PhysicsCategories.Player | PhysicsCategories.Punch
        self.addChild(enemy)
        
        let moveEnemy = SKAction.move(to: endPoint, duration: 1.5)
        let deleteEnemy = SKAction.removeFromParent()
        let enemySequence = SKAction.sequence([moveEnemy, deleteEnemy])
        enemy.run(enemySequence)
        
    }
    
    func spawnExplosion(spawnPosition: CGPoint) {
        
        let explosion = SKSpriteNode(imageNamed: "explosion")
        explosion.position = spawnPosition
        explosion.zPosition = 3
        explosion.setScale(0)
        self.addChild(explosion)
        let scaleIn = SKAction.scale(to: 1, duration: 0.1)
        let fadeOut = SKAction.fadeOut(withDuration: 0.1)
        let delete = SKAction.removeFromParent()
        let explosionSequence = SKAction.sequence([explosionSound, scaleIn, fadeOut, delete])
        explosion.run(explosionSequence)
        
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if lives != 0 {
            punch()
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch: AnyObject in touches {
            let pointOfTouch = touch.location(in: self)
            let previousPointOfTouch = touch.previousLocation(in: self)
            let amountDragged = pointOfTouch.x - previousPointOfTouch.x
            
            if lives != 0 {
                player.position.x += amountDragged
            }
            
            if player.position.x > CGRectGetMaxX(gameArea) - player.size.width {
                player.position.x = CGRectGetMaxX(gameArea) - player.size.width
            }
            
            if player.position.x < CGRectGetMinX(gameArea) + player.size.width {
                player.position.x = CGRectGetMinX(gameArea) + player.size.width
            }
            
        }
    }
    
}
