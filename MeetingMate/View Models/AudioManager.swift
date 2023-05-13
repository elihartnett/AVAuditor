//
//  AudioManager.swift
//  MeetingMate
//
//  Created by Eli Hartnett on 4/16/23.
//

import Foundation
import Accelerate
import AVKit
import AVFoundation

class AudioManager: Errorable {
    
    @Published var audioInputOptions: [AVCaptureDevice]?
    @Published var selectedAudioInputDeviceID = Constants.none
    @Published var detectedAudioLevel = Constants.zeroMultiplier
    @Published var fftMagnitudes: [Float] = []
    @Published var permissionDenied = false
    
    var captureDevice: AVCaptureDevice?
    
    private var captureSession: AVCaptureSession?
    private var audioRecorder: AVCaptureAudioFileOutput?
    private var avPlayer: AVPlayer?
    private let recordingURL = URL.documentsDirectory.appendingPathComponent(Constants.recordingFileName)
    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let bufferSize = 1024
    private let audioBarCount = 40
    
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
        _ = audioEngine.mainMixerNode
        
        audioEngine.prepare()
        try! audioEngine.start()
        
        let audioFile = try! AVAudioFile(forReading: recordingURL)
        let format = audioFile.processingFormat
        
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: format)
        
        playerNode.scheduleFile(audioFile, at: nil)
        playerNode.play()
        
        let fftSetup = vDSP_DFT_zop_CreateSetup(
            nil,
            UInt(bufferSize),
            vDSP_DFT_Direction.FORWARD
        )
        
        audioEngine.mainMixerNode.installTap(
            onBus: 0,
            bufferSize: UInt32(bufferSize),
            format: nil
        ) { [self] buffer, _ in
            let channelData = buffer.floatChannelData?[0]
            DispatchQueue.main.async { [self] in
                fftMagnitudes = fft(data: channelData!, setup: fftSetup!)
            }
        }
    }
    
    // Fast Fourier Transform
    func fft(data: UnsafeMutablePointer<Float>, setup: OpaquePointer) -> [Float] {
        var realIn = [Float](repeating: 0, count: bufferSize)
        var imagIn = [Float](repeating: 0, count: bufferSize)
        var realOut = [Float](repeating: 0, count: bufferSize)
        var imagOut = [Float](repeating: 0, count: bufferSize)
        
        for i in 0 ..< bufferSize {
            realIn[i] = data[i]
        }
        
        vDSP_DFT_Execute(setup, &realIn, &imagIn, &realOut, &imagOut)
        
        var magnitudes = [Float](repeating: 0, count: audioBarCount)
        
        realOut.withUnsafeMutableBufferPointer { realBP in
            imagOut.withUnsafeMutableBufferPointer { imagBP in
                var complex = DSPSplitComplex(realp: realBP.baseAddress!, imagp: imagBP.baseAddress!)
                vDSP_zvabs(&complex, 1, &magnitudes, 1, UInt(audioBarCount))
            }
        }
        
        var normalizedMagnitudes = [Float](repeating: 0.0, count: audioBarCount)
        var scalingFactor = Float(1)
        vDSP_vsmul(&magnitudes, 1, &scalingFactor, &normalizedMagnitudes, 1, UInt(audioBarCount))
        
        return normalizedMagnitudes
    }
}

extension AudioManager: AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let audioChannel = connection.audioChannels.first
        if let level = audioChannel?.averagePowerLevel {
            DispatchQueue.main.async {
                print(CGFloat(level))
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

// ARCHIVED CODE - Average output level
/*
 output.setSampleBufferDelegate(self, queue: DispatchQueue(label: Constants.audioQueueName))
 
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
 */
// View
/*
 GeometryReader { geo in
 let audioLevel = CGFloat((audioManager.detectedAudioLevel + 50) / 50)
 
 ZStack(alignment: .leading) {
 Rectangle()
 .fill(.tertiary.opacity(Constants.halfMultiplier))
 
 Rectangle()
 .fill(.primary)
 .frame(width: geo.size.width * CGFloat(min(max(0, audioLevel), 1)))
 .animation(.default, value: audioLevel)
 }
 .cornerRadius(Constants.componentCornerRadius)
 }
 */

// ARCHIVED CODE - passthrough, but can't change mic
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

// ARCHIVED CODE - passthrough, but laggy
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
