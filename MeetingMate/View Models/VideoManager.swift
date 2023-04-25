//
//  VideoManager.swift
//  MeetingMate
//
//  Created by Eli Hartnett on 4/24/23.
//

import Foundation
import AVKit

class VideoManager: ObservableObject {
    
    var videoInputOptions: [AVCaptureDevice]? = nil
    @Published var selectedVideoInputDeviceID = Constants.none
    @Published var selectedVideoInputDevice: AVCaptureDevice?
    @Published var videoCaptureSession: AVCaptureSession?
    
    func setSelectedVideoInputDevice() {
        selectedVideoInputDevice = videoInputOptions?.first { $0.uniqueID == selectedVideoInputDeviceID }
        
        if selectedVideoInputDevice != nil {
            if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
                setupCaptureSession()
            }
            else {
                AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                    if granted {
                        print("access allowed")
                    } else {
                        print("access denied")
                        self.selectedVideoInputDeviceID = ""
                        self.selectedVideoInputDevice = nil
                    }
                })
            }
        }
        else {
            videoCaptureSession?.stopRunning()
            videoCaptureSession = nil
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
            captureSession.addOutput(videoOutput)
            
            captureSession.startRunning()
            
            DispatchQueue.main.async {
                self.videoCaptureSession = captureSession
            }
        }
    }
}
