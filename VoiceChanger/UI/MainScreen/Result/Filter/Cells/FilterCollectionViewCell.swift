//
//  FilterCollectionViewCell.swift
//  VoiceChanger
//
//  Created by Dmitrii Ziablikov on 13.07.2020.
//  Copyright © 2020 Myna labs. All rights reserved.
//

import UIKit

class FilterCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet private weak var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    func configure(item: FilterItem) {
        nameLabel.text = item.name
        decorate(selected: item.isSelected)
    }
}

private extension FilterCollectionViewCell {
    func setup() {
        layer.cornerRadius = 20
    }
    
    func decorate(selected: Bool = false) {
        if selected {
            nameLabel.textColor = .white
            nameLabel.font = .systemFont(ofSize: 13, weight: .medium)
            backgroundColor = #colorLiteral(red: 0.431372549, green: 0.5019607843, blue: 0.7058823529, alpha: 1).withAlphaComponent(0.9)
            layer.borderWidth = 1.5
            layer.borderColor = UIColor.white.cgColor
        } else {
            nameLabel.textColor = #colorLiteral(red: 0.431372549, green: 0.5019607843, blue: 0.7058823529, alpha: 1)
            nameLabel.font = .systemFont(ofSize: 13, weight: .regular)
            backgroundColor = .white
            layer.borderWidth = 1.5
            layer.borderColor = #colorLiteral(red: 0.431372549, green: 0.5019607843, blue: 0.7058823529, alpha: 1).cgColor
        }
    }
    
}
