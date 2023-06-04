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
                    VStack(spacing: 0) {
                        let visualizer = AudioVisualizer(manager: manager)
                        
                        visualizer
                        visualizer
                            .scaleEffect(x: 1, y: -1) // Mirroring and flipping over the x-axis
                    }
                    .frame(height: Constants.componentDetailHeight * 2)
                    
                    VStack {
                        #warning("Temporarily removed. Can bring back if added to video view as well.")
                        //                        AudioRecorderView(audioManager: manager)
                        //                            .frame(width: Constants.componentDetailHeight, height: Constants.componentDetailHeight)
                        
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
                            Image(systemName: manager.playerNodeMuted ? Constants.mutedIcon : Constants.unmutedIcon)
                                .foregroundColor(.primary)
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
