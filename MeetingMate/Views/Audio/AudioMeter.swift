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
                    .fill(.white)
                
                Rectangle()
                    .fill(.blue)
                    .frame(width: geo.size.width * CGFloat(min(max(0, audioLevel), 1)))
                    .animation(.default, value: audioLevel)
            }
        }
        .frame(height: 20)
    }
}

struct AudioMeter_Previews: PreviewProvider {
    static var previews: some View {
        AudioMeter(audioManager: AudioManager())
    }
}
