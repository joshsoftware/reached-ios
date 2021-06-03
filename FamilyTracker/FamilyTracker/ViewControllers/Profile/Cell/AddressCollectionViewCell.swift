//
//  AddressCollectionViewCell.swift
//  FamilyTracker
//
//  Created by Mahesh on 01/06/21.
//

import UIKit

class AddressCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var radiusLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        // Initialization code
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = 12.0
        setShadowToAllSides()
    }
    
    func setupCell(place: Place) {
        nameLabel.text = place.name
        addressLabel.text = place.address
        radiusLabel.text = "\(String(describing: place.radius ?? 3)) Km"
    }

}
