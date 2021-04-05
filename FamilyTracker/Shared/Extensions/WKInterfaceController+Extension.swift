//
//  WKInterfaceController+Extension.swift
//  FamilyTracker WatchKit Extension
//
//  Created by Vijay Godse on 03/03/21.
//

import WatchKit
protocol NibLoadableViewController {
    static var name: String { get }
}

extension NibLoadableViewController where Self: WKInterfaceController {
    static var name: String {
        return String(describing: self)
    }
}
