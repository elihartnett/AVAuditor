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

        NavigationStack(path: $model.navigationPath) {

            VStack(spacing: 10) {

                VideoView(manager: model.videoManager)

                Divider()

                AudioView(manager: model.audioManager)

                Divider()

                HStack {
                    Text(model.errorMessage)
                        .opacity(model.showError ? Constants.wholeMultiplier : Constants.zeroMultiplier)
                        .foregroundColor(.red)
                        .animation(.default, value: model.showError)

                    Spacer()

                    Button {
                        model.navigationPath.append(NavigableViews.settings)
                    } label: {
                        Image(systemName: Constants.settingsIconName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: Constants.componentDetailHeight, height: Constants.componentDetailHeight)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .navigationDestination(for: NavigableViews.self) { navigableView in
                switch navigableView {
                case .settings:
                    SettingsView(videoManager: model.videoManager, audioManager: model.audioManager).padding()
                }
            }
        }
    }
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Home()
            .environmentObject(MeetingMateModel())
    }
}
