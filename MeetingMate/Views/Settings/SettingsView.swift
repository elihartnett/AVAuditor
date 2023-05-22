//
//  SettingsView.swift
//  MeetingMate
//
//  Created by Eli Hartnett on 5/6/23.
//

import SwiftUI

#warning("Remove all strings from view")
struct SettingsView: View {
    
    @Environment(\.openURL) private var openURL
    
    @ObservedObject var videoManager: VideoManager
    @ObservedObject var audioManager: AudioManager
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Form {
                
                videoSettings
                
                Divider()
                
                audioSettings
                
                Divider()
                
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
    }
    
    var videoSettings: some View {
        VStack(alignment: .leading) {
            Text("Video Settings")
                .bold()
            
            Picker("Scale", selection: $videoManager.videoGravity) {
                ForEach(VideoGravity.allCases, id: \.self) { videoGravityCase in
                    Text(videoGravityCase.title)
                        .tag(videoGravityCase.tag)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }
    
    var audioSettings: some View {
        let formatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 2
            return formatter
        }()
        
        return VStack(alignment: .leading) {
            Text("Audio Sensitivity")
                .bold()
            
            HStack {
                Slider(value: $audioManager.sensitivity, in: 0...2, step: 0.25)
                
                Text("\(formatter.string(from: NSNumber(floatLiteral: Double(audioManager.sensitivity)))!)x")
                    .monospaced()
            }
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
        SettingsView(videoManager: VideoManager(), audioManager: AudioManager())
    }
}
