//
//  ApplyFilter.swift
//  VoiceChanger
//
//  Created by Dmitrii Ziablikov on 13.07.2020.
//  Copyright © 2020 Myna labs. All rights reserved.
//

import AVKit
import AudioKit
import PromiseKit

struct ApplyFilterInput {
    public let audioURL: URL
    public let videoURL: URL

    public init(audioURL: URL, videoURL: URL) {
        self.audioURL = audioURL
        self.videoURL = videoURL
    }
}

class ApplyFilter: AsyncUseCase<ApplyFilterInput, (video: URL, audio: AVAsset)> {
    override func executeUseCase(resolver: Resolver<(video: URL, audio: AVAsset)>) {
        do {
            let audioFile = try AKAudioFile(forReading: input.audioURL)
            let akAudioPlayer = try AKAudioPlayer(file: audioFile)
            let timePitch = AKTimePitch(akAudioPlayer)

            //timePitch.rate = 1.0
            timePitch.pitch = 500.0
            //timePitch.overlap = 3.0

            // Add reverberation
            let reverb = AKReverb()
            akAudioPlayer >>> reverb >>> timePitch

            AudioKit.output = timePitch

            guard let url = Constants.filteredAudioURL else {
                resolver.reject(DomainError.generalWithDoNothing)
                return
            }

            if FileManager.default.fileExists(atPath: url.path) {
                do {
                    try FileManager.default.removeItem(atPath: url.path)
                } catch {
                    resolver.reject(DomainError.generalWithMessage("Copied Video is not removed"))
                }
            }

            let outputFile = try AKAudioFile(forWriting: url, settings: [:])
            _ = AudioKit.engine.isRunning
            try AudioKit.renderToFile(outputFile, duration: akAudioPlayer.duration, prerender: {
                AKSettings.ioBufferDuration = 0.002
                akAudioPlayer.start()
            }, progress: { progress in
                if progress == 1.0 {
                    do {
                        let asset = try AKAudioFile(forReading: url)
                        resolver.fulfill((video: self.input.videoURL, audio: asset.avAsset))
                    } catch {
                        resolver.reject(DomainError.generalWithDoNothing)
                    }
                }
            })
        } catch {
            resolver.reject(DomainError.generalWithDoNothing)
        }
    }
}
