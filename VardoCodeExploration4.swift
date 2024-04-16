//
//  VardoCodeExploration4.swift
//  vARdo Code Exploration

// I then wanted to connect it ot the discussed ROTOR function


//  Created by Rich  on 16/04/2024.
//

import UIKit
import ARKit
import PdAudioController

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var objectSelector: UISegmentedControl!
    
    let pdManager = PdManager()
    var sendSidesLengthTimer: Timer?
    let sendSidesLengthInterval: TimeInterval = 3.0 // Interval in seconds
    
    var selectedObjectType: ARSemanticSegmentation.Classification = .none {
        didSet {
            refreshARScene()
        }
    }
    
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
        
        // Set up object selector
        objectSelector.addTarget(self, action: #selector(objectSelectorValueChanged(_:)), for: .valueChanged)
        
        // Make the segmented control accessible
        objectSelector.isAccessibilityElement = true
        objectSelector.accessibilityLabel = "Select Object Type"
        
        // Add accessibility actions to allow navigation through the options
        objectSelector.accessibilityHint = "Use VoiceOver rotor to select object type"
        objectSelector.accessibilityTraits = .button
        objectSelector.accessibilityIdentifier = "ObjectSelector"
    }
    
    @objc func objectSelectorValueChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            selectedObjectType = .none
        case 1:
            selectedObjectType = .seat
        case 2:
            selectedObjectType = .door
        // Add more cases for other types if needed
        default:
            selectedObjectType = .none
        }
    }
    
    func refreshARScene() {
        // Remove existing nodes from the scene
        sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
        
        // Add only the selected type of objects to the scene
        sceneView.scene.rootNode.addChildNode(createNodesForSelectedType())
    }
    
    func createNodesForSelectedType() -> SCNNode {
        let rootNode = SCNNode()
        
        // Iterate over detected semantic objects and add nodes for the selected type
        sceneView.hitTest(sceneView.center, types: .existingPlaneUsingGeometry).forEach { result in
            guard let anchor = result.anchor as? ARPlaneAnchor else { return }
            let planeNode = createPlaneNode(planeAnchor: anchor)
            rootNode.addChildNode(planeNode)
        }
        
        return rootNode
    }
    
    func createPlaneNode(planeAnchor: ARPlaneAnchor) -> SCNNode {
        // Create and return a plane node based on the plane anchor
        // This function is just for demonstration purposes; you can replace it with your own implementation
        let planeGeometry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        let planeNode = SCNNode(geometry: planeGeometry)
        planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
        planeNode.eulerAngles.x = -.pi / 2 // Rotate the plane to be horizontal
        planeNode.opacity = 0.5 // Adjust transparency
        return planeNode
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

