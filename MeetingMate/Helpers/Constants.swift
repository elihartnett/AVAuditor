//
//  Constants.swift
//  MeetingMate
//
//  Created by Eli Hartnett on 4/16/23.
//

import Foundation
import SwiftUI

struct Constants {
    static let meetingMateIconName = "person.and.background.dotted"
    static let settingsIconName = "gearshape"
    static let recordingFileName = "recording.m4a"
    static let audioQueueName = "MeetingMateAudioManagerQueue"
    static let CADefaultDeviceAggregate = "CADefaultDeviceAggregate"

    static let componentHeight: CGFloat = 200
    static let componentDetailHeight: CGFloat = 20
    static let componentCornerRadius: CGFloat = 10.0
    static let audioBarCount = 40
    static let zeroMultiplier: CGFloat = .zero
    static let fifteenthMultiplier: CGFloat = 0.0667
    static let tenthMultiplier: CGFloat = 0.1
    static let fifthMultiplier: CGFloat = 0.2
    static let halfMultiplier: CGFloat = 0.5
    static let wholeMultiplier: CGFloat = 1.0
    static let doubleMultiplier: CGFloat = 2.0
    static let audioBufferSize = 1024

    static let emptyString = ""
    static let noneTag = "None"
    static let quit = "Quit"
    static let quitShortcut = KeyboardShortcut("q")
    static let videoInput = "Video Input"
    static let audioInput = "Audio Input"
    static let permissionDenied = "Permission Denied"
    static let scaleToFitTitle = "Fit"
    static let scaleToFillTitle = "Fill"
    static let scaleToFitTag = "scaleToFit"
    static let scaleToFillTag = "scaleToFill"
    static let submitFeedback = "Submit Feedback"
    static let emailAddress = "eli@elihartnett.com"
    static let meetingMateFeedback = "MeetingMate Feedback"
    static let videoSettings = "Video Settings"
    static let audioSettings = "Audio Settings"
    static let scale = "Scale"
    static let version = "Version"
    
    static let audioManagerBufferAccessQueue = "com.MeetingMate.AudioManagerBufferAccessQueue"
    static let audioManagerPassthroughAudioQueue = "com.MeetingMate.AudioManagerPassthroughAudioQueue"

    static let error = "Error"
    static let errorRecord = "Error: Failed to record"
    static let errorAddInput = "Error: Failed to add input"
    static let errorAddOutput = "Error: Failed to add output"
    static let errorStartPassthrough = "Error: Failed to start passthrough"
    static let errorGetBufferChannelData = "Error: Failed to get buffer channel data"
    static let errorCreateBuffer = "Error: Failed to create buffer"
    static let errorCreateConverter = "Error: Failed to create audio converter"
    static let errorConvertAudio = "Error: Failed to convert audio"
    static let errorGetCaptureSession = "Error: Failed to get session"
    static let errorGetCaptureDevice = "Error: Failed to get capture device"
    static let errorGetRecorder = "Error: Failed to get recorder"
    static let errorCreateEmail = "Error: Failed to create email. Please manually email \(Constants.emailAddress)"
    static let errorCreateAudioFile = "Error: Failed to read recording"
    static let errorTransformData = "Error: Failed to transform data"
    static let errorGetFFTSetup = "Error: Failed to get setup"
    static let errorGetAudioFormat = "Error: Failed to get audio format"
    static let errorPlayAudio = "Error: Failed to play audio"
}
