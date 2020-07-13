//
//  ffff.swift
//  VoiceChanger
//
//  Created by Dmitrii Ziablikov on 13.07.2020.
//  Copyright © 2020 Myna labs. All rights reserved.
//

import AVKit
import Foundation
import PromiseKit

struct MergeAudioAndVideoInput {
    let videoURL: URL
    let audioURL: AVAsset

    init(videoURL: URL, audioURL: AVAsset) {
        self.videoURL = videoURL
        self.audioURL = audioURL
    }
}

class MergeAudioAndVideo: AsyncUseCase<MergeAudioAndVideoInput, URL> {
    override func executeUseCase(resolver: Resolver<URL>) {
        let mixComposition = AVMutableComposition()
        //start merge

        let aVideoAsset = AVAsset(url: input.videoURL)
        let aAudioAsset = input.audioURL

        let compositionAddVideo = mixComposition.addMutableTrack(withMediaType: .video,
                                                                 preferredTrackID: kCMPersistentTrackID_Invalid)

        let compositionAddAudio = mixComposition.addMutableTrack(withMediaType: .audio,
                                                                 preferredTrackID: kCMPersistentTrackID_Invalid)

        guard let aVideoAssetTrack: AVAssetTrack = aVideoAsset.tracks(withMediaType: .video).first, let aAudioAssetTrack: AVAssetTrack = aAudioAsset.tracks(withMediaType: .audio).first else {
            resolver.reject(DomainError.generalWithDoNothing)
            return
        }

        // Default must have tranformation
        //compositionAddVideo?.preferredTransform = aVideoAssetTrack.preferredTransform
//        if aVideoAssetTrack.isPlayable && compositionAddVideo?.isPlayable == true {
            compositionAddVideo?.preferredTransform = aVideoAssetTrack.preferredTransform
//        }
        
//        compositionAddVideo?.preferredTransform = aVideoAssetTrack.preferredTransform
//
//         var transforms = aVideoAssetTrack.preferredTransform
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
//
//         compositionAddVideo?.preferredTransform = transforms
        
        compositionAddVideo?.preferredTransform = .identity


        do {
            try compositionAddVideo?.insertTimeRange(CMTimeRangeMake(start: .zero,
                                                                     duration: aVideoAssetTrack.timeRange.duration),
                                                     of: aVideoAssetTrack,
                                                     at: .zero)

            try compositionAddAudio?.insertTimeRange(CMTimeRangeMake(start: .zero,
                                                                     duration: aAudioAssetTrack.timeRange.duration),
                                                     of: aAudioAssetTrack,
                                                     at: .zero)
        } catch {
            print(error.localizedDescription)
        }

        let input = SaveAssetInput(asset: mixComposition,
                                          presetName: AVAssetExportPresetHighestQuality,
                                          outputFile: .mov,
                                          path: Constants.newFilteredFilePath)
        _ = SaveAsset(input: input).actWith(.none).done { videoUrl in
            resolver.fulfill(videoUrl)
        }
    }
}
