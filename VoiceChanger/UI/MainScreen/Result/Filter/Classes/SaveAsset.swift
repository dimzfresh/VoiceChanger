//
//  SaveAssetUseCase.swift
//  VoiceChanger
//
//  Created by Dmitrii Ziablikov on 13.07.2020.
//  Copyright © 2020 Myna labs. All rights reserved.
//

import AVKit
import Foundation
import PromiseKit

struct SaveAssetInput {
    let asset: AVAsset
    let presetName: String
    let outputFile: AVFileType
    let path: String

    init(asset: AVAsset, presetName: String, outputFile: AVFileType, path: String) {
        self.asset = asset
        self.presetName = presetName
        self.outputFile = outputFile
        self.path = path
    }
}

class SaveAsset: AsyncUseCase<SaveAssetInput, URL> {
    override func executeUseCase(resolver: Resolver<URL>) {
        // Get url for output
        let outputUrl = URL(fileURLWithPath: input.path)
        if FileManager.default.fileExists(atPath: outputUrl.path) {
            do {
                try FileManager.default.removeItem(atPath: outputUrl.path)
            } catch {
                resolver.reject(DomainError.generalWithMessage("Copied Video is not removed"))
            }
        }

        // Create an export session
        let exportSession = AVAssetExportSession(asset: input.asset, presetName: input.presetName)
        exportSession?.outputFileType = input.outputFile
        exportSession?.outputURL = outputUrl
        exportSession?.shouldOptimizeForNetworkUse = true

        // Export file
        exportSession?.exportAsynchronously {
            guard case exportSession?.status = AVAssetExportSession.Status.completed else {
                resolver.reject(DomainError.generalWithMessage("Video is not copied"))
                return
            }
            resolver.fulfill(outputUrl)
        }
    }
}
