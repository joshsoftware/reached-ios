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

class ImageTools {
    class func imageWithRoundedCornerSize(cornerRadius:CGFloat, usingImage original: UIImage) -> UIImage? {
        let frame = CGRect(x: 0, y: 0, width: original.size.width, height: original.size.height)

        // Begin a new image that will be the new image with the rounded corners
        UIGraphicsBeginImageContextWithOptions(original.size, false, 1.0)

        // Add a clip before drawing anything, in the shape of an rounded rect
        UIBezierPath(roundedRect: frame, cornerRadius: cornerRadius).addClip()

        // Draw the new image
        original.draw(in: frame)

        // Get the new image
        guard let roundedImage = UIGraphicsGetImageFromCurrentImageContext() else { return nil }

        // Lets forget about that we were drawing
        UIGraphicsEndImageContext()

        return roundedImage
    }
}
