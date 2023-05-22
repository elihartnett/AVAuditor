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

#warning("Memory constantly increasing")
class AudioManager: Errorable {
    
    @Published var audioInputOptions: [AVCaptureDevice]?
    @Published var selectedAudioInputDeviceID = Constants.noneTag
    @Published var fftMagnitudes: [Float] = []
    @Published var permissionDenied = false
    @Published var playerNodeMuted = true
    @Published var isRecording = false
    @Published var sensitivity: Float = 1

    var captureDevice: AVCaptureDevice?
    var captureSession: AVCaptureSession?

    private var audioRecorder: AVCaptureAudioFileOutput?
    private var buffers: [AVAudioPCMBuffer] = []
    private var playerNodeMutedBackup = true
    
    private let recordingURL = URL.documentsDirectory.appendingPathComponent(Constants.recordingFileName)
    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let bufferSize = 1024
    private let monoFormat = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 1)
    private let bufferQueue = DispatchQueue(label: "com.MeetingMate.BufferAccessQueue")
    
    override init() {
        super.init()
        audioInputOptions = MeetingMateModel.getAvailableDevices(mediaType: .audio)
        checkPermissions()
        
        if playerNodeMuted {
            mutePlayerNode()
        }
        else {
            unmutePlayerNode()
        }
    }
    
    func checkPermissions() {
        if AVCaptureDevice.authorizationStatus(for: .audio) ==  .authorized {
            permissionDenied = false
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
    
    func resetAudioManager() {
        audioInputOptions = MeetingMateModel.getAvailableDevices(mediaType: .audio)
        selectedAudioInputDeviceID = Constants.noneTag
        fftMagnitudes = Array(repeating: Float(0), count: Constants.audioBarCount)
        permissionDenied = false
        playerNodeMuted = true
        isRecording = false
        
        captureDevice = nil
        
        captureSession = nil
        audioRecorder = nil
        buffers = []
        playerNodeMutedBackup = true
        
        audioEngine.reset()
        playerNode.reset()
        playerNode.removeTap(onBus: 0)
    }
    
    func setSelectedAudioInputDevice() {
        audioInputOptions = MeetingMateModel.getAvailableDevices(mediaType: .audio)
        captureDevice = audioInputOptions?.first { $0.uniqueID == selectedAudioInputDeviceID }
        
        guard captureDevice != nil || permissionDenied else {
            resetAudioManager()
            return
        }
        
        setupCaptureSession()
        setupPassthroughAudio()
    }
    
    func setupCaptureSession() {
        captureSession = AVCaptureSession()
        audioRecorder = AVCaptureAudioFileOutput()
        
        guard let captureSession = captureSession else { return }
        guard let captureDevice = captureDevice else { return }
        guard let audioRecorder = audioRecorder else { return }
        
        if playerNodeMuted {
            mutePlayerNode()
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
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
            
            let output = AVCaptureAudioDataOutput()
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.MeetingMate.PassthroughAudioQueue"))
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
    
    func setupPassthroughAudio() {
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: monoFormat)
        audioEngine.connect(audioEngine.mainMixerNode, to: audioEngine.outputNode, format: monoFormat)
        
        do {
            try audioEngine.start()
        } catch {
#warning("show all printed errors")
            print("Error starting audio engine: \(error)")
        }
        
        playerNode.installTap(onBus: 0, bufferSize: UInt32(bufferSize), format: monoFormat) { [self] buffer, _ in
            updateFFTMagnitudes(buffer: buffer)
        }
    }
    
    func startRecording() {
        DispatchQueue.main.async {
            self.isRecording = true
        }
        playerNodeMutedBackup = playerNodeMuted
        mutePlayerNode()
        
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
        guard let audioRecorder = audioRecorder else { return }
        
        audioRecorder.stopRecording()
    }
    
    func playRecording() {
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: monoFormat)
        audioEngine.connect(audioEngine.mainMixerNode, to: audioEngine.outputNode, format: monoFormat)
        
        let audioFile = try! AVAudioFile(forReading: recordingURL)
        
        let playbackCompletionHandler: AVAudioNodeCompletionHandler = {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.playerNodeMuted = self.playerNodeMutedBackup
                
                if self.playerNodeMutedBackup {
                    self.mutePlayerNode()
                }
                else {
                    self.unmutePlayerNode()
                }
                self.isRecording = false
            }
        }
        
        unmutePlayerNode()
        playerNode.scheduleFile(audioFile, at: nil, completionHandler: playbackCompletionHandler)
        playerNode.play()
        
        playerNode.installTap(onBus: 0, bufferSize: UInt32(bufferSize), format: monoFormat) { [self] buffer, _ in
            updateFFTMagnitudes(buffer: buffer)
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
        
        var magnitudes = [Float](repeating: 0, count: Constants.audioBarCount)
        
        realOut.withUnsafeMutableBufferPointer { realBP in
            imagOut.withUnsafeMutableBufferPointer { imagBP in
                var complex = DSPSplitComplex(realp: realBP.baseAddress!, imagp: imagBP.baseAddress!)
                vDSP_zvabs(&complex, 1, &magnitudes, 1, UInt(Constants.audioBarCount))
            }
        }
        
        var normalizedMagnitudes = [Float](repeating: 0.0, count: Constants.audioBarCount)
        var scalingFactor = 2 * sensitivity
        vDSP_vsmul(&magnitudes, 1, &scalingFactor, &normalizedMagnitudes, 1, UInt(Constants.audioBarCount))
        
        return normalizedMagnitudes
    }
    
    func updateFFTMagnitudes(buffer: AVAudioPCMBuffer) {
        if let channelData = buffer.floatChannelData?[0] {
            DispatchQueue.main.async { [self] in
                let fftSetup = vDSP_DFT_zop_CreateSetup(nil, UInt(self.bufferSize), vDSP_DFT_Direction.FORWARD)
                fftMagnitudes = fft(data: channelData, setup: fftSetup!)
            }
        }
        else {
            print("error")
        }
    }
    
    func mutePlayerNode() {
        playerNode.volume =  0
        DispatchQueue.main.async {
            self.playerNodeMuted = true
        }
    }
    
    func unmutePlayerNode() {
        playerNode.volume = sensitivity
        DispatchQueue.main.async {
            self.playerNodeMuted = false
        }
    }
}

extension AudioManager: AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if !isRecording {
            if let buffer = createPCMBuffer(from: sampleBuffer) {
                buffers.append(buffer)
                scheduleNextBuffer()
            }
            else {
                print("error")
            }
        }
    }
    
    func scheduleNextBuffer() {
        bufferQueue.sync {
            if !buffers.isEmpty {
                let nextBuffer = buffers.removeFirst()
                
                playerNode.scheduleBuffer(nextBuffer) {
                    self.scheduleNextBuffer()
                }
                
                if !audioEngine.isRunning {
                    try! audioEngine.start()
                }
                playerNode.play()
            }
        }
    }
    
    // https://stackoverflow.com/questions/75228267/avaudioplayernode-causing-distortion
    func createPCMBuffer(from sampleBuffer: CMSampleBuffer) -> AVAudioPCMBuffer? {
        let numSamples = AVAudioFrameCount(sampleBuffer.numSamples)
        let format = AVAudioFormat(cmAudioFormatDescription: sampleBuffer.formatDescription!)
        
        let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: numSamples)!
        pcmBuffer.frameLength = numSamples
        CMSampleBufferCopyPCMDataIntoAudioBufferList(sampleBuffer, at: 0, frameCount: Int32(numSamples), into: pcmBuffer.mutableAudioBufferList)
        return pcmBuffer
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
