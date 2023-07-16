//
// AVAuditorApp.swift
// AVAuditor
//
// Created by Eli Hartnett on 4/15/23.
//
// Menu bar app boiler plate - https://sarunw.com/posts/swiftui-menu-bar-app/
// Reset video permission - tccutil reset Camera com.elihartnett.AVAuditor
// Reset audio permission - tccutil reset Microphone com.elihartnett.AVAuditor


import SwiftUI
import Firebase

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        FirebaseApp.configure()
    }
}

@main
struct AVAuditor: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
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
