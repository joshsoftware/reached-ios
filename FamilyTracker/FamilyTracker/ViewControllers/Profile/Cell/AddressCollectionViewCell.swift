//
//  AddressCollectionViewCell.swift
//  FamilyTracker
//
//  Created by Mahesh on 01/06/21.
//

import UIKit

class AddressCollectionViewCell: UICollectionViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = 12.0
        setShadowToAllSides()
    }

}
