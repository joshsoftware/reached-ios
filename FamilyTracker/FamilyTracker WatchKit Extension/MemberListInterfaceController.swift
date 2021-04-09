//
//  MemberListInterfaceController.swift
//  FamilyTracker WatchKit Extension
//
//  Created by Vijay Godse on 08/04/21.
//

import WatchKit
import Foundation
import CoreLocation
import WatchConnectivity
import FirebaseDatabase

class MemberListInterfaceController: WKInterfaceController, NibLoadableViewController {

    @IBOutlet weak var tableView: WKInterfaceTable!
    
    private var connectivityHandler = WatchSessionManager.shared
    private var ref: DatabaseReference!
    private var refSOS: DatabaseReference!

    var selectedGroup: Group?
    
    var itemList: [Members] = [] {
        didSet {
            if itemList.count > 0 {
                tableView.setNumberOfRows(itemList.count + 1, withRowType: "MemberRowController")
                for index in 0..<tableView.numberOfRows - 1 {
                    guard let controller = tableView.rowController(at: index) as? MemberRowController else { continue }
                    let memberId = itemList[index].id
                    let userId = UserDefaults.standard.string(forKey: "userId")
                    if memberId == userId {
                        itemList[index].name = "Me"
                    }
                    controller.item = itemList[index]
                }
                
                guard let controller = tableView.rowController(at: tableView.numberOfRows - 1) as? MemberRowController else { return }
                var item = Members()
                item.name = "All Members"
                controller.item = item
            }
        }
    }

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        guard let selectedGroup = context as? Group else {
            return
        }
        self.selectedGroup = selectedGroup
        self.itemList.removeAll()
        setUp()
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        setUp()
        connectivityHandler.startSession()
        connectivityHandler.watchOSDelegate = self
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    private func setUp() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: kLocationDidChangeNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(locationUpdateNotification(notification:)), name: NSNotification.Name(rawValue: kLocationDidChangeNotification), object: nil)
        let locationManager = UserLocationManager.shared
        locationManager.delegate = self
        
        if let selectedGroup = self.selectedGroup, let groupId = selectedGroup.id {
//            self.setTitle(selectedGroup.name ?? "")
            ref = Database.database().reference(withPath: "groups/\(groupId)")
            observeFirebaseRealtimeDBChanges()
        }

    }
    
    private func observeFirebaseRealtimeDBChanges() {
        //Observe updated value for member
        self.ref.child("/members").observe(.childChanged) { (snapshot) in
            if let value = snapshot.value as? NSMutableDictionary {
                self.familyMembersLocationUpdated(key: snapshot.key, value: value)
            }
        }
        
        //Observe newly added member
        self.ref.child("/members").observe(.childAdded) { (snapshot) in
            if let value = snapshot.value as? NSMutableDictionary {
                self.newFamilyMemberAdded(key: snapshot.key, value: value)
            }
        }
        
        //Observe family member removed
        self.ref.child("/members").observe(.childRemoved) { (snapshot) in
            if let value = snapshot.value as? NSMutableDictionary {
                self.familyMemberRemoved(value: value)
            }
        }
    }
    
    private func familyMembersLocationUpdated(key: String, value: NSMutableDictionary) {
        
        var member = Members()
        member.id = key
        member.lat = value["lat"] as? Double
        member.long = value["long"] as? Double
        member.name = value["name"] as? String
        
        if let index = self.itemList.firstIndex(where: { $0.id == member.id }) {
            self.itemList[index] = member
        }
    }
    
    private func newFamilyMemberAdded(key: String, value: NSMutableDictionary) {
        var member = Members()
        member.id = key
        member.lat = value["lat"] as? Double
        member.long = value["long"] as? Double
        member.name = value["name"] as? String
        
        let filtered = self.itemList.filter { ($0.id ?? "").contains(member.id ?? "") }

        if filtered.count <= 0 {
            self.itemList.append(member)
        }
        
    }
    
    private func familyMemberRemoved(value: NSMutableDictionary) {
        var member = Members()
        member.id = value["id"] as? String
        if let index = self.itemList.firstIndex(where: { $0.id == member.id }) {
            self.itemList.remove(at: index)
        }
    }

    private func showSOSAlert(sosUserId: String) {
        
        var userName = ""
        let filtered = self.itemList.filter { ($0.id?.contains(sosUserId) ?? false) }

        for member in filtered {
            if member.id == sosUserId {
                userName = member.name ?? ""
                break
            }
        }
        
        let titleOfAlert = "SOS Alert"
        let messageOfAlert = "Emergency! This is \(userName). \nI need help. Press ok to track me."
        DispatchQueue.main.async {
            self.presentAlert(withTitle: titleOfAlert, message: messageOfAlert, preferredStyle: .alert, actions: [WKAlertAction(title: "OK", style: .default){
                //something after clicking OK
                self.pushController(withName: MapInterfaceController.name, context: filtered)
            }])
        }
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
        var membersArray: [Members] = []
        
        if rowIndex == self.itemList.count {
            membersArray = itemList
        } else {
            let member = itemList[rowIndex]
            membersArray.append(member)
        }
        
        self.pushController(withName: MapInterfaceController.name, context: (membersArray, selectedGroup))
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

extension MemberListInterfaceController: LocationUpdateDelegate {
    
    func locationDidUpdateToLocation(location: CLLocation) {
        print("Latitude : \(location.coordinate.latitude)")
        print("Longitude : \(location.coordinate.longitude)")
        self.updateCurrentUserLocation(location: location)
    }
}

extension MemberListInterfaceController: WatchOSDelegate {
    
    func applicationContextReceived(tuple: ApplicationContextReceived) {
    }
    
    
    func messageReceived(tuple: MessageReceived) {
        DispatchQueue.main.async() {
            WKInterfaceDevice.current().play(.notification)
            
            if let loginStatus = tuple.message["loginStatus"] as? Bool {
                UserDefaults.standard.setValue(loginStatus, forKey: "loginStatus")
                if !loginStatus {
                    self.pop()
                }
            }
            
            if let userId = tuple.message["userId"] as? String {
                UserDefaults.standard.setValue(userId, forKey: "userId")
            }
            
            if let sosUserId = tuple.message["sosUserId"] as? String {
                DispatchQueue.main.async {
                    self.showSOSAlert(sosUserId: sosUserId)
                }
            }
            
            
        }
    }
    
}

