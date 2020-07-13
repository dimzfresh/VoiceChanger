//
//  ResultViewController.swift
//  VoiceChanger
//
//  Created by Dmitrii Ziablikov on 13.07.2020.
//  Copyright © 2020 Myna labs. All rights reserved.
//

import UIKit
import AudioKit
import PromiseKit

class ResultViewController: UIViewController {
    
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var playAndPauseButton: UIButton!
    @IBOutlet private weak var playerView: PlayerView!
    @IBOutlet private weak var previewImageView: UIImageView!
    
    private var filterViewManager: FilterViewManager?
    private var audioEngine: AVAudioEngine = AVAudioEngine()
    private var changePitchEffect: AVAudioUnitTimePitch = AVAudioUnitTimePitch()
    
    private var videoURL: URL?
    private var audioURL: URL?
    
    private var newAudioURL: URL?
    private var newVideoURL: URL?
    
    private var videoManager: VideoManager?
        
    private var filterItems: [FilterItem] = [
        .init(name: "Без фильтра", isSelected: true),
        .init(name: "Классный"),
        .init(name: "Супер классный"),
        .init(name: "ну, попробуй"),
        .init(name: "Абракадабра"),
        .init(name: "Скорее попробуй")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        enablePopGesture()
    }
    
    func attach(videoURL: URL?) {
        self.videoURL = videoURL
        self.newVideoURL = videoURL
        guard let videoURL = videoURL else { return }
        videoManager = VideoManager(videoURL: videoURL)
        
        let asset = AVURLAsset(url: videoURL, options: nil)

        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        guard let fileUrl = paths.first?.appendingPathComponent("audio.m4a") else { return }
        try? FileManager.default.removeItem(at: fileUrl)

        audioURL = fileUrl

        asset.writeAudioTrackToURL(fileUrl) { success, error in
            if success {}
        }
    }
    
    @IBAction private func playAndPauseButtonTapped(_ sender: Any) {
        play()
    }
    
    @IBAction private func backButtonTapped(_ sender: Any) {
        close()
    }
    
    @IBAction private func shareButtonTapped(_ sender: Any) {
        share()
    }
    
}

extension ResultViewController: UIGestureRecognizerDelegate {}

extension ResultViewController: PlayerObserver {
    func didStartPlaying() {
        print("Start playing")
        playAndPauseButton.setImage(#imageLiteral(resourceName: "pause_button"), for: .normal)
    }
    
    func didCompletePlay() {
        print("Complete playing")
        previewImageView.isHidden = false
        playerView.stop()
        playAndPauseButton.setImage(#imageLiteral(resourceName: "play_button"), for: .normal)
    }
    
    func didTrack(progress: Float) {
        print("Progress: \(progress)")
    }
    
    func didFailed(withError error: String, for url: URL?) {
        print(error)
        playAndPauseButton.setImage(#imageLiteral(resourceName: "play_button"), for: .normal)
    }
}

private extension ResultViewController {
    func setup() {
        setupPlayer()
        setupViewManager()
        setupPreviewImage()
    }
    
    func setupPreviewImage() {
        guard let url = videoURL else { return }
        DispatchQueue.main.async {
            self.previewImageView.image = self.playerView.videoPreviewImage(url: url)
        }
    }
    
    func setupPlayer() {
        playerView.playerObserverDelegate = self
    }
    
    func setupViewManager() {
        filterViewManager = FilterViewManager(collectionView: collectionView)
        filterViewManager?.filters = filterItems
        filterViewManager?.onSelectFilterItem = { [weak self] index in
            self?.writeAudioTrackToURL(index: index)
        }
    }
    
    func writeAudioTrackToURL(index: Int) {
        guard let videoURL = videoURL else { return }
        
        playerView.stop()
        previewImageView.isHidden = false
        playAndPauseButton.setImage(#imageLiteral(resourceName: "play_button"), for: .normal)
        
        if index == 0 {
            newVideoURL = videoURL
            play()
            return
        }
        
        self.applyFilter { [weak self] url in
            self?.newVideoURL = url
            DispatchQueue.main.async {
                self?.play()
            }
        }
    }
    
    // MARK: - Sound effects
    func setPitch(_ pitch: Float) {
        changePitchEffect.pitch = pitch
    }
    
    func setRate(_ rate: Float) {
        changePitchEffect.rate = rate
    }
    
    func enablePopGesture() {
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    func close() {
        navigationController?.popViewController(animated: true)
    }
    
    func share() {
        playerView.pause()
        
        guard let newVideoURL = newVideoURL else { return }
        
        let content = ["Check my super video!", newVideoURL] as [Any]
        let activityVC = UIActivityViewController(activityItems: content as [Any], applicationActivities: nil)
        //activityVC.excludedActivityTypes = [.airDrop, .message, .mail]
        activityVC.completionWithItemsHandler = { (activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
            self.playerView.play()
        }
        present(activityVC, animated: true)
    }
    
    func applyFilter(completion: @escaping (URL?) -> Void) {
        guard let videoURL = videoURL, let audioURL = audioURL, let videoManager = videoManager else {
            completion(nil)
            return
        }
        
        let videoInput = CopyVideoAssetInput(videoURL: videoManager.videoURL)
        _ = CopyVideoAsset(input: videoInput).actWith(.none).then { url -> Promise<AVTulip> in
            let input = RemoveAudioFileFromVideoInput(videoAsset: url)
            return RemoveAudioFileFromVideo(input: input).actWith(.none)
            //return .value((video: videoInput.videoURL, audio: audioURL))
        }.then { tulpan -> Promise<(video: URL, audio: AVAsset)> in
            let input = ApplyFilterInput(audioURL: tulpan.audio, videoURL: tulpan.video)
            return ApplyFilter(input: input).actWith(.none)
        }.then { tulpan -> Promise<URL> in
            let input = MergeAudioAndVideoInput(videoURL: tulpan.video, audioURL: tulpan.audio)
            return MergeAudioAndVideo(input: input).actWith(.none)
        }.done { videoUrl in
            completion(videoUrl)
        }
    }
    
    func play() {
        previewImageView.isHidden = true
        
        switch playerView.playerStatus  {
        case .unknown, .readyToPlay:
            playerView.play(with: .init(url: newVideoURL))
            playAndPauseButton.setImage(#imageLiteral(resourceName: "pause_button"), for: .normal)
        case .playing:
            playerView.pause()
            playAndPauseButton.setImage(#imageLiteral(resourceName: "play_button"), for: .normal)
        case .paused:
            playerView.play()
            playAndPauseButton.setImage(#imageLiteral(resourceName: "pause_button"), for: .normal)
        default:
            playerView.play(with: .init(url: newVideoURL))
        }
    }

}
