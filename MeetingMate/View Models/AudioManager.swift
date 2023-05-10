//
//  AudioManager.swift
//  MeetingMate
//
//  Created by Eli Hartnett on 4/16/23.
//

import AVKit
import Foundation

class AudioManager: Errorable {

    @Published var audioInputOptions: [AVCaptureDevice]?
    @Published var selectedAudioInputDeviceID = Constants.none
    @Published var detectedAudioLevel = Constants.zeroMultiplier

    @Published var permissionDenied = false

    var captureDevice: AVCaptureDevice?

    private var captureSession: AVCaptureSession?
    private var audioRecorder: AVCaptureAudioFileOutput?
    private var avPlayer: AVPlayer?
    private let recordingURL = URL.documentsDirectory.appendingPathComponent(Constants.recordingFileName)

    override init() {
        super.init()
        audioInputOptions = MeetingMateModel.getAvailableDevices(mediaType: .audio)
        checkPermissions()
    }

    func checkPermissions() {
        if AVCaptureDevice.authorizationStatus(for: .audio) ==  .authorized {
            startAudioManager()
        } else {
            AVCaptureDevice.requestAccess(for: .audio, completionHandler: { granted in
                if granted {
                    self.permissionDenied = false
                } else {
                    self.permissionDenied = true
                    DispatchQueue.main.async {
                        self.resetAudioManager()
                    }
                }
            })
        }
    }

    func startAudioManager() {
        setupCaptureSession()
    }

    func resetAudioManager() {
        detectedAudioLevel = Constants.zeroMultiplier
        audioInputOptions = MeetingMateModel.getAvailableDevices(mediaType: .audio)
        selectedAudioInputDeviceID = Constants.none
        captureDevice = nil
        captureSession = nil
        avPlayer = nil
    }

    func setSelectedAudioInputDevice() {
        audioInputOptions = MeetingMateModel.getAvailableDevices(mediaType: .audio)
        captureDevice = audioInputOptions?.first { $0.uniqueID == selectedAudioInputDeviceID }

        if captureDevice != nil {
            if !permissionDenied {
                self.startAudioManager()
            }
        } else { selectedAudioInputDeviceID = Constants.none }
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
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: Constants.audioQueueName))

            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            } else {
                errorMessage = Constants.errorAddInput
            }

            if captureSession.canAddOutput(audioRecorder) {
                captureSession.addOutput(audioRecorder)
            } else {
                errorMessage = Constants.errorAddOutput
            }

            // Add live output
            if captureSession.canAddOutput(output) {
                captureSession.addOutput(output)
            } else {
                errorMessage = Constants.errorAddOutput
            }

            captureSession.startRunning()
        } catch {
            errorMessage = Constants.error
        }
    }

    func startRecording() {
        setupCaptureSession()

        guard let audioRecorder = audioRecorder else { return }

        if FileManager.default.fileExists(atPath: recordingURL.path()) {
            do {
                try FileManager.default.removeItem(at: recordingURL)
            } catch {
                errorMessage = Constants.errorRecord
                return
            }
        }

        audioRecorder.startRecording(to: recordingURL, outputFileType: .m4a, recordingDelegate: self)
    }

    func stopRecording() {
        audioRecorder?.stopRecording()
    }

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
                self.detectedAudioLevel = CGFloat(level)
            }
        }
    }
}

extension AudioManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        guard error == nil else {
            errorMessage = Constants.errorRecord
            return
        }
        playRecording()
    }
}

// ARCHIVED CODE - Can not change capture device with passthrough
/*
 var audioEngine: AVAudioEngine? = nil
 var playerNode: AVAudioPlayerNode? = nil
 var mainMixerNode: AVAudioMixerNode? = nil
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
 */

