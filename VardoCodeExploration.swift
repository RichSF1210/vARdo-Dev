//
//  VardoCodeExploration.swift
//  vARdo Code Exploration
//
//  Created by Rich  on 16/04/2024.

//Obviously I've rammed everything into one script, probably bad.

//However, what I noticed is that It would be sending the geometry only once. Perhaps rather than parsing, streaming maybe an idea for the data this would be better for Pd to handle if possible please..


import UIKit
import ARKit
import PdAudioController

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    let pdManager = PdManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up libPd
        pdManager.setup()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // Configure ARKit session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            configuration.frameSemantics.insert(.personSegmentationWithDepth)
        }
        sceneView.session.run(configuration)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor {
            // Create a plane node
            let planeNode = createPlaneNode(planeAnchor: planeAnchor)
            node.addChildNode(planeNode)
            
            // Send parametric data to Pure Data
            let sidesLength = getPlaneSidesLength(planeAnchor: planeAnchor)
            pdManager.patch.sendFloat(sidesLength, toReceiver: "sidesLength")
        }
    }
    
    func createPlaneNode(planeAnchor: ARPlaneAnchor) -> SCNNode {
        let planeGeometry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        let planeNode = SCNNode(geometry: planeGeometry)
        planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
        planeNode.eulerAngles.x = -.pi / 2 // Rotate the plane to be horizontal
        planeNode.opacity = 0.5 // Adjust transparency
        
        return planeNode
    }
    
    func getPlaneSidesLength(planeAnchor: ARPlaneAnchor) -> Float {
        // Calculate the length of the sides of the plane
        let sideALength = planeAnchor.extent.x
        let sideBLength = planeAnchor.extent.z
        let averageLength = (sideALength + sideBLength) / 2.0
        
        return averageLength
    }
}

class PdManager {
    let pdAudioController = PdAudioController()
    var patch: PdFile!
    
    func setup() {
        pdAudioController.configureAmbient(withSampleRate: 44100, numberChannels: 2, mixingEnabled: true)
        pdAudioController.active = true
        
        patch = PdFile()
        patch.open("yourPatch.pd", path: Bundle.main.bundlePath)
    }
}
