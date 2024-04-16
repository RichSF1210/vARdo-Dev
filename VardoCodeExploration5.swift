//
//  VardoCodeExploration5.swift
//  vARdo Code Exploration
//
//  Created by Rich  on 16/04/2024.

//Latest functionality exploration - 12 MAr 2024 INPUT to LLM:

//this app will be using ARKit to detect AR planes on a LiDAR-capable device, once a plane is detected a singular sound-output will be directly attached to the immediate centre location of the singular detected AR plane. Each plane detected will be using an 'instance' of the same pd patch "_main.pd"  from the Pure Data embedded audio library 'PdLib' to produce the sound for each emitter of sound-output, Pd is acting as the main AVAudioEngine AU plugin. Once the audio has returned from each instance of the Pure Data Lib Pd patch then each instance of sound located at the centre of each AR plane will be spatialised using the AVAudio3DMixing at the same point of location of emitter of sound output, the centre of the detected AR plane. Upon detection of each of the ARplanes, the ARplane geometry data of the length of the sides of the plane are 'streamed' to the corresponding instance of the ARplane and its connected Pd Patch instance and sound output.  x-axis geometry data from the AR plane will be sent to a receiver in Pd named 'r geo_x', z-axis geometry data from the AR plane will be sent using receiver 'r geo_z' in pure data patch, height in formation or y-axis, will be sent using receiver 'r height_y' in pure data patch. This geometry axis information will be sent individually for each AR plane with a variable rate of repeat of 0-5 seconds, this si to retrigger the audio from Pd, the axis information will be sent staggered starting with the axis nearest the camera view first to last at a variable rate of 0-3 seconds.  Please provide the full code for this, inclusive of extensive comments for each section, please use print and debugging to ensure safety in the code and detect bugs easily in the build. Please provide step-by-step instructions in detail fo the setup of this project in an Xcode environment all the way through to build on ios 16 iPhone with lidar. Please include a print function that can be easily turned off to display the incoming geometry information on the phone screen itself as a debug tool



//

import UIKit
import ARKit
import PdLib

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var pdInstance: PdInstance?
    var audioEngine: AVAudioEngine!
    var audioEnvironment: AVAudioEnvironmentNode!
    var audioPlayerNodes: [AVAudioPlayerNode] = []
    var planeAnchor: ARPlaneAnchor?
    var geometryTimer: Timer?
    var sidesSentCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self

        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // Initialize Pd
        pdInstance = PdInstance()
        guard let pdInstance = pdInstance else {
            fatalError("Unable to initialize Pure Data instance.")
        }
        
        // Configure Pd audio session
        do {
            try pdInstance.configureAmbientCategory()
        } catch {
            print("Failed to configure Pd audio session: \(error)")
        }
        
        // Initialize audio engine
        audioEngine = AVAudioEngine()
        audioEnvironment = AVAudioEnvironmentNode()
        audioEngine.attach(audioEnvironment)
        audioEngine.connect(audioEnvironment, to: audioEngine.mainMixerNode, format: nil)
        
        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.sceneReconstruction = .meshWithClassification
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor {
            // Store the plane anchor
            self.planeAnchor = planeAnchor
            
            // Get center of the detected plane
            let center = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
            
            // Start sending geometry axis information staggered in timing
            startSendingGeometryDataStaggered()
            
            // Generate audio in Pd and play/spatialize in iOS app
            playAndSpatializeAudio(at: center)
        }
    }
    
    func startSendingGeometryDataStaggered() {
        // Invalidate existing timer if exists
        geometryTimer?.invalidate()
        
        geometryTimer = Timer.scheduledTimer(withTimeInterval: 0.0, repeats: true) { timer in
            guard let planeAnchor = self.planeAnchor else { return }
            
            let x = planeAnchor.extent.x
            let z = planeAnchor.extent.z
            let y = planeAnchor.extent.y
            
            // Send geometry axis information to Pure Data
            switch self.sidesSentCount % 3 {
            case 0:
                self.pdInstance?.sendMessage("r geo_x \(x)")
            case 1:
                self.pdInstance?.sendMessage("r geo_z \(z)")
            case 2:
                self.pdInstance?.sendMessage("r height_y \(y)")
            default:
                break
            }
            
            // Increment sides sent count
            self.sidesSentCount += 1
            
            // If all sides have been sent, reset the count
            if self.sidesSentCount == 3 {
                self.sidesSentCount = 0
            }
            
            // Calculate next interval with fixed adjustable delay lengths of 0 to 5 seconds
            let delay = Double(self.sidesSentCount) * 5.0 / 3.0 // 5 seconds divided by number of sides (3)
            timer.invalidate()
            timer.fireDate = Date(timeIntervalSinceNow: delay)
        }
    }
    
    func playAndSpatializeAudio(at position: SCNVector3) {
        // Same implementation as before
    }
}
