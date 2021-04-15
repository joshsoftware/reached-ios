//
//  GroupRowController.swift
//  FamilyTracker WatchKit Extension
//
//  Created by Vijay Godse on 08/04/21.
//

import WatchKit
import SDWebImage

class GroupRowController: NSObject {
    @IBOutlet var groupNameLabel: WKInterfaceLabel!
    @IBOutlet var groupImgView: WKInterfaceImage!
    @IBOutlet weak var memberCountLbl: WKInterfaceLabel!
    
    override init() {
    }
    
    var item: Group? {
        didSet {
            guard let item = item else { return }
            groupNameLabel.setText(item.name)
            memberCountLbl.setText(item.members?.count.description ?? "")
//            if let url = URL(string: item.profileUrl ?? "") {
//                SDWebImageDownloader.shared.downloadImage(with: url) { (image, _, _, _) in
//
//                    if let img = image, let roundedImage = ImageTools.imageWithRoundedCornerSize(cornerRadius: 35, usingImage: img) {
//                        self.groupImgView.setImage(roundedImage)
//                    }
//
//                }
//            }
        }
    }
    
}
