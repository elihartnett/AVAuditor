//
//  AudioRecorderView.swift
//  MeetingMate
//
//  Created by Eli Hartnett on 4/30/23.
//

import SwiftUI

struct AudioRecorderView: View {
    
    @ObservedObject var audioManager: AudioManager
    
    @State var isRecording = false
    
    var body: some View {
        
        GeometryReader { geo in
            let radius = min(geo.size.width, geo.size.height)
            let lineWidth = radius / 15
            let gap = 2 * lineWidth
            
            ZStack {
                
                RoundedRectangle(cornerRadius: isRecording ? radius / 5 : (radius / 2))
                    .fill(.red)
                    .frame(width: radius - gap, height: radius - gap)
                    .scaleEffect(isRecording ? 0.5 : 1)
                
                Circle()
                    .stroke(.gray, lineWidth: lineWidth)
                    .frame(width: radius, height: radius)
                    .padding(lineWidth / 2)
            }
        }
        .onTapGesture {
            withAnimation {
                isRecording.toggle()
            }
            if isRecording {
                audioManager.startRecording()
            }
            else {
                audioManager.stopRecording()
                audioManager.playRecording()
            }
        }
    }
}

struct AudioRecorderView_Previews: PreviewProvider {
    static var previews: some View {
        AudioRecorderView(audioManager: AudioManager())
    }
}
