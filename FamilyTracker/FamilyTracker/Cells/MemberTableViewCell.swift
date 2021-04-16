//
//  MemberTableViewCell.swift
//  FamilyTracker
//
//  Created by Vijay Godse on 03/03/21.
//

import UIKit

class MemberTableViewCell: UITableViewCell {

    @IBOutlet weak var userProfileImgView: UIImageView!
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var lastUpdatedLbl: UILabel!
    @IBOutlet weak var currentLocationLbl: UILabel!
    
    @IBOutlet weak var pinIcon: UIImageView!
    @IBOutlet weak var lastUpdatedIcon: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        containerView.layer.cornerRadius = 15.0
        userProfileImgView.backgroundColor = .black
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        userProfileImgView.layer.cornerRadius = userProfileImgView.frame.width / 2
        pinIcon.image = UIImage(named: "pin")?.withRenderingMode(.alwaysTemplate)
        lastUpdatedIcon.image = UIImage(named: "lastUpdateIcon")?.withRenderingMode(.alwaysTemplate)
        pinIcon.tintColor = .red
        lastUpdatedIcon.tintColor = .darkGray
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
