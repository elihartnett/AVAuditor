//
//  AudioView.swift
//  MeetingMate
//
//  Created by Eli Hartnett on 4/16/23.
//

import SwiftUI

struct AudioView: View {

    @ObservedObject var manager: AudioManager

    var body: some View {

        VStack {

            Picker(Constants.audioInput, selection: $manager.selectedAudioInputDeviceID) {

                Text(Constants.none)
                    .tag(Constants.none)

                if !manager.permissionDenied {
                    ForEach(manager.audioInputOptions ?? [], id: \.self) { audioInputOption in
                        Text(audioInputOption.localizedName)
                            .tag(audioInputOption.uniqueID)
                    }
                }
            }
            .onChange(of: manager.selectedAudioInputDeviceID) { _ in
                manager.setSelectedAudioInputDevice()
            }

            if manager.captureDevice != nil {
                HStack {
                    AudioMeter(audioManager: manager)
                        .frame(height: Constants.componentDetailHeight)

                    AudioRecorderView(audioManager: manager)
                        .frame(width: Constants.componentDetailHeight, height: Constants.componentDetailHeight)
                }
                .animation(.default, value: manager.selectedAudioInputDeviceID)
            }

            if manager.permissionDenied {
                PermissionDeniedView()
            }
        }
        .onAppear { manager.startAudioManager() }
    }
}

struct AudioView_Previews: PreviewProvider {
    static var previews: some View {
        AudioView(manager: AudioManager())
    }
}
