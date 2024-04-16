//
//  VardoCodeExploration2.swift
//  vARdo Code Exploration

// I was then thinking, wouldn't it be awesome to have a GUI to change the rate at which it did send the info to the user a range of 0.1-5 attempted ‘UISlider’ from the Object Library onto your view controller.

//whenever the user changes the value of the slider, the sliderValueChanged method will be called, which in turn updates the timer interval based on the slider value using the updateTimerInterval method. The startSendingSidesLength method is then called with the new interval.



//
//  Created by Rich  on 16/04/2024.
//

import UIKit
import ARKit
import PdAudioController

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var intervalSlider: UISlider!
    
    let pdManager = PdManager()
    var sendSidesLengthTimer: Timer?
    
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
        
        // Start sending sides length information based on the slider value
        updateTimerInterval()
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        updateTimerInterval()
    }
    
    func updateTimerInterval() {
        let interval = TimeInterval(intervalSlider.value)
        startSendingSidesLength(every: interval)
    }
    
    func startSendingSidesLength(every interval: TimeInterval) {
        sendSidesLengthTimer?.invalidate() // Invalidate previous timer
        
        sendSidesLengthTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            if let currentPlaneAnchor = self.getCurrentPlaneAnchor() {
                let sidesLengths = self.getPlaneSidesLengths(planeAnchor: currentPlaneAnchor)
                self.pdManager.patch.sendList(sidesLengths, toReceiver: "sidesLengths")
            }
        }
    }
    
    func getCurrentPlaneAnchor() -> ARPlaneAnchor? {
        guard let currentFrame = sceneView.session.currentFrame else { return nil }
        return currentFrame.anchors.compactMap { $0 as? ARPlaneAnchor }.first
    }
    
    func getPlaneSidesLengths(planeAnchor: ARPlaneAnchor) -> [Float] {
        // Calculate the lengths of the sides of the plane
        let side1Length = planeAnchor.extent.x
        let side2Length = planeAnchor.extent.z
        let side3Length = planeAnchor.extent.x // Assuming opposite sides are of the same length
        let side4Length = planeAnchor.extent.z // Assuming opposite sides are of the same length
        
        // Organize the lengths in a specific order if needed
        let sidesLengths = [side1Length, side2Length, side3Length, side4Length]
        
        return sidesLengths
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
