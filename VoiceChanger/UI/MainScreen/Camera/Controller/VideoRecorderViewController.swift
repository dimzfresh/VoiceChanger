//
//  VideoRecorderViewController.swift
//  VoiceChanger
//
//  Created by Dmitrii Ziablikov on 13.07.2020.
//  Copyright © 2020 Myna labs. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices

class VideoRecorderViewController: UIViewController {
    
    @IBOutlet private weak var recordButton: UIButton!
    @IBOutlet private weak var progressView: UIView!
    @IBOutlet private weak var photoLibraryButton: UIButton!
    
    private var curreentProgressView: ProgressView?
    private var pulseLayers = [CAShapeLayer]()
    
    private var captureSession = AVCaptureSession()
    private var previewLayer = AVCaptureVideoPreviewLayer()
    private var movieOutput = AVCaptureMovieFileOutput()
    private var videoCaptureDevice : AVCaptureDevice?
    private var audioFilePath: URL?
    
    private let permissions = Permissions()
    private var firstOpen: Bool = true
    
    private var imagePickerController = UIImagePickerController()
    private var videoURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkPermissions()
        setup()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layout()
    }
    
    @IBAction private func recordButtonTapped(_ sender: UIButton) {
        updateRecording()
    }
    
    @IBAction private func photoLibraryButtonTapped(_ sender: Any) {
        imagePickerController.sourceType = .savedPhotosAlbum
        imagePickerController.delegate = self
        imagePickerController.mediaTypes = ["public.movie"]
        present(imagePickerController, animated: true, completion: nil)
    }
}

extension VideoRecorderViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        videoURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL
        print("videoURL:\(String(describing: videoURL))")
        dismiss(animated: true) {
            if self.videoURL != nil {
                self.showResultView()
            }
        }
    }
}

extension VideoRecorderViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if error == nil {
            videoURL = outputFileURL
            showResultView()
            //UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, nil, nil, nil)
        }
    }
}

extension VideoRecorderViewController: PermisionDelegate {
    func update() {
        checkPermissions()
        setup()
    }
}

private extension VideoRecorderViewController {
    func setup() {
        setupViews()
        setupCamera()
    }
    
    func setupViews() {
        view.bringSubviewToFront(recordButton)
        setupProgressView()
    }
    
    func setupProgressView(start: Bool = false) {
        curreentProgressView?.removeFromSuperview()
        
        let progress = ProgressView()
        progress.activateAnchors()
        progressView.addSubview(progress)
        
        progress
            .topAnchor(to: progressView.topAnchor)
            .bottomAnchor(to: progressView.bottomAnchor)
            .leadingAnchor(to: progressView.leadingAnchor)
            .trailingAnchor(to: progressView.trailingAnchor)
        progressView.layoutIfNeeded()
        
        curreentProgressView = progress
        curreentProgressView?.duration = 15
        curreentProgressView?.backColor = UIColor.white.withAlphaComponent(0.05)
        curreentProgressView?.lineColor = UIColor.white.withAlphaComponent(0.55)
        curreentProgressView?.reset()
        curreentProgressView?.onCompletion = { [weak self] in
            self?.stopRecordAnimation()
            self?.updateRecording()
        }
        if start {
            curreentProgressView?.start()
        }
    }
    
    func updateRecording() {
        if movieOutput.isRecording {
            photoLibraryButton.isEnabled = true
            movieOutput.stopRecording()
            
            curreentProgressView?.fill()
            stopRecordAnimation()
            
        } else {
            setupProgressView(start: true)
            startRecordAnimation()
            photoLibraryButton.isEnabled = false

            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            guard let fileUrl = paths.first?.appendingPathComponent("output.mov") else { return }
            try? FileManager.default.removeItem(at: fileUrl)
            movieOutput.startRecording(to: fileUrl, recordingDelegate: self)
        }
    }
    
