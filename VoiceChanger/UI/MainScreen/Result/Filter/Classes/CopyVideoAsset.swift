//
//  CopyVideoAsset.swift
//  VoiceChanger
//
//  Created by Dmitrii Ziablikov on 13.07.2020.
//  Copyright © 2020 Myna labs. All rights reserved.
//

import AVKit
import PromiseKit

struct CopyVideoAssetInput {
    public let videoURL: URL

    public init(videoURL: URL) {
        self.videoURL = videoURL
    }
}

class CopyVideoAsset: AsyncUseCase<CopyVideoAssetInput, URL> {
    override func executeUseCase(resolver: Resolver<URL>) {
        let sourceAsset = AVURLAsset(url: input.videoURL)
        let input = SaveAssetInput(asset: sourceAsset,
                                          presetName: AVAssetExportPresetHighestQuality,
                                          outputFile: .mov,
                                          path: NSTemporaryDirectory() + "out.mov")
        _ = SaveAsset(input: input).actWith(.none).done {
            resolver.fulfill($0)
        } .catch {
            resolver.reject($0)
        }
    }
}
