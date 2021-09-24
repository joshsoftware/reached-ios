//
//  GroupsInterfaceController.swift
//  FamilyTracker WatchKit Extension
//
//  Created by Mahesh on 21/06/21.
//

import WatchKit
import Foundation
import CoreLocation
import WatchConnectivity
import FirebaseDatabase
import FirebaseCore

class GroupsInterfaceController: BaseInterfaceController, NibLoadableViewController {
    
    @IBOutlet weak var tableView: WKInterfaceTable!
    @IBOutlet weak var refreshBtn: WKInterfaceButton!
    @IBOutlet weak var swiper: WKSwipeGestureRecognizer!
    @IBOutlet weak var logoutGroup: WKInterfaceGroup!

    private var userRef: DatabaseReference!

    var groups : NSDictionary = NSDictionary()
    var isAlertDismissed = false
    var isDataLoaded = false

    private var groupList = [Group]() {
        didSet {
            if groupList.count > 0 {
                tableView.setNumberOfRows(groupList.count, withRowType: "GroupRowController")
                for index in 0..<tableView.numberOfRows{
                    guard let controller = tableView.rowController(at: index) as? GroupRowController else { continue }
                    controller.item = groupList[index]
                }
            }
            tableView.scrollToRow(at: 2)
        }
    }
    
    override func awake(withContext context: Any?) {
        // Configure interface objects here.
        super.awake(withContext: context)
        self.updateDeviceTokenOnFirebase()
        isDataLoaded = false
        fetchGroups()
        observeFirebaseRealtimeDBChanges()
        
        NotificationCenter.default.addObserver(self, selector: #selector(fetchGroups), name: NSNotification.Name(rawValue: "fetchGroupsNotification"), object: nil)
    }
    
    private func showSignInRequiredAlert() {
//        let titleOfAlert = "Sign In required"
//        let messageOfAlert = "Sign In from your connected phone"
        let titleOfAlert = "Sign In from phone"
        let messageOfAlert = "Request Sign In from your connected phone"
        DispatchQueue.main.async {
            self.presentAlert(withTitle: titleOfAlert, message: messageOfAlert, preferredStyle: .alert, actions: [WKAlertAction(title: "OK", style: .default){
                //something after clicking OK
                self.refreshBtn.setHidden(false)
                self.requestLoginFromPhone()
            }])
        }
    }
    
    private func observeFirebaseRealtimeDBChanges() {
        guard let userId = UserDefaults.standard.value(forKey: "userId") as? String, !userId.isEmpty else {
            return
        }
        userRef = Database.database().reference(withPath: "users/\(userId)")

        //Observe new value added for user
        self.userRef.observe(.childAdded) { (snapshot) in
            self.fetchGroups()
        }

        //Observe new value removed for user
        self.userRef.observe(.childRemoved) { (snapshot) in
            self.fetchGroups()
        }
        
        //Observe new group added
        self.userRef.child("/groups").observe(.childAdded) { (snapshot) in
            self.fetchGroups()
        }

        //Observe group removed
        self.userRef.child("/groups").observe(.childRemoved) { (snapshot) in
            self.fetchGroups()
        }
    }

    @objc func fetchGroups() {
        self.groupList.removeAll()
        if let userId = UserDefaults.standard.string(forKey: "userId"), !userId.isEmpty {
            DatabaseManager.shared.fetchGroupsFor(userWith: userId) { (groups) in
                if let groups = groups {
                    DatabaseManager.shared.fetchGroupData(groups: groups) { (data) in
                        if let data = data {
                            self.isDataLoaded = true
                            let filtered = self.groupList.filter { ($0.id ?? "").contains(data.id ?? "") }

                            if filtered.count <= 0 {
                                self.groupList.append(data)
                            }
                            
                        }
                    }
                }
            }
        }
    }
    
    
    @IBAction func logoutBtnAction() {
        let rootVC = WKExtension.shared().rootInterfaceController
        if let vc = rootVC as? InterfaceController {
            vc.reset()
        }
        self.logoutUser()
        self.updateDeviceTokenOnFirebase()
        self.popToRootController()
    }
    
    @IBAction func refreshBtnAction() {
//        setUp()
    }
    
    private func requestLoginFromPhone() {
        self.connectivityHandler.sendMessage(message: ["requestlogin" : true as AnyObject], errorHandler:  { (error) in
            print("Error sending message: \(error)")
        })
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {

        let isIndexValid = self.groupList.indices.contains(rowIndex)
        
        if isIndexValid {
            let group = self.groupList[rowIndex]
            self.pushController(withName: MemberListInterfaceController.name, context: group)
        }
    }
    
    @IBAction func swipe(_ sender: Any) {
        switch swiper.direction {
        case WKSwipeGestureRecognizerDirection.right:
            print("Swiped right")
        case WKSwipeGestureRecognizerDirection.down:
            print("Swiped down")
            self.animate(withDuration: 0.2, animations: {
                self.logoutGroup.setHidden(false)
                self.swiper.direction = .up
            })
        case WKSwipeGestureRecognizerDirection.left:
            print("Swiped left")
        case WKSwipeGestureRecognizerDirection.up:
            print("Swiped up")
            self.animate(withDuration: 0.2, animations: {
                self.logoutGroup.setHidden(true)
                self.swiper.direction = .down
            })
        default:
            break
        }

    }
    
}
