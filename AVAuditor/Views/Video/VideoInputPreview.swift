//
//  SelectedVideoInputMonitor.swift
// AVAuditor
//
//  Created by Eli Hartnett on 4/16/23.
//

import AVKit
import SwiftUI

struct VideoInputPreview: NSViewRepresentable {
    @Binding var captureSession: AVCaptureSession?
    @Binding var videoGravity: VideoGravity

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
        
        switch videoGravity {
        case .fit:
            context.coordinator.previewLayer?.videoGravity = .resizeAspect
        case .fill:
            context.coordinator.previewLayer?.videoGravity = .resizeAspectFill
        }
    }


    class Coordinator {
        var parent: VideoInputPreview
        var previewLayer: AVCaptureVideoPreviewLayer?

        init(_ parent: VideoInputPreview) {
            self.parent = parent
        }

        func updatePreviewLayer(for nsView: NSView, with captureSession: AVCaptureSession?) {
            if let currentPreviewLayer = previewLayer {
                currentPreviewLayer.removeFromSuperlayer()
            }

            guard let captureSession = captureSession, let viewLayer = nsView.layer else {
                return
            }

            let newPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            newPreviewLayer.frame = viewLayer.bounds

            viewLayer.addSublayer(newPreviewLayer)
            previewLayer = newPreviewLayer
        }
    }
}
