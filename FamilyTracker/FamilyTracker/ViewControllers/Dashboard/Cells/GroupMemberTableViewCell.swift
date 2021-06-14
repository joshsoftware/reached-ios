//
//  GroupMemberTableViewCell.swift
//  FamilyTracker
//
//  Created by Vijay Godse on 13/05/21.
//

import UIKit
import SDWebImage
import CoreLocation

class GroupMemberTableViewCell: UITableViewCell {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var memberNameLbl: UILabel!
    
    @IBOutlet weak var memberProfileImgView: UIImageView!
    @IBOutlet weak var pinImgView: UIImageView!
    @IBOutlet weak var currentLocationContainerView: UIView!
    @IBOutlet weak var currentLocationLbl: UILabel!
    @IBOutlet weak var distanceLbl: UILabel!
    @IBOutlet weak var awayLbl: UILabel!
    
    var onClickMemberHandler: (() -> Void)?
    var onClickMemberProfileHandler: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        distanceLbl.isHidden = true
        awayLbl.isHidden = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        containerView.addGestureRecognizer(tap)
        
        let profileTap = UITapGestureRecognizer(target: self, action: #selector(self.handleProfileTap(_:)))
        memberProfileImgView.addGestureRecognizer(profileTap)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        memberProfileImgView.layer.cornerRadius = memberProfileImgView.frame.width / 2

        currentLocationContainerView.layer.cornerRadius = currentLocationContainerView.frame.height / 2
        containerView.layer.cornerRadius = 5.0
        containerView.layer.borderWidth = 0.4
        containerView.layer.borderColor = UIColor.lightGray.cgColor
    }
    
    func updateCell(member: Members) {
        let memberId = member.id
        let userId = UserDefaults.standard.string(forKey: "userId")
        if memberId == userId {
            memberNameLbl.text = "You"
        } else {
            memberNameLbl.text = member.name
        }
        
        self.memberProfileImgView.sd_setImage(with: URL(string: member.profileUrl ?? ""), placeholderImage: UIImage(named: "userPlaceholder"))
        
        if let lat = member.lat, let long =  member.long {
            let location = CLLocation(latitude: lat, longitude: long)
            location.fetchCityAndCountry { (name, city, error) in
                if error == nil {
                    self.currentLocationLbl.text = (name ?? "") + ", " + (city ?? "")
                }
            }
        }
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        onClickMemberHandler?()
    }
    
    @objc func handleProfileTap(_ sender: UITapGestureRecognizer? = nil) {
        onClickMemberProfileHandler?()
    }
    
}
