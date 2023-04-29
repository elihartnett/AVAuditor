//
//  AudioManager.swift
//  MeetingMate
//
//  Created by Eli Hartnett on 4/16/23.
//

import Foundation
import AVKit

class AudioManager: NSObject, ObservableObject {
    
    @Published var selectedAudioInputDeviceID = Constants.none
    @Published var detectedAudioLevel: Float = 0.0

    var audioInputOptions: [AVCaptureDevice]? = nil
    var captureDevice: AVCaptureDevice? = nil
    var captureSession: AVCaptureSession? = nil
    
    var audioEngine: AVAudioEngine? = nil
    var playerNode: AVAudioPlayerNode? = nil
    var mainMixerNode: AVAudioMixerNode? = nil
    
    func startAudioManager(mute: Bool) {
        startDetectingAudioLevel()
        startLivePlayback(mute: mute)
    }
    
    func resetAudioManager() {
        mainMixerNode?.engine?.stop()
        mainMixerNode = nil
        
        audioEngine?.stop()
        audioEngine?.reset()
        audioEngine = nil

        playerNode?.stop()
        playerNode = nil
                
        captureSession = nil
        captureDevice = nil
    }
    
    func setCaptureDevice(mute: Bool) {
        resetAudioManager()
        
        captureDevice = audioInputOptions?.first { $0.uniqueID == selectedAudioInputDeviceID }
        
        if captureDevice != nil {
            if AVCaptureDevice.authorizationStatus(for: .audio) ==  .authorized {
                startAudioManager(mute: mute)
            }
            else {
                AVCaptureDevice.requestAccess(for: .audio, completionHandler: { granted in
                    if granted {
                        #warning("Change all prints to error alerts")
                        print("access allowed")
                        self.startAudioManager(mute: mute)
                    } else {
                        print("access denied")
                        self.selectedAudioInputDeviceID = ""
                    }
                })
            }
        }
        else {
            resetAudioManager()
        }
    }
    
    func startLivePlayback(mute: Bool) {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        
        guard let audioEngine = audioEngine else { return }
        guard let playerNode = playerNode else { return }

        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        mainMixerNode = audioEngine.mainMixerNode
        guard let mainMixerNode = mainMixerNode else { return }
        if mute {
            muteLivePlayback()
        }
        else {
            muteLivePlayback()
        }
        
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: mainMixerNode, format: inputFormat)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { (buffer, time) in
            self.playerNode?.scheduleBuffer(buffer, completionHandler: nil)
        }
        
        do {
            try audioEngine.start()
            playerNode.play()
        } catch {
            print("Error starting the audio engine: \(error)")
        }
    }
    
    func muteLivePlayback() {
        mainMixerNode?.outputVolume = 0
    }
    
    func unmuteLivePlayback() {
        mainMixerNode?.outputVolume = 1
    }
    
    func startDetectingAudioLevel() {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }
        guard let captureDevice = captureDevice else { return }

        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            let output = AVCaptureAudioDataOutput()
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "audioQueue"))

            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            } else {
                print("Could not add input device to capture session")
                return
            }

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
}

extension AudioManager: AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let audioChannel = connection.audioChannels.first
        if let level = audioChannel?.averagePowerLevel {
            DispatchQueue.main.async {
                #warning("average power level not working well")
                self.detectedAudioLevel = level
            }
        }
    }
}
