//
//  UIView+Extension.swift
//  FamilyTracker
//
//  Created by Vijay Godse on 07/04/21.
//

import UIKit

extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if parentResponder is UIViewController {
                return parentResponder as? UIViewController
            }
        }
        return nil
    }
    
    func setShadowToAllSides(color: UIColor = .lightGray) {
        layer.masksToBounds = false
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize.zero
        layer.shadowRadius = 5
    }
}
