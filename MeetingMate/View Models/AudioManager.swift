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
    @Published var fftMagnitudes: [Float] = []
    @Published var permissionDenied = false
    
    var captureDevice: AVCaptureDevice?
    
    private var captureSession: AVCaptureSession?
    private var audioRecorder: AVCaptureAudioFileOutput?
    private var buffers: [AVAudioPCMBuffer] = []

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
        audioInputOptions = MeetingMateModel.getAvailableDevices(mediaType: .audio)
        selectedAudioInputDeviceID = Constants.none
        captureDevice = nil
        captureSession = nil
    }
    
    func setSelectedAudioInputDevice() {
        audioInputOptions = MeetingMateModel.getAvailableDevices(mediaType: .audio)
        captureDevice = audioInputOptions?.first { $0.uniqueID == selectedAudioInputDeviceID }
        
        if captureDevice != nil {
            if !permissionDenied {
                // self.startAudioManager()
                startPassthroughAudio()
            }
        } else { selectedAudioInputDeviceID = Constants.none }
    }
    
    func startPassthroughAudio() {
        // Create capture session
        captureSession = AVCaptureSession()
        
        // Add selected capture device to capture session
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            captureSession?.addInput(input)
        } catch {
            print("Error setting up audio input: \(error)")
            return
        }
        
        // Create output location; Redirect all capture session output to delegate
        let output = AVCaptureAudioDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.MeetingMate.PassthroughAudioQueue"))
        captureSession?.addOutput(output)
        
        // Start capture session (Start sending output to delegate)
        captureSession?.startRunning()
        
        // Attach player node to audio engine
        audioEngine.attach(playerNode)
        
        // player node -> mainMixerNode
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: monoFormat)
        
        // mainMixerNode -> audioEngine output
        audioEngine.connect(audioEngine.mainMixerNode, to: audioEngine.outputNode, format: monoFormat)
        
        do {
            try audioEngine.start()
        } catch {
            print("Error starting audio engine: \(error)")
        }
        
        let fftSetup = vDSP_DFT_zop_CreateSetup(
            nil,
            UInt(bufferSize),
            vDSP_DFT_Direction.FORWARD
        )
        
        audioEngine.mainMixerNode.installTap(
            onBus: 0,
            bufferSize: UInt32(bufferSize),
            format: monoFormat
        ) { [self] buffer, _ in
            let channelData = buffer.floatChannelData?[0]
            DispatchQueue.main.async { [self] in
                fftMagnitudes = fft(data: channelData!, setup: fftSetup!)
            }
        }
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
        #warning("Correlate with mic sensitivity")
        playerNode.volume = 1
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
    
    func muteLivePlayback() {
        audioEngine.mainMixerNode.outputVolume = 0
    }
    
    func unmuteLivePlayback() {
        audioEngine.mainMixerNode.outputVolume = 1
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
        #warning("Add sensitivity to settings")
        var scalingFactor = Float(1)
        vDSP_vsmul(&magnitudes, 1, &scalingFactor, &normalizedMagnitudes, 1, UInt(Constants.audioBarCount))
        
        return normalizedMagnitudes
    }
}

extension AudioManager: AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let buffer = createPCMBuffer(from: sampleBuffer) {
            bufferQueue.sync {
                buffers.append(buffer)
            }
        }
        
        scheduleNextBuffer()
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
