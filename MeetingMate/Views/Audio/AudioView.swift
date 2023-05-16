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
                    AudioVisualizer(manager: manager)
                        .frame(height: Constants.componentDetailHeight)
                    
                    VStack {
                        AudioRecorderView(audioManager: manager)
                            .frame(width: Constants.componentDetailHeight, height: Constants.componentDetailHeight)
                        
                        Button {
                            withAnimation {
                                manager.passthroughMuted.toggle()
                            }
                        } label: {
                            Image(systemName: manager.passthroughMuted ? "speaker.slash" : "speaker")
                        }
                        .frame(width: Constants.componentDetailHeight, height: Constants.componentDetailHeight)
                    }
                }
                .animation(.default, value: manager.selectedAudioInputDeviceID)
            }
            
            if manager.permissionDenied {
                PermissionDeniedView()
            }
        }
    }
}

struct AudioView_Previews: PreviewProvider {
    static var previews: some View {
        AudioView(manager: AudioManager())
    }
}
