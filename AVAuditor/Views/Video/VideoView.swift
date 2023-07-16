//
// VideoView.swift
// AVAuditor
//
// Created by Eli Hartnett on 4/16/23.
//

import SwiftUI

struct VideoView: View {

    @EnvironmentObject var avAuditorModel: AVAuditorModel
    
    @ObservedObject var manager: VideoManager

    var body: some View {

        VStack {

            Picker(Constants.videoInput, selection: $manager.selectedVideoInputDeviceID) {

                Text(Constants.noneTag)
                    .tag(Constants.noneTag)

                if !manager.permissionDenied {
                    ForEach(manager.videoInputOptions ?? [], id: \.self) { videoInputOption in
                        Text(videoInputOption.localizedName)
                            .tag(videoInputOption.uniqueID)
                    }
                }
            }
            .onChange(of: manager.selectedVideoInputDeviceID) { _ in
                manager.setSelectedVideoInputDevice()
            }

            if manager.captureDevice != nil {
                ZStack {
                    ProgressView()
                        .controlSize(.large)

                    VideoInputPreview(captureSession: $manager.captureSession, videoGravity: $manager.videoGravity)
                        .frame(height: avAuditorModel.navigationPath.contains(NavigableViews.settings) ? 0 : Constants.componentHeight)
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                        .background(Material.ultraThick)
                        .cornerRadius(Constants.componentCornerRadius)
                }
            }

            if manager.permissionDenied {
                PermissionDeniedView()
            }
        }
    }
}

struct VideoView_Previews: PreviewProvider {
    static var previews: some View {
        VideoView(manager: VideoManager())
    }
}
