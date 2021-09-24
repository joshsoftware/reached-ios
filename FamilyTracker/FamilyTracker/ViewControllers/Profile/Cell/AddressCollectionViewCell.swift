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

    var onClickRemoveAddressHandler: (() -> Void)?

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
        let distanceInKilometer = (place.radius ?? 200) / 1000
        radiusLabel.text = "\(String(describing: distanceInKilometer)) Km"
    }
    
    @IBAction func crossBtnAction(_ sender: Any) {
        onClickRemoveAddressHandler?()
    }

}
