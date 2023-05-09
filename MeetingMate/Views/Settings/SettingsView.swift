//
//  SettingsView.swift
//  MeetingMate
//
//  Created by Eli Hartnett on 5/6/23.
//

import SwiftUI

struct SettingsView: View {

    @Environment(\.openURL) private var openURL

    var body: some View {

        Form {

            Text("Version \(Bundle.main.shortVersion)")

            Button(action: {
                        NSWorkspace.shared.open(URL(string: "mailto:")!)
                    }) {
                        Text("Open Email App")
                    }

            Button {
                if let url = URL(string: "mailto:") {
                    NSWorkspace.shared.open(url)
                } else {
                    print("error")
                }
            } label: {
                Text("Submit Feedback")
            }

            Button(Constants.quit) {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut(Constants.quitShortcut)
        }
    }

//    var submitFeedbackButton: some View {
//        Button {
//            if EmailViewRepresentable.canSendEmail() {
//                showEmailVIew = true
//            } else {
//                if let url = URL(string: "mailto:\(Strings.emailAddress)") {
//                    alertTitle = Strings.failedToOpenEmailURLErrorMessage
//                    showAlert = true
//                    if UIApplication.shared.canOpenURL(url) {
//                        UIApplication.shared.open(url)
//                    } else {
//                        alertTitle = Strings.failedToOpenEmailURLErrorMessage
//                        showAlert = true
//                    }
//                } else {
//                    alertTitle = Strings.failedToCreateEmailURLErrorMessage
//                    showAlert = true
//                }
//            }
//        } label: {
//            Text(Strings.submitFeedbackLabel)
//        }
//    }

//    var writeAReviewButton: some View {
//        Group {
//            if let url = URL(string: "https://apps.apple.com/app/id\(Constants.appID)?action=write-review") {
//                Button {
//                    openURL(url)
//                } label: {
//                    Text("Write A Review")
//                }
//            }
//        }
//    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
