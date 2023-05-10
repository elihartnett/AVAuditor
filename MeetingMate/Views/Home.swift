//
//  Home.swift
//  MeetingMate
//
//  Created by Eli Hartnett on 4/15/23.
//

import AVKit
import SwiftUI

struct Home: View {

    @EnvironmentObject private var model: MeetingMateModel

    var body: some View {

        NavigationStack {

            AudioVisualizer()
//            VStack(spacing: 10) {
//
//                VideoView(manager: model.videoManager)
//
//                Divider()
//
//                AudioView(manager: model.audioManager)
//
//                Divider()
//
//                HStack {
//                    Text(model.errorMessage)
//                        .opacity(model.showError ? Constants.wholeMultiplier : Constants.zeroMultiplier)
//                        .foregroundColor(.red)
//                        .animation(.default, value: model.showError)
//
//                    Spacer()
//
//                    NavigationLink {
//                        SettingsView()
//                    } label: {
//                        Image(systemName: Constants.settingsIconName)
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: Constants.componentDetailHeight, height: Constants.componentDetailHeight)
//                    }
//                    .buttonStyle(.plain)
//                }
//            }
            .padding()
        }
    }
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Home()
            .environmentObject(MeetingMateModel())
    }
}
