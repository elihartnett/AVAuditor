//
//  AudioView.swift
//  MeetingMate
//
//  Created by Eli Hartnett on 4/16/23.
//

import SwiftUI

struct AudioView: View {
    
    @ObservedObject var manager: AudioManager
    
    @State var mute = true {
        didSet {
            if mute { manager.muteLivePlayback() }
            else { manager.unmuteLivePlayback() }
        }
    }
    
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
                manager.setCaptureDevice(mute: mute)
            }
            
            if manager.captureDevice != nil {
                HStack {
                    AudioMeter(audioManager: manager)
                    .frame(width: 300, height: 20)
                    
                    Button {
                        mute.toggle()
                    } label: {
                        Image(systemName: mute ? "speaker.slash" : "speaker")
                    }
                    .frame(width: 20, height: 20)
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


