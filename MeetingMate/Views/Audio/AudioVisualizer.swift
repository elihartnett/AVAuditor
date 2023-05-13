//
//  AudioVisualizer.swift
//  AudioVisualizer
//
//  Created by Alex Barbulescu on 2019-04-06.
//  Copyright © 2019 alex. All rights reserved.
//

import Accelerate
import AVKit
import Charts
import SwiftUI

struct AudioVisualizer: View {

    @ObservedObject var manager: AudioManager

    private let magnitudeLimit: Float = 32

    @State var data = [Float]()

    var body: some View {
        Chart(Array(data.enumerated()), id: \.0) { index, magnitude in
            BarMark(
                x: .value("Frequency", String(index)),
                y: .value("Magnitude", max(0.1, magnitude))
            )
            .foregroundStyle(.white)
        }
        .onChange(of: manager.fftMagnitudes) { _ in
            updateData()
        }
        .chartYScale(domain: 0...magnitudeLimit)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: 100)
        .padding()
        .cornerRadius(10)
    }

    func updateData() {
        withAnimation {
            data = manager.fftMagnitudes.map { min(Float($0), magnitudeLimit) }

        }
    }
}
