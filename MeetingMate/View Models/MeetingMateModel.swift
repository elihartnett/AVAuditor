//
//  MeetingMateModel.swift
//  MeetingMate
//
//  Created by Eli Hartnett on 4/16/23.
//

import Foundation
import AVKit

class MeetingMateModel: ObservableObject {
    
    @Published var audioManager = AudioManager()
    
    // Video input
    @Published var selectedVideoInputDeviceID = Constants.none
    @Published var selectedVideoInputDevice: AVCaptureDevice?
    var videoInputOptions: [AVCaptureDevice] {
        getAvailableDevices(mediaType: .video)
    }
    @Published var videoCaptureSession: AVCaptureSession?
    
    // Audio input
    @Published var selectedAudioInputDeviceID = Constants.none
    @Published var selectedAudioInputDevice: AVCaptureDevice?
    var audioInputOptions: [AVCaptureDevice] {
        getAvailableDevices(mediaType: .audio)
    }
        
    
    // Functions
    func getAvailableDevices(mediaType: AVMediaType) -> [AVCaptureDevice] {
        let videoDeviceTypes: [AVCaptureDevice.DeviceType] = [.builtInWideAngleCamera, .deskViewCamera, .externalUnknown]
        let audioDeviceTypes: [AVCaptureDevice.DeviceType] = [.builtInMicrophone, .externalUnknown]
        
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: mediaType == .video ? videoDeviceTypes : audioDeviceTypes, mediaType: mediaType, position: .unspecified)
        let devices = discoverySession.devices
        
        return devices
    }
    
    func setSelectedVideoInputDevice() {
        selectedVideoInputDevice = videoInputOptions.first { $0.uniqueID == selectedVideoInputDeviceID }
        
        if selectedVideoInputDevice != nil {
            if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
                setupVideoCaptureSession()
            } else {
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
    
    func setSelectedAudioInputDevice() {
        if AVCaptureDevice.authorizationStatus(for: .audio) ==  .authorized {
            selectedAudioInputDevice = audioInputOptions.first { $0.uniqueID == selectedAudioInputDeviceID }
        }
        else {
            AVCaptureDevice.requestAccess(for: .audio, completionHandler: { granted in
                if granted {
                    print("access allowed")
                } else {
                    print("access denied")
                    self.selectedAudioInputDeviceID = ""
                    self.selectedAudioInputDevice = nil
                }
            })
        }
    }
    
    func setupVideoCaptureSession() {
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

