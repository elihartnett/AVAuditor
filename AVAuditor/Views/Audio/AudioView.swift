//
//  AudioView.swift
// AVAuditor
//
//  Created by Eli Hartnett on 4/16/23.
//

import SwiftUI

struct AudioView: View {
    
    @ObservedObject var manager: AudioManager
    
    var body: some View {
        
        VStack {
            
            Picker(Constants.audioInput, selection: $manager.selectedAudioInputDeviceID) {
                
                Text(Constants.noneTag)
                    .tag(Constants.noneTag)
                
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
                                if manager.playerNodeMuted {
                                    manager.unmutePlayerNode()
                                }
                                else {
                                    manager.mutePlayerNode()
                                }
                            }
                        } label: {
                            Image(systemName: manager.playerNodeMuted ? "speaker.slash" : "speaker")
                        }
                        .disabled(manager.isRecording)
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
