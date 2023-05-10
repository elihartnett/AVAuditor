//
//  SignalProcessing.swift
//  AudioVisualizer
//
//  Created by Alex Barbulescu on 2019-09-02.
//  Copyright © 2019 alex. All rights reserved.
//
// https://betterprogramming.pub/audio-visualization-in-swift-using-metal-accelerate-part-1-390965c095d7

import Accelerate
import AVFoundation

class AudioProcessing {
    static var shared: AudioProcessing = .init()

    private let engine = AVAudioEngine()
    private let bufferSize = 1024

    let barAmount = 40

    let player = AVAudioPlayerNode()
    var fftMagnitudes: [Float] = []

    init() {
        _ = engine.mainMixerNode

        engine.prepare()
        try! engine.start()

        /**
         - Music: Moonlight Sonata Op. 27 No. 2 - III. Presto
         - Performed by: Paul Pitman
         - https://musopen.org/music/2547-piano-sonata-no-14-in-c-sharp-minor-moonlight-sonata-op-27-no-2/
         */
        let url = Bundle.main.url(forResource: "music", withExtension: "mp3")!
        let audioFile = try! AVAudioFile(forReading: url)
        let format = audioFile.processingFormat

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)

        player.scheduleFile(audioFile, at: nil)

        let fftSetup = vDSP_DFT_zop_CreateSetup(
            nil,
            UInt(bufferSize),
            vDSP_DFT_Direction.FORWARD
        )

        engine.mainMixerNode.installTap(
            onBus: 0,
            bufferSize: UInt32(bufferSize),
            format: nil
        ) { [self] buffer, _ in
            let channelData = buffer.floatChannelData?[0]
            fftMagnitudes = fft(data: channelData!, setup: fftSetup!)
        }
    }

    func fft(data: UnsafeMutablePointer<Float>, setup: OpaquePointer) -> [Float] {
        var realIn = [Float](repeating: 0, count: bufferSize)
        var imagIn = [Float](repeating: 0, count: bufferSize)
        var realOut = [Float](repeating: 0, count: bufferSize)
        var imagOut = [Float](repeating: 0, count: bufferSize)

        for i in 0 ..< bufferSize {
            realIn[i] = data[i]
        }

        vDSP_DFT_Execute(setup, &realIn, &imagIn, &realOut, &imagOut)

        var magnitudes = [Float](repeating: 0, count: barAmount)

        realOut.withUnsafeMutableBufferPointer { realBP in
            imagOut.withUnsafeMutableBufferPointer { imagBP in
                var complex = DSPSplitComplex(realp: realBP.baseAddress!, imagp: imagBP.baseAddress!)
                vDSP_zvabs(&complex, 1, &magnitudes, 1, UInt(barAmount))
            }
        }

        var normalizedMagnitudes = [Float](repeating: 0.0, count: barAmount)
        var scalingFactor = Float(1)
        vDSP_vsmul(&magnitudes, 1, &scalingFactor, &normalizedMagnitudes, 1, UInt(barAmount))

        return normalizedMagnitudes
    }
}
