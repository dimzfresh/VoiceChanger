//
//  RemoveAudioFileFromVideo.swift
//  VoiceChanger
//
//  Created by Dmitrii Ziablikov on 13.07.2020.
//  Copyright © 2020 Myna labs. All rights reserved.
//

import AVKit
import Foundation
import PromiseKit

struct RemoveAudioFileFromVideoInput {
    let videoAssetURL: URL

    init(videoAsset: URL) {
        self.videoAssetURL = videoAsset
    }
}

class RemoveAudioFileFromVideo: AsyncUseCase<RemoveAudioFileFromVideoInput, AVTulip> {
    override func executeUseCase(resolver: Resolver<AVTulip>) {
        let videoAsset = AVURLAsset(url: input.videoAssetURL)
        let videoComposition = AVMutableComposition()
        let audioComposition = AVMutableComposition()
        let compositionVideoTrack: AVMutableCompositionTrack? = videoComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let timeRange: CMTimeRange = CMTimeRangeMake(start: .zero, duration: videoAsset.duration)
        guard let sourceVideoTrack: AVAssetTrack = videoAsset.tracks(withMediaType: .video).first else {
            resolver.reject(DomainError.generalWithMessage("Can't Get Source Audio Track"))
            return
        }

        // Extracting video
        do {
            _ = try compositionVideoTrack?.insertTimeRange(timeRange, of: sourceVideoTrack, at: .zero)
        } catch {
            resolver.reject(DomainError.generalWithUnknownError)
        }
        
        if videoAsset.isPlayable && compositionVideoTrack?.isPlayable == true {
            compositionVideoTrack?.preferredTransform = videoAsset.preferredTransform
        }
        // Rotate extracted Video for Portrait
        compositionVideoTrack?.preferredTransform = CGAffineTransform(rotationAngle: .pi / 2)

//        compositionVideoTrack?.preferredTransform = videoAsset.preferredTransform
//
//         var transforms = videoAsset.preferredTransform
//         if UIDevice.current.orientation == .landscapeLeft {
//             transforms = transforms.concatenating(CGAffineTransform(rotationAngle: CGFloat(-90.0 * .pi / 180)))
//             transforms = transforms.concatenating(CGAffineTransform(translationX: 1280, y: 0))
//         } else if UIDevice.current.orientation == .landscapeRight {
//             transforms = transforms.concatenating(CGAffineTransform(rotationAngle: CGFloat(90.0 * .pi / 180)))
//             transforms = transforms.concatenating(CGAffineTransform(translationX: 1280, y: 0))
//         } else if UIDevice.current.orientation == .portraitUpsideDown {
//             transforms = transforms.concatenating(CGAffineTransform(rotationAngle: CGFloat(180.0 * .pi / 180)))
//             transforms = transforms.concatenating(CGAffineTransform(translationX: 0, y: 720))
//         }
        //compositionVideoTrack?.preferredTransform = transforms


        // AUDIO
        let sourceAudioTracks: [AVAssetTrack] = videoAsset.tracks(withMediaType: .audio)
        // Extracting audio
        // Adding them to a new AVAsset
        for track in sourceAudioTracks {
            let compositionTrack = audioComposition.addMutableTrack(withMediaType: .audio,
                                                               preferredTrackID: kCMPersistentTrackID_Invalid)
            do {
                // Add the current audio track at the beginning of
                // the asset for the duration of the source AVAsset
                try compositionTrack?.insertTimeRange(track.timeRange,
                                                      of: track,
                                                      at: track.timeRange.start)
            } catch {
                resolver.reject(DomainError.generalWithDoNothing)
            }
        }

        let input = SaveAssetInput(asset: videoComposition,
                                          presetName: AVAssetExportPresetHighestQuality,
                                          outputFile: .mov,
                                          path: NSTemporaryDirectory() + "out.mov")
        _ = SaveAsset(input: input).actWith(.none).done { videoUrl in
            let input = SaveAssetInput(asset: audioComposition,
                                              presetName: AVAssetExportPresetAppleM4A,
                                              outputFile: .m4a,
                                              path: NSTemporaryDirectory() + "mout.m4a")
            _ = SaveAsset(input: input).actWith(.none).done { audioUrl in
                resolver.fulfill((video: videoUrl, audio: audioUrl))
            } .catch {
                resolver.reject($0)
            }
        } .catch {
            resolver.reject($0)
        }
    }
}
