//
//  FilterViewManager.swift
//  VoiceChanger
//
//  Created by Dmitrii Ziablikov on 13.07.2020.
//  Copyright © 2020 Myna labs. All rights reserved.
//

import UIKit

final class FilterViewManager: NSObject {
    
    var onSelectFilterItem: ((Int) -> Void)?
    
    private weak var collectionView: UICollectionView?
    
    var filters: [FilterItem] = [] {
        didSet {
            collectionView?.reloadData()
        }
    }
    
    private let spacing: CGFloat = 16
    
    private var snappingDelegate: SnappingCollectionViewDelegateFlowLayout?
    
    private var orientation: UIDeviceOrientation { UIDevice.current.orientation }
    
    init(collectionView: UICollectionView) {
        super.init()
        self.collectionView = collectionView
        setup()
    }
    
    private lazy var cellSize: CGSize = {
        let height = 80
        let width = 80
        return CGSize(width: width, height: height)
    }()
}

extension FilterViewManager: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filters.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeue(FilterCollectionViewCell.self, indexPath: indexPath) else {
            return UICollectionViewCell()
        }
        
        cell.configure(item: filters[indexPath.row])
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return cellSize
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onSelectFilterItem?(indexPath.row)
        
        filters = filters.map({ var new = $0; new.isSelected = false; return new })
        filters[indexPath.row].isSelected = !filters[indexPath.row].isSelected
        collectionView.reloadData()
    }
}


private extension FilterViewManager {
    func setup() {
        setupSnappingDelegate()
        setupCollectionView()
    }
    
    func setupSnappingDelegate() {
        snappingDelegate = SnappingCollectionViewDelegateFlowLayout(spacing: spacing)
        snappingDelegate?.collectionView = collectionView
        snappingDelegate?.delegate = self
    }
    
    func setupCollectionView() {
        collectionView?.allowsSelection = true
        collectionView?.decelerationRate = .fast
        collectionView?.dataSource = self
        collectionView?.isPagingEnabled = false
        collectionView?.register(FilterCollectionViewCell.nib, forCellWithReuseIdentifier: FilterCollectionViewCell.identifier)
    }
}
