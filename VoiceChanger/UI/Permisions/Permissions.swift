//
//  Permissions.swift
//  VoiceChanger
//
//  Created by Dmitrii Ziablikov on 13.07.2020.
//  Copyright © 2020 Myna labs. All rights reserved.
//

import AVFoundation
import Photos

enum PermissionType {
    case camera
    case photos
    case audio
}

enum PermissionStatus {
    case unknown
    case denied
    case granted
}

final class Permissions {
            
    // MARK: - Getters
    subscript(type: PermissionType) -> PermissionStatus {
        get {
             status(for: type)
        }
    }
    
    // MARK: - Requests
    func request(for type: PermissionType, completion: @escaping (PermissionStatus) -> Void) {
        func callback(_ granted: Bool) {
            DispatchQueue.main.async {
                completion(granted ? .granted : .denied)
            }
        }
        
        switch type {
        case .camera:
            requestCameraAccess(callback)
        case .photos:
            requestPhotosAccess(callback)
        case .audio:
            requestAudioAccess(callback)
        }
    }
    
}

private extension Permissions {
    
    var cameraStatus: PermissionStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return .granted
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .unknown
        @unknown default:
            return .unknown
        }
    }
    
    var photosStatus: PermissionStatus {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            return .granted
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .unknown
        @unknown default:
            return .unknown
        }
    }
    
    var audioStatus: PermissionStatus {
        let status = AVAudioSession.sharedInstance().recordPermission
        switch status {
        case .granted:
            return .granted
        case .denied:
            return .denied
        case .undetermined:
            return .unknown
        @unknown default:
            return .unknown
        }
    }
    
    func status(for type: PermissionType) -> PermissionStatus {
        let status: PermissionStatus
        
        switch type {
        case .camera:
            status = cameraStatus
        case .photos:
            status = photosStatus
        case .audio:
            status = audioStatus
        }
        
        return status
    }
    
    func requestCameraAccess(_ completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: completion)
    }
    
    func requestPhotosAccess(_ completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization {
            completion($0 == .authorized)
        }
    }
    
    func requestAudioAccess(_ completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission(completion)
    }
    
}

