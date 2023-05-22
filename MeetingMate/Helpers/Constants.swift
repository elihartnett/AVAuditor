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

    static let error = "Error"
    static let errorRecord = "Error: Failed to record."
    static let errorAddInput = "Error: Failed to add input."
    static let errorAddOutput = "Error: Failed to add output."
}
