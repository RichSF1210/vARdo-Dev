//
//  Setting_Up_Callback.swift
//  vARdo Code Exploration
//  Ensure to set up LibPd and handle audio callbacks appropriately
//  Created by Rich  on 23/04/2024.
//

import Foundation
import LibPd

class ViewController: UIViewController {

    var pdAudioController: PdAudioController!
    var patchHandle: PdFileHandle!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize LibPd Audio Controller
        pdAudioController = PdAudioController()
        pdAudioController.configurePlayback(withSampleRate: 44100, numberChannels: 2, inputEnabled: false, mixingEnabled: true)
        pdAudioController.isActive = true
        
        // Load Pure Data Patch
        patchHandle = PdFile.openFile("example.pd", path: Bundle.main.resourcePath)
        guard let patchHandle = patchHandle else {
            fatalError("Failed to load Pure Data patch.")
        }
        
        // Set up audio processing callback
        pdAudioController.addListener(self)
    }

    // Implement audio processing callback
    func receivePrint(_ message: String!) {
        print(message)
    }
}

