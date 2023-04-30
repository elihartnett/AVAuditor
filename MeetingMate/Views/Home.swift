//
//  Home.swift
//  MeetingMate
//
//  Created by Eli Hartnett on 4/15/23.
//

import SwiftUI
import AVKit

struct Home: View {
    
    @EnvironmentObject var meetingMateModel: MeetingMateModel
    
    var body: some View {
        
        VStack(spacing: 10) {
            
            VideoView(manager: meetingMateModel.videoManager)
            
            Divider()
            
            AudioView(manager: meetingMateModel.audioManager)
            
            Divider()
                        
            Button("Quit") {
                
                NSApplication.shared.terminate(nil)
                
            }.keyboardShortcut("q")
        }
        .padding()
    }
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Home()
            .environmentObject(MeetingMateModel())
    }
}
