//
// AudioRecorderView.swift
// AVAuditor
//
// Created by Eli Hartnett on 4/30/23.
//

import SwiftUI

struct AudioRecorderView: View {

    @ObservedObject var audioManager: AudioManager

    @State private var isRecording = false

    var body: some View {

        GeometryReader { geo in
            let radius = min(geo.size.width, geo.size.height)
            let lineWidth = radius * Constants.tenthMultiplier
            let gap = lineWidth * Constants.doubleMultiplier

            ZStack {

                RoundedRectangle(cornerRadius: isRecording ? radius * Constants.fifthMultiplier : (radius * Constants.halfMultiplier))
                    .fill(.red)
                    .frame(width: radius - gap, height: radius - gap)
                    .scaleEffect(isRecording ? Constants.halfMultiplier : Constants.wholeMultiplier)

                Circle()
                    .stroke(.gray, lineWidth: lineWidth)
                    .frame(width: radius, height: radius)
                    .padding(lineWidth * Constants.tenthMultiplier)
            }
        }
        .onTapGesture {
            withAnimation {
                isRecording.toggle()
            }
            if isRecording {
                audioManager.startRecording()
            } else {
                audioManager.stopRecording()
            }
        }
    }
}

struct AudioRecorderView_Previews: PreviewProvider {
    static var previews: some View {
        AudioRecorderView(audioManager: AudioManager())
    }
}
