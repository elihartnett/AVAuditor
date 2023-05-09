//
//  VideoManager.swift
//  MeetingMate
//
//  Created by Eli Hartnett on 4/24/23.
//

import AVKit
import Combine
import Foundation

class VideoManager: Errorable {

    @Published var videoInputOptions: [AVCaptureDevice]?
    @Published var selectedVideoInputDeviceID = Constants.none
    @Published var selectedVideoInputDevice: AVCaptureDevice?
    @Published var videoCaptureSession: AVCaptureSession?

    @Published var permissionDenied = false

    private var timeoutTimer = Timer.scheduledTimer(timeInterval: Constants.halfMultiplier, target: VideoManager.self, selector: #selector(timeoutTimerHandler), userInfo: nil, repeats: false)

    override init() {
        super.init()
        videoInputOptions = MeetingMateModel.getAvailableDevices(mediaType: .video)
        checkPermissions()
    }

    func checkPermissions() {
        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
            permissionDenied = false
        } else {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if granted {
                    self.permissionDenied = false
                } else {
                    self.permissionDenied = true
                    DispatchQueue.main.async {
                        self.resetVideoManager()
                    }
                }
            })
        }
    }

    func resetVideoManager() {
        videoInputOptions = MeetingMateModel.getAvailableDevices(mediaType: .video)
        selectedVideoInputDeviceID = Constants.none
        selectedVideoInputDevice = nil
        videoCaptureSession?.stopRunning()
        videoCaptureSession = nil
        timeoutTimer.invalidate()
    }

    func setSelectedVideoInputDevice() {
        videoInputOptions = MeetingMateModel.getAvailableDevices(mediaType: .video)

        selectedVideoInputDevice = videoInputOptions?.first { $0.uniqueID == selectedVideoInputDeviceID }

        if selectedVideoInputDevice != nil {
            if !permissionDenied {
                setupCaptureSession()
            }
        } else {
            resetVideoManager()
        }
    }

    func setupCaptureSession() {
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let captureSession = AVCaptureSession()

            guard let videoDevice = selectedVideoInputDevice, let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
                return
            }

            captureSession.addInput(videoInput)

            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "test"))
            captureSession.addOutput(videoOutput)

            captureSession.startRunning()

            DispatchQueue.main.async {
                self.videoCaptureSession = captureSession
            }
        }
    }
}

extension VideoManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        timeoutTimer.invalidate()
    }

    @objc private func timeoutTimerHandler() {
        errorMessage = Constants.errorRecord
        resetVideoManager()
    }
}
