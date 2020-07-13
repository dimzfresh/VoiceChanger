//
//  PermisionViewController.swift
//  VoiceChanger
//
//  Created by Dmitrii Ziablikov on 13.07.2020.
//  Copyright © 2020 Myna labs. All rights reserved.
//

import UIKit

protocol PermisionDelegate {
    func update()
}

class PermisionViewController: UIViewController {
    
    @IBOutlet private weak var cameraPermissionButton: UIButton!
    @IBOutlet private weak var photosPermissionButton: UIButton!
    @IBOutlet private weak var audioPermissionButton: UIButton!
    
    @IBOutlet private weak var cameraPermissionFlagImageView: UIImageView!
    @IBOutlet private weak var photosPermissionFlagImageView: UIImageView!
    @IBOutlet private weak var audioPermissionFlagImageView: UIImageView!
    
    private lazy var blurEffectView: UIVisualEffectView = {
         let blurEffect = UIBlurEffect(style: .light)
         let blurEffectView = UIVisualEffectView(effect: blurEffect)
         return blurEffectView
     }()
    
    private let permissions = Permissions()
    
    var permisionDelegate: PermisionDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    @IBAction private func cameraPermissionButtonTapped(_ sender: Any) {
        permissions.request(for: .camera) { _ in
            self.setupControls()
        }
    }
    
    @IBAction private func photosPermissionButtonTapped(_ sender: Any) {
        permissions.request(for: .photos) { _ in
            self.setupControls()
        }
    }
    
    @IBAction private func audioPermissionButtonTapped(_ sender: Any) {
        permissions.request(for: .audio) { _ in
            self.setupControls()
        }
    }
    
    @IBAction private func closeButtonTapped(_ sender: Any) {
        close()
    }

}

private extension PermisionViewController {
    func setup() {
        setupBlurEffectView()
        setupControls()
    }
    
    func setupBlurEffectView() {
        view.backgroundColor = #colorLiteral(red: 0.1960784314, green: 0.262745098, blue: 0.4196078431, alpha: 1).withAlphaComponent(0.4)
        blurEffectView.alpha = 0.45
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurEffectView)
        view.sendSubviewToBack(blurEffectView)
    }
    
    func setupControls() {
        var ok: Bool = true
        let cameraStatus = permissions[.camera]
        let photosStatus = permissions[.photos]
        let audioStatus = permissions[.audio]

        if cameraStatus == .granted {
            cameraPermissionButton.isEnabled = false
            cameraPermissionButton.alpha = 0.8
            cameraPermissionFlagImageView.alpha = 0.9
        } else {
            ok = false
        }
        
        if photosStatus == .granted {
            photosPermissionButton.isEnabled = false
            photosPermissionButton.alpha = 0.8
            photosPermissionFlagImageView.alpha = 0.9
        } else {
            ok = false
        }
        
        if audioStatus == .granted {
            audioPermissionButton.isEnabled = false
            audioPermissionButton.alpha = 0.8
            audioPermissionFlagImageView.alpha = 0.9
        } else {
            ok = false
        }
        
        if ok {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.close()
            }
        }
    }
    
    func close() {
        permisionDelegate?.update()
        dismiss(animated: true)
    }
}
