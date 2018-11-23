//
//  ViewController.swift
//  ARDicee
//
//  Created by Kevin Wang on 11/19/18.
//  Copyright © 2018 Kevin Wang. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    // MARK: - Outlets
    @IBOutlet var sceneView: ARSCNView!
    
    // MARK: - Instance Variables
    private var currentDice : [SCNNode] = []
    
    // MARK: - VC Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: - Roll Dice methods
    
    private func rollAll() {
        for dice in currentDice {
            roll(dice: dice)
        }
    }
    
    private func roll(dice : SCNNode) {
        
        let randomX = Float(Int.random(in: 1...4)) * Float.pi / 2
        let randomZ = Float(Int.random(in: 1...4)) * Float.pi / 2
        
        dice.runAction(SCNAction.rotateBy(x: CGFloat(randomX * 5), y: 0, z: CGFloat(randomZ * 5), duration: 0.5))
    }
    
    // MARK: - Gesture methods
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        rollAll()
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let touch = touches.first else {
            return
        }
        
        let touchLocation = touch.location(in: sceneView)
        
        let hitTest = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
        
        if let hitResult = hitTest.first, let newDice = createDiceAt(location: hitResult) {            
            currentDice.append(newDice)
            roll(dice: newDice)
        }
        
    }
    
    // MARK: - Outlet functions
    
    @IBAction func removeDice(_ sender: Any) {
        for dice in currentDice {
            dice.removeFromParentNode()
        }
    }
    
    // MARK: - Node Creation methods
    private func createDiceAt(location : ARHitTestResult) -> SCNNode? {
        
        guard let diceScene = SCNScene(named: "art.scnassets/diceCollada.scn"), let diceNode = diceScene.rootNode.childNode(withName: "Dice", recursively: true)else {
            return nil
        }
        
        diceNode.position = SCNVector3(location.worldTransform.columns.3.x, location.worldTransform.columns.3.y + diceNode.boundingSphere.radius / 2, location.worldTransform.columns.3.z)
        
        sceneView.scene.rootNode.addChildNode(diceNode)
        return diceNode
    }
    
    private func createPlane(withAnchor planeAnchor : ARPlaneAnchor) -> SCNNode {
        let plane = SCNPlane(width: CGFloat(Float(planeAnchor.extent.x)), height: CGFloat(planeAnchor.extent.z))
        
        let planeNode = SCNNode()
        planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
        
        let material = SCNMaterial()
        material.diffuse.contents = [UIImage(named: "art.scnassets/grid.png")]
        plane.materials = [material]
        planeNode.geometry = plane
        
        return planeNode
    }

    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            return
        }
        
        let planeNode = createPlane(withAnchor: planeAnchor)
        
        node.addChildNode(planeNode)
        
    }
}
