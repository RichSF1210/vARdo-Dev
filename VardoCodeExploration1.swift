//
//  VardoCodeExploration1.swift
//  vARdo Code Exploration

//So I started to think maybe this should be sent at intervals of a chosen amount, every 3 seconds. In order for the sound from Pd to repeat otherwise just makes a noise once.

//Digging further into the code ive realised its averaged all the geometry into one value so needs to be separated, and sent at set intervals, to create a constant pulse of data

// I also wanted the nearest side to be sent to the camera position first.

//  Created by Rich  on 16/04/2024.

// ‘getClosestSideLength’ function calculates the distance from the viewer's position to each side of the plane and then determines the closest side.

//

import UIKit
import ARKit
import PdAudioController

class ViewController: UIViewController, ARSCNViewDelegate {
    @IBOutlet var sceneView: ARSCNView!
        let pdManager = PdManager()
        var sendSidesLengthTimer: Timer?
        let sendSidesLengthInterval: TimeInterval = 3.0 // Interval in seconds
        
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
            
            // Start sending sides length information every 3 seconds
            startSendingSidesLength()
        }
        
        func startSendingSidesLength() {
            sendSidesLengthTimer = Timer.scheduledTimer(withTimeInterval: sendSidesLengthInterval, repeats: true) { [weak self] timer in
                guard let self = self else { return }
                if let currentPlaneAnchor = self.getCurrentPlaneAnchor() {
                    let closestSideLength = self.getClosestSideLength(planeAnchor: currentPlaneAnchor)
                    self.pdManager.patch.sendFloat(closestSideLength, toReceiver: "closestSideLength")
                }
            }
        }
        
        func getCurrentPlaneAnchor() -> ARPlaneAnchor? {
            guard let currentFrame = sceneView.session.currentFrame else { return nil }
            return currentFrame.anchors.compactMap { $0 as? ARPlaneAnchor }.first
        }
        
        func getClosestSideLength(planeAnchor: ARPlaneAnchor) -> Float {
            // Get the viewer's position in the AR scene
            guard let viewerPosition = sceneView.pointOfView?.position else { return 0.0 }
            
            // Calculate the distance from the viewer to each side of the plane
            let distances = [
                distance(from: viewerPosition, to: SCNVector3(planeAnchor.center.x - planeAnchor.extent.x / 2, 0, planeAnchor.center.z)),
                distance(from: viewerPosition, to: SCNVector3(planeAnchor.center.x + planeAnchor.extent.x / 2, 0, planeAnchor.center.z)),
                distance(from: viewerPosition, to: SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z - planeAnchor.extent.z / 2)),
                distance(from: viewerPosition, to: SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z + planeAnchor.extent.z / 2))
            ]
            
            // Find the index of the minimum distance
            guard let minIndex = distances.indices.min(by: { distances[$0] < distances[$1] }) else { return 0.0 }
            
            // Return the length of the closest side
            switch minIndex {
            case 0, 1:
                return planeAnchor.extent.x
            case 2, 3:
                return planeAnchor.extent.z
            default:
                return 0.0
            }
        }
        
        func distance(from pointA: SCNVector3, to pointB: SCNVector3) -> Float {
            let dx = pointB.x - pointA.x
            let dy = pointB.y - pointA.y
            let dz = pointB.z - pointA.z
            return sqrt(dx * dx + dy * dy + dz * dz)
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
