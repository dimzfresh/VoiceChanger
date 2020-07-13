//
//  Storyboards.swift
//  VoiceChanger
//
//  Created by Dmitrii Ziablikov on 13.07.2020.
//  Copyright © 2020 Myna labs. All rights reserved.
//

import UIKit

public enum Storyboards: String {
    case main = "Main"

    var instance: UIStoryboard {
        return UIStoryboard(name: self.rawValue, bundle: nil)
    }

}
