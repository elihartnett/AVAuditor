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
}