    func setupCamera() {
        let cameraStatus = permissions[.camera]
        let photosStatus = permissions[.photos]
        let audioStatus = permissions[.audio]
        guard cameraStatus == .granted, photosStatus == .granted, audioStatus == .granted else {
            return
        }
        
        guard videoCaptureDevice == nil else { return }
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let audioInput = AVCaptureDevice.default(for: .audio)
            else { return }
        
        videoCaptureDevice = device
        
        do {
            try captureSession.addInput(AVCaptureDeviceInput(device: device))
            try captureSession.addInput(AVCaptureDeviceInput(device: audioInput))
        } catch(let error) {
            print(error)
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoOrientation = .portrait
        
        view.layer.addSublayer(previewLayer)
        
        view.bringSubviewToFront(recordButton)
        view.bringSubviewToFront(progressView)
        view.bringSubviewToFront(photoLibraryButton)
        
        captureSession.addOutput(movieOutput)
        captureSession.startRunning()
    }
    
    func checkPermissions() {
        guard firstOpen else { return }
        firstOpen = false
        
        let cameraStatus = permissions[.camera]
        let photosStatus = permissions[.photos]
        let audioStatus = permissions[.audio]
        
        if cameraStatus == .unknown || photosStatus == .unknown || audioStatus == .unknown {
            showPermissionsView()
        }
    }
    
    func layout() {
        recordButton.layer.cornerRadius = 40
        
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.bounds = view.layer.bounds
        previewLayer.position = CGPoint(x: view.layer.bounds.midX, y: view.layer.bounds.midY)
        
    }
    
    // MARK: - Record button animation
    
    func startRecordAnimation() {
        recordButton.layer.removeAllAnimations()
        pulseLayers.forEach { $0.removeFromSuperlayer() }
        pulseLayers.removeAll()
        
        recordButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        createPulse()
        
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 5,
                       options: [.autoreverse, .curveLinear,
                                 .repeat, .allowUserInteraction],
                       animations: {
                        self.recordButton.transform = .identity
        })
    }
    
    func stopRecordAnimation() {
        recordButton.layer.removeAllAnimations()
        pulseLayers.forEach { $0.removeFromSuperlayer() }
        pulseLayers.removeAll()
    }
    
    func createPulse() {
        for _ in 0...2 {
            let circularPath = UIBezierPath(arcCenter: .zero, radius: 80, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
            let pulseLayer = CAShapeLayer()
            pulseLayer.path = circularPath.cgPath
            pulseLayer.lineWidth = 3.0
            pulseLayer.fillColor = UIColor.clear.cgColor
            pulseLayer.lineCap = .round
            pulseLayer.position = recordButton.center
            view.layer.insertSublayer(pulseLayer, above: previewLayer)
            pulseLayers.append(pulseLayer)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.animatePulse(index: 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.animatePulse(index: 1)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.animatePulse(index: 2)
                }
            }
        }
    }
    
    func animatePulse(index: Int) {
        guard !pulseLayers.isEmpty else { return }
        pulseLayers[index].strokeColor = #colorLiteral(red: 0.431372549, green: 0.5019607843, blue: 0.7058823529, alpha: 1).cgColor
        pulseLayers[index].fillColor = #colorLiteral(red: 0.431372549, green: 0.5019607843, blue: 0.7058823529, alpha: 1).cgColor

        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.duration = 2.3
        scaleAnimation.fromValue = 0.0
        scaleAnimation.toValue = 0.9
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        scaleAnimation.repeatCount = .greatestFiniteMagnitude
        pulseLayers[index].add(scaleAnimation, forKey: "scale")
        
        let opacityAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        opacityAnimation.duration = 2.3
        opacityAnimation.fromValue = 0.9
        opacityAnimation.toValue = 0.05
        opacityAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        opacityAnimation.repeatCount = .greatestFiniteMagnitude
        pulseLayers[index].add(opacityAnimation, forKey: "opacity")
    }
    
    // MARK: - Navigation
    
    func showPermissionsView() {
        let vc = PermisionViewController.initFromNib()
        vc.modalPresentationStyle = .overFullScreen
        vc.permisionDelegate = self
        present(vc, animated: true)
    }
    
    func showResultView() {
        let vc = ResultViewController.initFromNib()
        vc.attach(videoURL: videoURL)
        navigationController?.pushViewController(vc, animated: true)
    }
}


