//
// AVAuditorModel.swift
// AVAuditor
//
// Created by Eli Hartnett on 4/16/23.
//

import AVKit
import Combine
import Foundation
import IOKit
import SwiftUI

class AVAuditorModel: ObservableObject {
    
    @Published var navigationPath = [NavigableViews]()

    @Published var videoManager: VideoManager
    @Published var audioManager: AudioManager

    @Published var errorMessage = Constants.emptyString
    private var subscriptions: Set<AnyCancellable> = []

    init() {
        self.videoManager = VideoManager()
        self.audioManager = AudioManager()

        videoManager.$errorMessage.sink { [weak self] message in
            self?.errorMessage = message
        }
        .store(in: &subscriptions)

        audioManager.$errorMessage.sink { [weak self] message in
            self?.errorMessage = message
        }
        .store(in: &subscriptions)
        
        NotificationCenter.default.addObserver(self, selector: #selector(deviceWasDisconnected), name: NSNotification.Name.AVCaptureDeviceWasDisconnected, object: videoManager.captureSession)
        NotificationCenter.default.addObserver(self, selector: #selector(deviceWasConnected), name: NSNotification.Name.AVCaptureDeviceWasConnected, object: videoManager.captureSession)
                
        NotificationCenter.default.addObserver(self, selector: #selector(deviceWasDisconnected), name: NSNotification.Name.AVCaptureDeviceWasDisconnected, object: audioManager.captureSession)
        NotificationCenter.default.addObserver(self, selector: #selector(deviceWasConnected), name: NSNotification.Name.AVCaptureDeviceWasConnected, object: audioManager.captureSession)
    }

    static func getAvailableDevices(mediaType: AVMediaType) -> [AVCaptureDevice] {
        let videoDeviceTypes: [AVCaptureDevice.DeviceType] = [.builtInWideAngleCamera, .deskViewCamera, .externalUnknown]
        let audioDeviceTypes: [AVCaptureDevice.DeviceType] = [.builtInMicrophone, .externalUnknown]

        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: mediaType == .video ? videoDeviceTypes : audioDeviceTypes, mediaType: mediaType, position: .unspecified)
        var discoveredDevices = discoverySession.devices
        discoveredDevices.removeAll(where: { $0.localizedName.contains(Constants.CADefaultDeviceAggregate)})
    
        let sortedDevices = discoveredDevices.sorted { lhs, rhs in
            lhs.localizedName.localizedCompare(rhs.localizedName) == .orderedAscending
        }
        
        return sortedDevices
    }
    
    @objc
    func deviceWasDisconnected(notification: NSNotification) {
        videoManager.setSelectedVideoInputDevice()
        audioManager.setSelectedAudioInputDevice()
    }

    @objc
    func deviceWasConnected(notification: NSNotification) {
        videoManager.setSelectedVideoInputDevice()
        audioManager.setSelectedAudioInputDevice()
    }
    
    func getDeviceInformation() -> String {
        let videoDevice = videoManager.captureDevice?.activeFormat.formatDescription as Any?
        let audioDevice = audioManager.captureDevice?.activeFormat.formatDescription as Any?
        let appVersion = Bundle.main.fullVersion
        
        return """
        -----------------------------
        Video device: \(videoDevice ?? Constants.noneTag)
        Audio device: \(audioDevice ?? Constants.noneTag)
        App Version: \(appVersion)
        -----------------------------\n\n
        """
    }
}
