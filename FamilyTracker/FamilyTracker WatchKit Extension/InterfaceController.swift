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

class InterfaceController: WKInterfaceController, NibLoadableViewController {
    
    @IBOutlet weak var tableView: WKInterfaceTable!
    @IBOutlet weak var refreshBtn: WKInterfaceButton!
    
    @IBOutlet weak var signInGroup: WKInterfaceGroup!
    @IBOutlet weak var signInBtn: WKInterfaceButton!
    
    var connectivityHandler = WatchSessionManager.shared
    private var userRef: DatabaseReference!
    var groups : NSDictionary = NSDictionary()
    var isAlertDismissed = false
    
    private var groupList = [Group]() {
        didSet {
            if groupList.count > 0 {
                tableView.setNumberOfRows(groupList.count, withRowType: "GroupRowController")
                for index in 0..<tableView.numberOfRows{
                    guard let controller = tableView.rowController(at: index) as? GroupRowController else { continue }
                    controller.item = groupList[index]
                }
            }
        }
    }
    
    override func awake(withContext context: Any?) {
        // Configure interface objects here.
        super.awake(withContext: context)
        FirebaseApp.configure()
        signInGroup.setHidden(true)
        signInBtn.setBackgroundImageNamed("google")
        
        fetchGroups()
        observeFirebaseRealtimeDBChanges()
        
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        setUp()
        connectivityHandler.startSession()
        connectivityHandler.watchOSDelegate = self
    }
        
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
    }
    
    private func setUp() {
                 
        if UserDefaults.standard.bool(forKey: "loginStatus") == true && groupList.count > 0 {
         
            if !isAlertDismissed {
                isAlertDismissed = true
                DispatchQueue.main.async {
                    self.dismiss()
                }
            }
            
            self.tableView.setHidden(false)
            self.refreshBtn.setHidden(true)
            self.signInGroup.setHidden(true)

            self.setTitle("My Groups")
            
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: kLocationDidChangeNotification), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(locationUpdateNotification(notification:)), name: NSNotification.Name(rawValue: kLocationDidChangeNotification), object: nil)
            let locationManager = UserLocationManager.shared
            locationManager.delegate = self
        } else if UserDefaults.standard.bool(forKey: "loginStatus") == true && groupList.count <= 0 {
            self.setTitle("")
            self.isAlertDismissed = false
            self.tableView.setHidden(true)
            self.refreshBtn.setHidden(false)
            self.signInGroup.setHidden(true)

            let titleOfAlert = ""
            let messageOfAlert = "Create or Join group from your connected phone"
            self.presentAlert(withTitle: titleOfAlert, message: messageOfAlert, preferredStyle: .alert, actions: [WKAlertAction(title: "OK", style: .default){
                //something after clicking OK
            }])
        } else {
            self.setTitle("")
            self.tableView.setHidden(true)
            self.refreshBtn.setHidden(true)
            self.signInGroup.setHidden(false)
        }
        
    }
    
    private func showSignInRequiredAlert() {
        let titleOfAlert = "Sign In required"
        let messageOfAlert = "Sign In from your connected phone"
        DispatchQueue.main.async {
            self.presentAlert(withTitle: titleOfAlert, message: messageOfAlert, preferredStyle: .alert, actions: [WKAlertAction(title: "OK", style: .default){
                //something after clicking OK
                self.refreshBtn.setHidden(false)
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

    func fetchGroups() {
        self.groupList.removeAll()
        if let userId = UserDefaults.standard.string(forKey: "userId"), !userId.isEmpty {
            DatabaseManager.shared.fetchGroupsFor(userWith: userId) { (groups) in
                if let groups = groups {
                    DatabaseManager.shared.fetchGroupData(groups: groups) { (data) in
                        if let data = data {
                            let filtered = self.groupList.filter { ($0.id ?? "").contains(data.id ?? "") }

                            if filtered.count <= 0 {
                                self.groupList.append(data)
                                self.setUp()
                            }
                            
                        }
                    }
                }
            }
        }
    }
    
    
    @IBAction func signInBtnAction() {
        showSignInRequiredAlert()
    }
    
    @IBAction func refreshBtnAction() {
        setUp()
    }
    
    // MARK: - Notifications

    @objc private func locationUpdateNotification(notification: NSNotification) {
        let userinfo = notification.userInfo
        if let currentLocation = userinfo?["location"] as? CLLocation {
            print("Latitude : \(currentLocation.coordinate.latitude)")
            print("Longitude : \(currentLocation.coordinate.longitude)")
            self.updateCurrentUserLocation(location: currentLocation)
        }
        
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {

        let isIndexValid = self.groupList.indices.contains(rowIndex)
        
        if isIndexValid {
            let group = self.groupList[rowIndex]
            self.pushController(withName: MemberListInterfaceController.name, context: group)
        }
    }
    
    func updateCurrentUserLocation(location: CLLocation) {
        if let userId = UserDefaults.standard.string(forKey: "userId") {
            DatabaseManager.shared.fetchGroupsFor(userWith: userId) { (groups) in
                if let groups = groups {
                    DatabaseManager.shared.updateLocationFor(userWith: userId, groups: groups, location: location)
                }
            }
        }
    }
    
}

extension InterfaceController: LocationUpdateDelegate {
    
    func locationDidUpdateToLocation(location: CLLocation) {
        print("Latitude : \(location.coordinate.latitude)")
        print("Longitude : \(location.coordinate.longitude)")
        self.updateCurrentUserLocation(location: location)
    }
}

extension InterfaceController: WatchOSDelegate {
    
    func applicationContextReceived(tuple: ApplicationContextReceived) {
    }
    
    
    func messageReceived(tuple: MessageReceived) {
        DispatchQueue.main.async() {
            WKInterfaceDevice.current().play(.notification)
            
            if let loginStatus = tuple.message["loginStatus"] as? Bool {
                UserDefaults.standard.setValue(loginStatus, forKey: "loginStatus")
                self.setUp()
            }
            
            if let userId = tuple.message["userId"] as? String {
                UserDefaults.standard.setValue(userId, forKey: "userId")
                self.setUp()
                if !userId.isEmpty {
                    self.observeFirebaseRealtimeDBChanges()
                }
            }
                        
//            if let sosUserId = tuple.message["sosUserId"] as? String {
//                DispatchQueue.main.async {
//                    self.showSOSAlert(sosUserId: sosUserId)
//                }
//            }
            
            
        }
    }
    
}
