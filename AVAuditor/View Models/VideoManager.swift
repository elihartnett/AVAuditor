//
//  VideoManager.swift
// AVAuditor
//
//  Created by Eli Hartnett on 4/24/23.
//

import AVKit
import Combine
import Foundation

class VideoManager: Errorable {

    @Published var videoInputOptions: [AVCaptureDevice]?
    @Published var selectedVideoInputDeviceID = Constants.noneTag
    @Published var captureDevice: AVCaptureDevice?
    @Published var captureSession: AVCaptureSession?
    @Published var videoGravity: VideoGravity = .fit

    @Published var permissionDenied = false

    override init() {
        super.init()
        videoInputOptions = AVAuditorModel.getAvailableDevices(mediaType: .video)
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
        videoInputOptions = AVAuditorModel.getAvailableDevices(mediaType: .video)
        selectedVideoInputDeviceID = Constants.noneTag
        captureDevice = nil
        captureSession?.stopRunning()
        captureSession = nil
        setErrorMessage(error: Constants.emptyString)
    }

    func setSelectedVideoInputDevice() {
        videoInputOptions = AVAuditorModel.getAvailableDevices(mediaType: .video)

        captureDevice = videoInputOptions?.first { $0.uniqueID == selectedVideoInputDeviceID }
        
        guard captureDevice != nil || permissionDenied else {
            resetVideoManager()
            return
        }
        
        setupCaptureSession()
    }

    func setupCaptureSession() {
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let captureSession = AVCaptureSession()

            guard let videoDevice = captureDevice, let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
                return
            }

            captureSession.addInput(videoInput)

            let videoOutput = AVCaptureVideoDataOutput()
            captureSession.addOutput(videoOutput)

            captureSession.startRunning()

            DispatchQueue.main.async {
                self.captureSession = captureSession
            }
        }
    }
}
