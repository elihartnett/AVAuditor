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
    
    let audioProcessing = AudioProcessing.shared
    let timer = Timer.publish(
        every: 0.03,
        on: .main,
        in: .common
    ).autoconnect()
    
    private let magnitudeLimit: Float = 32
    
    @State var isPlaying = false
    @State var data = [Float]()
    
    var body: some View {
        Chart(Array(data.enumerated()), id: \.0) { index, magnitude in
            BarMark(
                x: .value("Frequency", String(index)),
                y: .value("Magnitude", magnitude)
            )
            .foregroundStyle(
                Color(
                    hue: 0.3 - Double((magnitude / magnitudeLimit) / 5),
                    saturation: 1,
                    brightness: 1,
                    opacity: 0.7
                )
            )
        }
        .onReceive(timer, perform: updateData)
        .chartYScale(domain: 0...magnitudeLimit)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: 100)
        .padding()
        .background(
            .black
                .opacity(0.3)
                .shadow(.inner(radius: 20))
        )
        .cornerRadius(10)
        .onAppear {
            playButtonTapped()
        }
    }
    
    func updateData(_: Date) {
        if isPlaying {
            withAnimation(.easeOut(duration: 0.08)) {
                data = audioProcessing.fftMagnitudes.map { min(Float($0), magnitudeLimit) }
            }
        }
    }
    
    func playButtonTapped() {
        if isPlaying {
            audioProcessing.player.pause()
        } else {
            audioProcessing.player.play()
        }
        isPlaying.toggle()
    }
}
