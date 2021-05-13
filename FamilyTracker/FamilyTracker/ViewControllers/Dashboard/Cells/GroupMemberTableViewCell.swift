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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        distanceLbl.isHidden = true
        awayLbl.isHidden = true
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
            memberNameLbl.text = "Me"
        } else {
            memberNameLbl.text = member.name
        }
        
        if let url = URL(string: member.profileUrl ?? "") {
            SDWebImageDownloader.shared.downloadImage(with: url) { (image, _, _, _) in
                self.memberProfileImgView.image = image
            }
        }
        
        if let lat = member.lat, let long =  member.long {
            let location = CLLocation(latitude: lat, longitude: long)
            location.fetchCityAndCountry { (name, city, error) in
                if error == nil {
                    self.currentLocationLbl.text = (name ?? "") + ", " + (city ?? "")
                }
            }
        }
    }
    
}
