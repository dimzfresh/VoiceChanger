//
//  Constants.swift
//  VoiceChanger
//
//  Created by Dmitrii Ziablikov on 13.07.2020.
//  Copyright © 2020 Myna labs. All rights reserved.
//

import Foundation

typealias AVTulip = (video: URL, audio: URL)

class Constants {
    static let filteredAudioURL = URL(string: NSTemporaryDirectory() + "newAudioOut.caf")
    static let newFilteredFilePath = NSTemporaryDirectory() + "newFiltered.mov"
}
