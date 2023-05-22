//
//  MeetingMateModel.swift
//  MeetingMate
//
//  Created by Eli Hartnett on 4/16/23.
//

import AVKit
import Combine
import Foundation

class MeetingMateModel: ObservableObject {

    @Published var videoManager: VideoManager

    @Published var audioManager: AudioManager

    @Published var showError = false
    @Published var errorMessage = Constants.emptyString
    private var subscriptions: Set<AnyCancellable> = []

    init() {
        self.videoManager = VideoManager()
        self.audioManager = AudioManager()

        videoManager.$errorMessage.sink { [weak self] message in
            guard !message.isEmpty else { return }
            self?.errorMessage = message
            self?.showError = true
        }
        .store(in: &subscriptions)

        audioManager.$errorMessage.sink { [weak self] message in
            guard !message.isEmpty else { return }
            self?.errorMessage = message
            self?.showError = true
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
        let devices = discoverySession.devices
        let sortedDevices = devices.sorted { lhs, rhs in
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
}
