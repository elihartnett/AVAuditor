//
//  AudioView.swift
//  MeetingMate
//
//  Created by Eli Hartnett on 4/16/23.
//

import SwiftUI

struct AudioView: View {
    
    @ObservedObject var manager: AudioManager
    
    let height: CGFloat = 20
    
    var body: some View {
        
        VStack {
            
            Picker("Audio Input", selection: $manager.selectedAudioInputDeviceID) {
                
                Text(Constants.none)
                    .tag(Constants.none)
                
                ForEach(manager.audioInputOptions ?? [], id: \.self) { audioInputOption in
                    Text(audioInputOption.localizedName)
                        .tag(audioInputOption.uniqueID)
                }
            }
            .onChange(of: manager.selectedAudioInputDeviceID) { id in
                manager.setCaptureDevice()
            }
            
            if manager.captureDevice != nil {
                HStack {
                    AudioMeter(audioManager: manager)
                        .frame(height: height)
                    
                    AudioRecorderView(audioManager: manager)
                        .frame(width: height, height: height)
                }
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


