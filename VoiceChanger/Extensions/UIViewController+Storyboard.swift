//
//  UIViewController+Storyboard.swift
//  VoiceChanger
//
//  Created by Dmitrii Ziablikov on 13.07.2020.
//  Copyright © 2020 Myna labs. All rights reserved.
//

import UIKit

extension NSObject {
    static var nameOfClass: String {
        return NSStringFromClass(self).components(separatedBy: ".").last ?? ""
    }
}

extension UIViewController {
    class func instanceController<T: UIViewController>(storyboard: Storyboards) -> T {
        guard let viewController = storyboard.instance.instantiateViewController(withIdentifier: nameOfClass) as? T else {
            return T()
        }
        return viewController
    }
}

extension UIViewController {
    static func initFromNib() -> Self {
        func instanceFromNib<T: UIViewController>() -> T {
            return T(nibName: String(describing: self), bundle: nil)
        }
        return instanceFromNib()
    }
}
