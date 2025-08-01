//
//  AudioLooper.swift
//  ChatGPTCoreModel_playground
//
//  Created by Xcode Developer on 8/1/25.
//

import AVFoundation

typealias PlayToneCompletionBlock = () -> Void
typealias CreateAudioBufferCompletionBlock = (_ buffer: AVAudioPCMBuffer, _ playToneCompletion: @escaping PlayToneCompletionBlock) -> Void

class AudioLooper {
    let audioEngine = AVAudioEngine()
    let playerOneNode = AVAudioPlayerNode()
    var mixerNode: AVAudioMixerNode { audioEngine.mainMixerNode }

    let lowFrequency: Double = 220.0
    let highFrequency: Double = 880.0

    init() {
        audioEngine.attach(playerOneNode)
        audioEngine.connect(playerOneNode, to: mixerNode, format: nil)
    }

    func createAudioBufferWithCompletionBlock(_ createAudioBufferCompletionBlock: @escaping CreateAudioBufferCompletionBlock) {
        func createAudioBuffer() -> AVAudioPCMBuffer {
            let frequency = Double.random(in: lowFrequency...highFrequency)
            let format = mixerNode.outputFormat(forBus: 0)
            let frameLength = AVAudioFrameCount(format.sampleRate)
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameLength)!
            buffer.frameLength = frameLength

            let leftChannel = buffer.floatChannelData![0]
            let isStereo = format.channelCount == 2
            let rightChannel = isStereo ? buffer.floatChannelData![1] : nil

            for i in 0..<Int(frameLength) {
                let position = Double(i) / Double(frameLength)
                let amplitude = position <= 0.5 ? position : 1.0 - position
                let value = Float(sin((frequency * Double(i) * 2 * Double.pi) / Double(frameLength))) * pow(Float(amplitude), 3)
                leftChannel[i] = value
                // Optional stereo effect (disabled)
                // if let rc = rightChannel {
                //     rc[frameLength - 1 - i] = value
                // }
            }
            return buffer
        }

        var block: (() -> Void)!
        block = {
            createAudioBufferCompletionBlock(createAudioBuffer()) {
                if self.playerOneNode.isPlaying {
                    block()
                }
            }
        }

        createAudioBufferCompletionBlock(createAudioBuffer()) {
            if self.playerOneNode.isPlaying {
                block()
            }
        }
    }

    func start() {
        guard !audioEngine.isRunning else { return }
        do {
            try audioEngine.start()
        } catch {
            print("Error starting audio engine: \(error)")
        }

        if !playerOneNode.isPlaying {
            playerOneNode.play()
        }

        createAudioBufferWithCompletionBlock { buffer, playToneCompletion in
            self.playerOneNode.scheduleBuffer(
                buffer,
                completionCallbackType: .dataPlayedBack
            ) { callbackType in
                if callbackType == .dataPlayedBack {
                    playToneCompletion()
                }
            }
        }
    }
}
