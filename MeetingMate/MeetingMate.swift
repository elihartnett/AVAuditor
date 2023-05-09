//
//  MeetingMateApp.swift
//  MeetingMate
//
//  Created by Eli Hartnett on 4/15/23.
//
// Menu bar app boiler plate - https://sarunw.com/posts/swiftui-menu-bar-app/
// Reset video permission - tccutil reset Camera com.elihartnett.MeetingMate
// Reset audio permission - tccutil reset Microphone com.elihartnett.MeetingMate

#warning("Analytics?")

import SwiftUI

@main
struct MeetingMate: App {

    @StateObject private var model = MeetingMateModel()

    var body: some Scene {
        MenuBarExtra {
            Home()
                .background(.tertiary.opacity(Constants.fifthMultiplier))
                .environmentObject(model)
        } label: {
            Image(systemName: Constants.meetingMateIconName)
        }
        .menuBarExtraStyle(.window)
    }
}
