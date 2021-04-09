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
    
    override init() {
    }
    
    var item: Members? {
        didSet {
            guard let item = item else { return }
            nameLabel.setText(item.name)
            if let url = URL(string: item.profileUrl ?? "") {
                SDWebImageDownloader.shared.downloadImage(with: url) { (image, _, _, _) in
                    
                    if let img = image, let roundedImage = ImageTools.imageWithRoundedCornerSize(cornerRadius: 35, usingImage: img) {
                        self.userImgView.setImage(roundedImage)
                    }
 
                }
            }
        }
    }
    
}
