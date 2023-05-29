//
// AVAuditorApp.swift
// AVAuditor
//
//  Created by Eli Hartnett on 4/15/23.
//
// Menu bar app boiler plate - https://sarunw.com/posts/swiftui-menu-bar-app/
// Reset video permission - tccutil reset Camera com.elihartnett.AVAuditor
// Reset audio permission - tccutil reset Microphone com.elihartnett.AVAuditor

#warning("Analytics?")

import SwiftUI

@main
struct AVAuditor: App {

    @StateObject private var model = AVAuditorModel()

    var body: some Scene {
        MenuBarExtra {
            Home()
                .background(.tertiary.opacity(Constants.fifthMultiplier))
                .environmentObject(model)
        } label: {
            Image(systemName: Constants.AVAuditorIconName)
        }
        .menuBarExtraStyle(.window)
    }
}
