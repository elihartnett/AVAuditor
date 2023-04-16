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
        
        VStack {
            
            VideoView()
            
            AudioView()
            
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
