//
//  InterfaceController.swift
//  FamilyTracker WatchKit Extension
//
//  Created by Vijay Godse on 02/03/21.
//

import WatchKit
import Foundation
import CoreLocation
import WatchConnectivity
import FirebaseDatabase
import FirebaseCore

class InterfaceController: BaseInterfaceController, NibLoadableViewController {
    @IBOutlet weak var welcomeToLabel: WKInterfaceLabel!
    @IBOutlet weak var logoImg: WKInterfaceImage!
    @IBOutlet weak var bottomGroup: WKInterfaceGroup!
    @IBOutlet weak var loginInfoGroup: WKInterfaceGroup!
    @IBOutlet weak var emailLabel: WKInterfaceLabel!

    var userRefForDeviceToken: DatabaseReference!
    var isDataLoaded = false
    var groupCount: Int = 0

    override func awake(withContext context: Any?) {
        // Configure interface objects here.
        super.awake(withContext: context)
        userRefForDeviceToken = Database.database().reference()
        if UserDefaults.standard.bool(forKey: "loginStatus") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.animation(completion: {
                    self.fetchGroupsCount { (count) in
                        let isLogin = UserDefaults.standard.bool(forKey: "loginStatus")
                        self.handleNavigation(isLogin: isLogin, groupCount: count!)
                    }
                })
            }
        }
    }
    
    func animation(completion: @escaping () -> Void) {
        self.welcomeToLabel.setHidden(true)
        self.logoImg.setHidden(true)
        self.animate(withDuration: 0.5) {
            self.bottomGroup.setRelativeHeight(0.8, withAdjustment: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.loginInfoGroup.setHidden(false)
            if let userEmailId = UserDefaults.standard.string(forKey: "userEmailId") {
                self.emailLabel.setText(userEmailId)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                completion()
            }
        }
    }
    
    func reset() {
        self.welcomeToLabel.setHidden(false)
        self.logoImg.setHidden(false)
        self.bottomGroup.setHeight(40.0)
        self.loginInfoGroup.setHidden(true)
    }
}
