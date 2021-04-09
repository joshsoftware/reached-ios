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

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        containerView.layer.cornerRadius = 15.0
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        userProfileImgView.layer.cornerRadius = userProfileImgView.frame.width / 2
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
