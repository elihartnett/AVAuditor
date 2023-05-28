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
    private let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 2)
    private let bufferQueue = DispatchQueue(label: "com.MeetingMate.BufferAccessQueue")
    private let fftSetup = vDSP_DFT_zop_CreateSetup(nil, UInt(Constants.audioBufferSize), vDSP_DFT_Direction.FORWARD)
    
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
        
        setupCaptureSession()
        setupPassthroughAudio()
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
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            self.errorMessage = Constants.emptyString
            self.audioInputOptions = MeetingMateModel.getAvailableDevices(mediaType: .audio)
            self.selectedAudioInputDeviceID = Constants.noneTag
            self.fftMagnitudes = Array(repeating: Float(0), count: Constants.audioBarCount)
            self.permissionDenied = false
            self.playerNodeMuted = true
            self.isRecording = false
            
            self.captureDevice = nil
            
            self.captureSession = nil
            self.audioRecorder = nil
            self.buffers = []
            self.playerNodeMutedBackup = true
            
            self.playerNode.reset()
            self.playerNode.removeTap(onBus: 0)
            self.audioEngine.reset()
        }
    }
    
    func setSelectedAudioInputDevice() {
        guard !permissionDenied else {
            resetAudioManager()
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.audioInputOptions = MeetingMateModel.getAvailableDevices(mediaType: .audio)
        }
        captureDevice = audioInputOptions?.first { $0.uniqueID == selectedAudioInputDeviceID }
        
        guard let captureDevice else {
            resetAudioManager()
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.fftMagnitudes = Array(repeating: Float(0), count: Constants.audioBarCount)
            setupCaptureSession()
            setupPassthroughAudio()
        }

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
                setErrorMessage(error: Constants.errorAddInput)
            }
            
            if captureSession.canAddOutput(audioRecorder) {
                captureSession.addOutput(audioRecorder)
            } else {
                setErrorMessage(error: Constants.errorAddOutput)
            }
            
            let output = AVCaptureAudioDataOutput()
#warning("Get queue strings out")
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.MeetingMate.PassthroughAudioQueue"))
            if captureSession.canAddOutput(output) {
                captureSession.addOutput(output)
            } else {
                setErrorMessage(error: Constants.errorAddOutput)
            }
            
            captureSession.startRunning()
        } catch {
            setErrorMessage(error: Constants.error)
        }
    }
    
    func setupPassthroughAudio() {
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: audioFormat)
        audioEngine.connect(audioEngine.mainMixerNode, to: audioEngine.outputNode, format: audioFormat)
        
        do {
            try audioEngine.start()
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = Constants.errorStartPassthrough
            }
        }
        
        playerNode.removeTap(onBus: 0)
        playerNode.installTap(onBus: 0, bufferSize: UInt32(Constants.audioBufferSize), format: audioFormat) { [self] buffer, _ in
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
                setErrorMessage(error: Constants.errorRecord)
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
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: audioFormat)
        audioEngine.connect(audioEngine.mainMixerNode, to: audioEngine.outputNode, format: audioFormat)
        
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
    }
    
    // Fast Fourier Transform
    func fft(data: UnsafeMutablePointer<Float>, setup: OpaquePointer) -> [Float] {
        var realIn = [Float](repeating: 0, count: Constants.audioBufferSize)
        var imagIn = [Float](repeating: 0, count: Constants.audioBufferSize)
        var realOut = [Float](repeating: 0, count: Constants.audioBufferSize)
        var imagOut = [Float](repeating: 0, count: Constants.audioBufferSize)
        
        for i in 0 ..< Constants.audioBufferSize {
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
        guard let channelData = buffer.floatChannelData?[0] else {
            setErrorMessage(error: Constants.errorBufferChannelData)
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            fftMagnitudes = fft(data: channelData, setup: fftSetup!)
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
    
    func setErrorMessage(error: String) {
        DispatchQueue.main.async {
            self.errorMessage = error
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
                setErrorMessage(error: Constants.errorCreateBuffer)
            }
        }
    }
    
    func scheduleNextBuffer() {
        bufferQueue.sync {
            if !buffers.isEmpty {
                var nextBuffer = buffers.removeFirst()
                
                if nextBuffer.format != audioFormat {
                    #warning("look for all force unwraps")
                    nextBuffer = convertBuffer(nextBuffer, to: audioFormat!)!
                }
                
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
    
    func convertBuffer(_ buffer: AVAudioPCMBuffer, to format: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard let converter = AVAudioConverter(from: buffer.format, to: format) else {
            #warning("Need to log all new errors where guards are")
            return nil
        }

        let ratio = format.sampleRate / buffer.format.sampleRate
        let newBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: buffer.frameCapacity * UInt32(ratio))!
        let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }

        var error: NSError?
        converter.convert(to: newBuffer, error: &error, withInputFrom: inputBlock)

        if let error = error {
            print("Error during format conversion: \(error.localizedDescription)")
            return nil
        }
        
        return newBuffer
    }
}

extension AudioManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        guard error == nil else {
            setErrorMessage(error: Constants.errorRecord)
            return
        }
        playRecording()
    }
}
