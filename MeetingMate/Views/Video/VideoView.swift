//
//  VideoView.swift
//  MeetingMate
//
//  Created by Eli Hartnett on 4/16/23.
//

import SwiftUI

struct VideoView: View {
    
    @ObservedObject var manager: VideoManager
    
    var body: some View {
        
        VStack {
            
            Picker("Video Input", selection: $manager.selectedVideoInputDeviceID) {
                
                Text(Constants.none)
                    .tag(Constants.none)
                
                ForEach(manager.videoInputOptions ?? [], id: \.self) { videoInputOption in
                    Text(videoInputOption.localizedName)
                        .tag(videoInputOption.uniqueID)
                }
            }
            .onChange(of: manager.selectedVideoInputDeviceID) { id in
                manager.setSelectedVideoInputDevice()
            }
            
            if manager.selectedVideoInputDevice != nil {
                ZStack {
                    ProgressView()
                        .controlSize(.large)
                    
                    VideoInputPreview(captureSession: $manager.videoCaptureSession)
                        .frame(width: 300, height: 200)
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                }
            }
        }
    }
}

struct VideoView_Previews: PreviewProvider {
    static var previews: some View {
        VideoView(manager: VideoManager())
    }
}
