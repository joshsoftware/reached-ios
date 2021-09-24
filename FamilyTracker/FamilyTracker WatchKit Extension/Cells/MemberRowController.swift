//
//  MemberRowController.swift
//  FamilyTracker WatchKit Extension
//
//  Created by Vijay Godse on 03/03/21.
//

import WatchKit
import SDWebImage

class MemberRowController: NSObject {
    @IBOutlet var nameLabel: WKInterfaceLabel!
    @IBOutlet var userImgView: WKInterfaceImage!
    @IBOutlet var addressLabel: WKInterfaceLabel!
    @IBOutlet var containerGroup: WKInterfaceGroup!
    @IBOutlet var unsafeImgView: WKInterfaceImage!

    override init() {
    }
    
    var item: Members? {
        didSet {
            guard let item = item else { return }
            nameLabel.setText(item.name)
//            lastUpdatedLocationLabel.setText(DateUtils.formatLastUpdated(dateString: item.lastUpdated ?? ""))
            
            if let sosState = item.sosState, sosState {
                unsafeImgView.setHidden(false)
            } else {
                unsafeImgView.setHidden(true)
            }
            
            if let url = URL(string: item.profileUrl ?? "") {
                SDWebImageDownloader.shared.downloadImage(with: url) { (image, _, _, _) in
                    
                    if let img = image, let roundedImage = ImageTools.imageWithRoundedCornerSize(cornerRadius: 35, usingImage: img) {
                        self.userImgView.setImage(roundedImage)
                    }
 
                }
            }
            
            let location = CLLocation(latitude: item.lat ?? 0, longitude: item.long ?? 0)
            location.fetchCityAndCountry { (name, city, error) in
                if error == nil {
                        self.addressLabel.setText((name ?? "") + ", " + (city ?? ""))
                }
            }
        }
    }
    
}
