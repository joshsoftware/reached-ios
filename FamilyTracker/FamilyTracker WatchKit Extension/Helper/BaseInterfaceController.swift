//
//  BaseInterfaceController.swift
//  FamilyTracker WatchKit Extension
//
//  Created by Mahesh on 22/06/21.
//

import UIKit
import WatchKit
import FirebaseDatabase

class BaseInterfaceController: WKInterfaceController {
    var connectivityHandler = WatchSessionManager.shared
    private var userRefForDeviceToken: DatabaseReference!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)

        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        connectivityHandler.startSession()
        connectivityHandler.watchOSDelegate = self
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func fetchGroupsCount(completion: @escaping (_ count: Int?) -> Void) {
        if let userId = UserDefaults.standard.string(forKey: "userId"), !userId.isEmpty {
            DatabaseManager.shared.fetchGroupsFor(userWith: userId) { (data) in
                if let groups = data {
                    if groups.count > 0 {
                        return completion(groups.count)
                    } else {
                        return completion(0)
                    }
                } else {
                    return completion(0)
                }
            }
        } else {
            return completion(0)
        }
    }
    
    func handleNavigation(isLogin: Bool, groupCount: Int) {
        let topVC = WKExtension.shared().visibleInterfaceController
        if isLogin && groupCount > 0 {
            if (topVC?.isKind(of: InterfaceController.self))! {
                if let vc = topVC as? InterfaceController {
                    vc.animation(completion: {
                        if !(topVC?.isKind(of: GroupsInterfaceController.self))! {
                            topVC?.pushController(withName: GroupsInterfaceController.name, context: nil)
                        }
                    })
                }
            } else {
                if !(topVC?.isKind(of: GroupsInterfaceController.self))! {
                    topVC?.pushController(withName: GroupsInterfaceController.name, context: nil)
                }
            }
        } else if isLogin && groupCount <= 0 {
            if (topVC?.isKind(of: InterfaceController.self))! {
                if let vc = topVC as? InterfaceController {
                    vc.animation(completion: {
                        if !(topVC?.isKind(of: HomeInterfaceController.self))! {
                            topVC?.pushController(withName: HomeInterfaceController.name, context: nil)
                        }
                    })
                }
            } else {
                if !(topVC?.isKind(of: HomeInterfaceController.self))! {
                    topVC?.pushController(withName: HomeInterfaceController.name, context: nil)
                }
            }
        } else {
            if !(topVC?.isKind(of: InterfaceController.self))! {
                let rootVC = WKExtension.shared().rootInterfaceController
                if let vc = rootVC as? InterfaceController {
                    vc.reset()
                }
                topVC?.popToRootController()
            }
        }
    }
    
    func updateDeviceTokenOnFirebase() {
        userRefForDeviceToken = Database.database().reference()
        if let userId = UserDefaults.standard.string(forKey: "userId"), !userId.isEmpty && UserDefaults.standard.bool(forKey: "loginStatus") == true {
            UserDefaults.standard.setValue(userId, forKey: "userIdBeforeLogout")
            if let token = UserDefaults.standard.object(forKey: "watchDeviceToken") as? String {
                self.userRefForDeviceToken.child("users").child(userId).child("token").child("watch").setValue(token)
            }
        } else {
            if let userId = UserDefaults.standard.object(forKey: "userIdBeforeLogout") as? String,!userId.isEmpty {
                self.userRefForDeviceToken.child("users").child(userId).child("token").child("watch").removeValue()
                UserDefaults.standard.setValue(nil, forKey: "userIdBeforeLogout")
            }
        }
    }
    
    func logoutUser() {
        UserDefaults.standard.setValue(false, forKey: "loginStatus")
        UserDefaults.standard.setValue("", forKey: "userId")
        UserDefaults.standard.setValue("", forKey: "userEmailId")
    }
}

extension BaseInterfaceController: WatchOSDelegate {
    
    func applicationContextReceived(tuple: ApplicationContextReceived) {
        
    }
    
    
    func messageReceived(tuple: MessageReceived) {
        DispatchQueue.main.async() {
            WKInterfaceDevice.current().play(.notification)
            if let loginStatus = tuple.message["loginStatus"] as? Bool, let userId = tuple.message["userId"] as? String, let userEmailId = tuple.message["userEmailId"] as? String {
                UserDefaults.standard.setValue(loginStatus, forKey: "loginStatus")
                UserDefaults.standard.setValue(userId, forKey: "userId")
                UserDefaults.standard.setValue(userEmailId, forKey: "userEmailId")
                if loginStatus {
                    self.fetchGroupsCount { (count) in
                        self.handleNavigation(isLogin: loginStatus, groupCount: count!)
                    }
                } else {
                    self.handleNavigation(isLogin: loginStatus, groupCount: 0)
                }
            }
        }
    }
    
}
