//
//  PlayerContract.swift
//  VoiceChanger
//
//  Created by Dmitrii Ziablikov on 13.07.2020.
//  Copyright © 2020 Myna labs. All rights reserved.
//

import UIKit

enum ResourceType: String {
    case image
    case video
}

struct VideoResource {
    let url: URL?
    var duration: Float = 0
    var backColor: UIColor = #colorLiteral(red: 0.2224900723, green: 0.3040249646, blue: 0.5268210769, alpha: 1)
    var image: UIImage?
    var resourceType: ResourceType = .video
}

enum PlayerStatus {
    case unknown
    case playing
    case failed
    case paused
    case readyToPlay
}

protocol PlayerObserver: class {
    func didStartPlaying()
    func didCompletePlay()
    func didTrack(progress: Float)
    func didFailed(withError error: String, for url: URL?)
}

protocol PlayerControls: class {
    func play(with resource: VideoResource)
    func play()
    func pause()
    func stop()
    var playerStatus: PlayerStatus { get }
}
