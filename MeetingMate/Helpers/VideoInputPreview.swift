//
//  SelectedVideoInputMonitor.swift
//  MeetingMate
//
//  Created by Eli Hartnett on 4/16/23.
//

import SwiftUI
import AVKit

struct VideoInputPreview: NSViewRepresentable {
    @Binding var captureSession: AVCaptureSession?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if context.coordinator.previewLayer?.session != captureSession {
            context.coordinator.updatePreviewLayer(for: nsView, with: captureSession)
        }
    }
    
    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
        
        init(_ selectedVideoInputMonitor: VideoInputPreview) {}
        
        func updatePreviewLayer(for nsView: NSView, with captureSession: AVCaptureSession?) {
            if let currentPreviewLayer = previewLayer {
                currentPreviewLayer.removeFromSuperlayer()
            }

            guard let captureSession = captureSession, let viewLayer = nsView.layer else {
                return
            }

            let newPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            newPreviewLayer.frame = viewLayer.frame
            viewLayer.addSublayer(newPreviewLayer)

            previewLayer = newPreviewLayer
        }
    }
}
