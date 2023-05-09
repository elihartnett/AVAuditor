//
//  AudioMeter.swift
//  MeetingMate
//
//  Created by Eli Hartnett on 4/16/23.
//

import SwiftUI

struct AudioMeter: View {

    @ObservedObject var audioManager: AudioManager

    var body: some View {

        GeometryReader { geo in
            let audioLevel = CGFloat((audioManager.detectedAudioLevel + 50) / 50)

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(.tertiary.opacity(Constants.halfMultiplier))

                Rectangle()
                    .fill(.primary)
                    .frame(width: geo.size.width * CGFloat(min(max(0, audioLevel), 1)))
                    .animation(.default, value: audioLevel)
            }
            .cornerRadius(Constants.componentCornerRadius)
        }
        .frame(height: Constants.componentDetailHeight)
    }
}

struct AudioMeter_Previews: PreviewProvider {
    static var previews: some View {
        AudioMeter(audioManager: AudioManager())
    }
}
