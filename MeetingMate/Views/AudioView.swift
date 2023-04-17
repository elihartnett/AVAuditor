//
//  AudioView.swift
//  MeetingMate
//
//  Created by Eli Hartnett on 4/16/23.
//

import SwiftUI

struct AudioView: View {
    
    @EnvironmentObject var meetingMateModel: MeetingMateModel
    
    var body: some View {
        
        VStack {
            
            Picker("Audio Input", selection: $meetingMateModel.selectedAudioInputDeviceID) {
                
                Text(Constants.none)
                    .tag(Constants.none)
                
                ForEach(meetingMateModel.audioInputOptions, id: \.self) { audioInputOption in
                    Text(audioInputOption.localizedName)
                        .tag(audioInputOption.uniqueID)
                }
            }
            .onChange(of: meetingMateModel.selectedAudioInputDeviceID) { id in
                meetingMateModel.setSelectedAudioInputDevice()
            }
            
            if meetingMateModel.selectedAudioInputDevice != nil {
                AudioMeter(audioManager: meetingMateModel.audioManager)
                .frame(width: 300, height: 20)
            }
        }
    }
}

struct AudioView_Previews: PreviewProvider {
    static var previews: some View {
        AudioView()
    }
}


