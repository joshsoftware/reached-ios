//
//  Utility.swift
//  FamilyTracker
//
//  Created by Vijay Godse on 23/04/21.
//

import UIKit

class Utility {
    
    class func logoutUser() {
        UserDefaults.standard.setValue(false, forKey: "loginStatus")
        UserDefaults.standard.setValue("", forKey: "userId")
        UserDefaults.standard.setValue("", forKey: "userName")
        UserDefaults.standard.setValue(nil, forKey: "groups")
        UserDefaults.standard.setValue("", forKey: "userProfileUrl")
    }
    
}
