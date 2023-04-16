//
//  VideoView.swift
//  MeetingMate
//
//  Created by Eli Hartnett on 4/16/23.
//

import SwiftUI

struct VideoView: View {
    
    @EnvironmentObject var meetingMateModel: MeetingMateModel
    
    var body: some View {
        
        VStack {
            
            Picker("Video Input", selection: $meetingMateModel.selectedVideoInputDeviceID) {
                
                Text(Constants.none)
                    .tag(Constants.none)
                
                ForEach(meetingMateModel.videoInputOptions, id: \.self) { videoInputOption in
                    Text(videoInputOption.localizedName)
                        .tag(videoInputOption.uniqueID)
                }
            }
            .onChange(of: meetingMateModel.selectedVideoInputDeviceID) { id in
                meetingMateModel.setSelectedVideoInputDevice()
            }
            
            if meetingMateModel.selectedVideoInputDevice != nil {
                VideoInputPreview(captureSession: $meetingMateModel.videoCaptureSession)
                    .frame(width: 300, height: 300)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
        }
    }
}

struct VideoView_Previews: PreviewProvider {
    static var previews: some View {
        VideoView()
    }
}
