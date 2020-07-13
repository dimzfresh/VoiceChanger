//
//  Utils.swift
//  VoiceChanger
//
//  Created by Dmitrii Ziablikov on 13.07.2020.
//  Copyright © 2020 Myna labs. All rights reserved.
//

import UIKit

class Utils {
    static func isVideoPortraitOriented(size: CGSize?, preferredTransform: CGAffineTransform?) -> Bool {
        guard let size = size, let preferredTransform = preferredTransform else {
            return false
        }
        var videoRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        videoRect = videoRect.applying(preferredTransform)

        return videoRect.size.height > videoRect.size.width ? true : false
    }
}
