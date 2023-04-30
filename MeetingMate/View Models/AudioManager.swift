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
    
    var audioInputOptions: [AVCaptureDevice]?
    var captureDevice: AVCaptureDevice?
    
    private var captureSession: AVCaptureSession?
    private var audioRecorder: AVCaptureAudioFileOutput?
    private var avPlayer: AVPlayer?
    let recordingURL = URL.documentsDirectory.appendingPathComponent("recording.m4a")
    
    func startAudioManager() {
        setupCaptureSession()
    }
    
    func resetAudioManager() {
        detectedAudioLevel = 0
        #warning("Need to be able to reset input options")
//        audioInputOptions = []
        captureDevice = nil
        captureSession = nil
        avPlayer = nil
    }
    
    func setCaptureDevice() {
        resetAudioManager()
        
        captureDevice = audioInputOptions?.first { $0.uniqueID == selectedAudioInputDeviceID }
        
        if captureDevice != nil {
            if AVCaptureDevice.authorizationStatus(for: .audio) ==  .authorized {
                startAudioManager()
            }
            else {
                AVCaptureDevice.requestAccess(for: .audio, completionHandler: { granted in
                    if granted {
#warning("Change all prints to error alerts")
                        print("access allowed")
                        self.startAudioManager()
                    } else {
                        print("access denied")
                        self.selectedAudioInputDeviceID = Constants.none
                    }
                })
            }
        }
        else { selectedAudioInputDeviceID = Constants.none }
    }
    
    func setupCaptureSession() {
        captureSession = AVCaptureSession()
        audioRecorder = AVCaptureAudioFileOutput()
        guard let captureSession = captureSession else { return }
        guard let captureDevice = captureDevice else { return }
        guard let audioRecorder = audioRecorder else { return }
        
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
            
            if captureSession.canAddOutput(audioRecorder) {
                captureSession.addOutput(audioRecorder)
            } else {
                print("Could not add output to capture session")
                return
            }
            
            // Add live output
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
    
    func startRecording() {
        setupCaptureSession()
        
        guard let audioRecorder = audioRecorder else { return }
        guard let captureSession = captureSession else { return }
        
        if FileManager.default.fileExists(atPath: recordingURL.path()) {
            try! FileManager.default.removeItem(at: recordingURL)
        }

        let audioRecordingSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        audioRecorder.startRecording(to: recordingURL, outputFileType: .m4a, recordingDelegate: self)
    }
    
    func stopRecording() {
        audioRecorder?.stopRecording()
    }
    
    #warning("Not playing")
    func playRecording() {
        avPlayer = AVPlayer(url: recordingURL)
        guard let avPlayer = avPlayer else { return }
        avPlayer.play()
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

extension AudioManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        #warning("catch error")
    }
}

// Can not change capture device with passthrough
//    var audioEngine: AVAudioEngine? = nil
//    var playerNode: AVAudioPlayerNode? = nil
//    var mainMixerNode: AVAudioMixerNode? = nil
//    func startLivePlayback(mute: Bool) {
//        audioEngine = AVAudioEngine()
//        playerNode = AVAudioPlayerNode()
//
//        guard let audioEngine = audioEngine else { return }
//        guard let playerNode = playerNode else { return }
//
//        let inputNode = audioEngine.inputNode
//        let inputFormat = inputNode.inputFormat(forBus: 0)
//        mainMixerNode = audioEngine.mainMixerNode
//        guard let mainMixerNode = mainMixerNode else { return }
//        if mute {
//            muteLivePlayback()
//        }
//        else {
//            muteLivePlayback()
//        }
//
//        audioEngine.attach(playerNode)
//        audioEngine.connect(playerNode, to: mainMixerNode, format: inputFormat)
//
//        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { (buffer, time) in
//            self.playerNode?.scheduleBuffer(buffer, completionHandler: nil)
//        }
//
//        do {
//            try audioEngine.start()
//            playerNode.play()
//        } catch {
//            print("Error starting the audio engine: \(error)")
//        }
//    }
//
//    func muteLivePlayback() {
//        mainMixerNode?.outputVolume = 0
//    }
//
//    func unmuteLivePlayback() {
//        mainMixerNode?.outputVolume = 1
//    }
