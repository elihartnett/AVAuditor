//
//  AudioManager.swift
//  MeetingMate
//
//  Created by Eli Hartnett on 4/16/23.
//

import Foundation
import AVKit

class AudioManager: NSObject, ObservableObject, AVCaptureAudioDataOutputSampleBufferDelegate {
    @Published var audioLevel: Float = 0.0
    private var captureSession: AVCaptureSession!
    let audioEngine = AVAudioEngine()
    let playerNode = AVAudioPlayerNode()
    var captureDevice: AVCaptureDevice?
    
    init(captureDevice: AVCaptureDevice? = nil) {
        super.init()
        self.captureDevice = captureDevice
//        setupCaptureSession(captureDevice: captureDevice)
    }
    
    func start() {
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        let mainMixerNode = audioEngine.mainMixerNode
        
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: mainMixerNode, format: inputFormat)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { (buffer, time) in
            self.playerNode.scheduleBuffer(buffer, completionHandler: nil)
        }
        
        do {
            try audioEngine.start()
            playerNode.play()
        } catch {
            print("Error starting the audio engine: \(error)")
        }
    }
    
    func stop() {
        playerNode.stop()
        audioEngine.stop()
        audioEngine.reset()
    }
    
    func setupCaptureSession(captureDevice: AVCaptureDevice) {
        captureSession = AVCaptureSession()
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            } else {
                print("Could not add input device to capture session")
                return
            }
            
            let output = AVCaptureAudioDataOutput()
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "audioDataOutputQueue"))
            
            if captureSession.canAddOutput(output) {
                captureSession.addOutput(output)
            } else {
                print("Could not add output to capture session")
                return
            }
            
            captureSession.startRunning()
        } catch {
            print("Error setting up capture session: \(error)")
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let audioChannel = connection.audioChannels.first
        if let level = audioChannel?.averagePowerLevel {
            DispatchQueue.main.async {
                self.audioLevel = level
            }
        }
    }
}
