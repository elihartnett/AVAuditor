//
//  SettingsView.swift
//  MeetingMate
//
//  Created by Eli Hartnett on 5/6/23.
//

import SwiftUI

struct SettingsView: View {
    
    @Environment(\.openURL) private var openURL
    
    @EnvironmentObject var meetingMateModel: MeetingMateModel
    
    @ObservedObject var videoManager: VideoManager
    @ObservedObject var audioManager: AudioManager
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            videoSettings
            
            Divider()
            
            audioSettings
            
            Divider()
            
            Text("\(Constants.version) \(Bundle.main.fullVersion)")
            
            Button {
                let emailAddress = Constants.emailAddress
                let subject = Constants.meetingMateFeedback
                let bodyText = meetingMateModel.getDeviceInformation()
                if let url = URL(string: "mailto:\(emailAddress)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(bodyText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                    NSWorkspace.shared.open(url)
                } else {
                    #warning("Remove prints")
                    print("error: \(Constants.errorCreateEmail)")
                }
            } label: {
                Text(Constants.submitFeedback)
            }
            
            Button(Constants.quit) {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut(Constants.quitShortcut)
        }
    }
    
    var videoSettings: some View {
        VStack(alignment: .leading) {
            Text(Constants.videoSettings)
                .bold()
            
            Picker(Constants.scale, selection: $videoManager.videoGravity) {
                ForEach(VideoGravity.allCases, id: \.self) { videoGravityCase in
                    Text(videoGravityCase.title)
                        .tag(videoGravityCase.tag)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
        .frame(maxWidth: .infinity)
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
            Text(Constants.audioSettings)
                .bold()
                .fixedSize()
            
            HStack {
                Rectangle()
                    .fill(.clear)
                    .frame(height: 1)
                    .overlay {
                        Slider(value: $audioManager.sensitivity, in: 0...2, step: 0.25)
                            .labelsHidden()
                    }
                
                Text("\(formatter.string(from: NSNumber(floatLiteral: Double(audioManager.sensitivity))) ?? "0.00")x")
                    .monospaced()
            }
        }
    }
    
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
