//
//  CustomAnnotationView.swift
//  FamilyTracker
//
//  Created by Mahesh on 04/06/21.
//

import UIKit
import MapKit

class CustomAnnotationView: MKAnnotationView {
    var imageView: UIImageView!
    var profileImageView: UIImageView!

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)

        self.frame = CGRect(x: 0, y: 0, width: 40, height: 60)
        self.imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 60))
        self.imageView.image = UIImage(named: "annotation_bg")
        self.addSubview(self.imageView)
        
        self.profileImageView = UIImageView(frame: CGRect(x: 5, y: 5, width: 30, height: 30))
        self.addSubview(self.profileImageView)
        self.profileImageView.layer.cornerRadius = 15.0
        self.profileImageView.layer.masksToBounds = true
    }

    override var image: UIImage? {
        get {
            return self.profileImageView.image
        }
        set {
            self.profileImageView.image = newValue
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