// ARCHIVED CODE - laggy audio
/*
 import SwiftUI
 import Foundation
 import AVFoundation
 
 struct ContentView: View {
 @StateObject private var audioHandler = AudioHandler()
 @State private var selectedDevice: AVCaptureDevice?
 
 var body: some View {
 VStack {
 Text("Select Microphone")
 .font(.headline)
 
 Picker("Input Devices", selection: $selectedDevice) {
 ForEach(audioHandler.inputDevices, id: \.uniqueID) { device in
 Text(device.localizedName).tag(device as AVCaptureDevice?)
 }
 }
 .pickerStyle(MenuPickerStyle())
 .padding()
 
 Button("Start Audio Passthrough") {
 if let device = selectedDevice {
 audioHandler.startAudioCapture(device: device)
 }
 }
 }
 .frame(maxWidth: .infinity, maxHeight: .infinity)
 }
 }
 
 struct ContentView_Previews: PreviewProvider {
 static var previews: some View {
 ContentView()
 }
 }
 
 class AudioHandler: NSObject, ObservableObject {
 @Published var inputDevices: [AVCaptureDevice] = []
 var audioSession: AVCaptureSession?
 var audioEngine = AVAudioEngine()
 var audioPlayerNode = AVAudioPlayerNode()
 
 override init() {
 super.init()
 inputDevices = AVCaptureDevice.devices(for: .audio)
 }
 
 func startAudioCapture(device: AVCaptureDevice) {
 audioSession?.stopRunning()
 audioSession = nil
 
 let newSession = AVCaptureSession()
 
 do {
 let input = try AVCaptureDeviceInput(device: device)
 newSession.addInput(input)
 } catch {
 print("Error setting up audio input: \(error)")
 return
 }
 
 let output = AVCaptureAudioDataOutput()
 output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "AudioDataOutputQueue"))
 newSession.addOutput(output)
 
 newSession.startRunning()
 audioSession = newSession
 
 audioEngine.attach(audioPlayerNode)
 audioEngine.connect(audioPlayerNode, to: audioEngine.mainMixerNode, format: nil)
 audioEngine.connect(audioEngine.mainMixerNode, to: audioEngine.outputNode, format: nil)
 
 do {
 try audioEngine.start()
 } catch {
 print("Error starting audio engine: \(error)")
 }
 }
 }
 
 extension AudioHandler: AVCaptureAudioDataOutputSampleBufferDelegate {
 func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
 
 // Get the audio buffer from the sample buffer
 var audioBufferList = AudioBufferList()
 var blockBuffer: CMBlockBuffer?
 
 let status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
 sampleBuffer,
 bufferListSizeNeededOut: nil,
 bufferListOut: &audioBufferList,
 bufferListSize: MemoryLayout<AudioBufferList>.size,
 blockBufferAllocator: nil,
 blockBufferMemoryAllocator: nil,
 flags: 0,
 blockBufferOut: &blockBuffer
 )
 
 guard status == noErr, let audioBuffer = audioBufferList.mBuffers.mData, audioBufferList.mNumberBuffers > 0 else {
 print("Error getting audio buffer from sample buffer")
 return
 }
 
 // Get output format from the audio engine's output node
 let outputFormat = audioEngine.outputNode.outputFormat(forBus: 0)
 
 // Create an AVAudioPCMBuffer from the audio buffer using the output format
 guard let audioPCMBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: UInt32(audioBufferList.mBuffers.mDataByteSize) / outputFormat.streamDescription.pointee.mBytesPerFrame) else {
 print("Error creating AVAudioPCMBuffer")
 return
 }
 audioPCMBuffer.frameLength = audioPCMBuffer.frameCapacity
 
 let src = UnsafeMutableRawPointer(audioBuffer)
 let dst = audioPCMBuffer.floatChannelData![0]
 memcpy(dst, src, Int(audioBufferList.mBuffers.mDataByteSize))
 
 // Play the audio through the audio engine
 audioPlayerNode.scheduleBuffer(audioPCMBuffer, completionHandler: nil)
 if !audioPlayerNode.isPlaying {
 audioPlayerNode.play()
 }
 }
 }
 
 */
