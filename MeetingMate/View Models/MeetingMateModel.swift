//
//  MeetingMateModel.swift
//  MeetingMate
//
//  Created by Eli Hartnett on 4/16/23.
//

import Foundation
import AVKit

class MeetingMateModel: ObservableObject {
    
    @Published var videoManager: VideoManager
    
    @Published var audioManager: AudioManager
    
    init() {
        self.videoManager = VideoManager()
        self.audioManager = AudioManager()
        
        videoManager.videoInputOptions = getAvailableDevices(mediaType: .video)
        audioManager.audioInputOptions = getAvailableDevices(mediaType: .audio)
    }
    
    func getAvailableDevices(mediaType: AVMediaType) -> [AVCaptureDevice] {
        let videoDeviceTypes: [AVCaptureDevice.DeviceType] = [.builtInWideAngleCamera, .deskViewCamera, .externalUnknown]
        let audioDeviceTypes: [AVCaptureDevice.DeviceType] = [.builtInMicrophone, .externalUnknown]
        
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: mediaType == .video ? videoDeviceTypes : audioDeviceTypes, mediaType: mediaType, position: .unspecified)
        let devices = discoverySession.devices
        let sortedDevices = devices.sorted { lhs, rhs in
            lhs.localizedName.localizedCompare(rhs.localizedName) == .orderedAscending
        }
        
        return sortedDevices
    }
}

