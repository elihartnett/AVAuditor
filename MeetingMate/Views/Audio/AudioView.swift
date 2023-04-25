//
//  AudioView.swift
//  MeetingMate
//
//  Created by Eli Hartnett on 4/16/23.
//

import SwiftUI

struct AudioView: View {
    
    @ObservedObject var manager: AudioManager
    
    @State var mute = true
    
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
                manager.setSelectedAudioInputDevice(mute: mute)
            }
            
            if manager.selectedAudioInputDevice != nil {
                HStack {
                    AudioMeter(audioManager: manager)
                    .frame(width: 300, height: 20)
                    
                    Button {
                        mute.toggle()
                    } label: {
                        Image(systemName: mute ? "speaker.slash" : "speaker")
                    }
                    .frame(width: 20, height: 20)
                    .onChange(of: mute) { _ in
                        if mute {
                            manager.mute()
                        }
                        else {
                            manager.unmute()
                        }
                    }
                }
            }
        }
    }
}

struct AudioView_Previews: PreviewProvider {
    static var previews: some View {
        AudioView(manager: AudioManager())
    }
}


