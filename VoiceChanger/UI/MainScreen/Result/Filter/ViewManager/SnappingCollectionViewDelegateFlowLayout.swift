//
//  SnappingCollectionViewDelegateFlowLayout.swift
//  VoiceChanger
//
//  Created by Dmitrii Ziablikov on 13.07.2020.
//  Copyright © 2020 Myna labs. All rights reserved.
//

import UIKit

final class SnappingCollectionViewDelegateFlowLayout: NSObject {
    
    private let spacing: CGFloat
    
    init(spacing: CGFloat) {
        self.spacing = spacing
    }
    
    weak var collectionView: UICollectionView? {
        willSet {
            collectionView?.delegate = nil
        }
        didSet {
            collectionView?.delegate = self
        }
    }
    
    weak var delegate: UICollectionViewDelegateFlowLayout?
    
}

extension SnappingCollectionViewDelegateFlowLayout: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.collectionView?(collectionView, didSelectItemAt: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return delegate?.collectionView?(collectionView, layout: collectionViewLayout, insetForSectionAt: section) ??
            UIEdgeInsets(top: 0.0, left: spacing, bottom: 0.0, right: spacing)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return spacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return delegate?.collectionView?(collectionView, layout: collectionViewLayout, sizeForItemAt: indexPath) ?? .zero
    }
    
}
