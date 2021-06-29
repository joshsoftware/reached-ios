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

class MemberListInterfaceController: BaseInterfaceController, NibLoadableViewController {

    @IBOutlet weak var tableView: WKInterfaceTable!
    @IBOutlet weak var groupNameLbl: WKInterfaceLabel!
    @IBOutlet weak var showonMapBtn: WKInterfaceButton!

    private var ref: DatabaseReference!
    private var refSOS: DatabaseReference!

    var selectedGroup: Group?
    
    var itemList: [Members] = [] {
        didSet {
            if itemList.count > 0 {
                tableView.setNumberOfRows(itemList.count, withRowType: "MemberRowController")
                for index in 0..<tableView.numberOfRows {
                    guard let controller = tableView.rowController(at: index) as? MemberRowController else { continue }
                    let memberId = itemList[index].id
                    let userId = UserDefaults.standard.string(forKey: "userId")
                    if memberId == userId {
                        itemList[index].name = "Me"
                    }
                    controller.item = itemList[index]
                }
             
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
        if selectedGroup.name != nil {
            setUp()
        } else {
            if let groupId = selectedGroup.id {
                DatabaseManager.shared.fetchGroupData(groups: [groupId:""]) { (groupData) in
                    if let group = groupData {
                        self.selectedGroup = group
                        self.itemList.removeAll()
                        self.setUp()
                    }
                }
            }
        }
    }
    
    private func setUp() {
        
        if let selectedGroup = self.selectedGroup, let groupId = selectedGroup.id {
            groupNameLbl.setText(selectedGroup.name ?? "")
            ref = Database.database().reference(withPath: "groups/\(groupId)")
            refSOS = Database.database().reference().child("sos")
            observeFirebaseRealtimeDBChanges()
        }

    }
    
    private func observeFirebaseRealtimeDBChanges() {
        observeSOSChanges()
        
        //Observe updated value for member
        self.ref.child("/members").observe(.childChanged) { (snapshot) in
            if let value = snapshot.value as? NSMutableDictionary {
                self.familyMembersLocationUpdated(key: snapshot.key, value: value)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "fetchGroupsNotification"), object: nil)
            }
        }
        
        //Observe newly added member
        self.ref.child("/members").observe(.childAdded) { (snapshot) in
            if let value = snapshot.value as? NSMutableDictionary {
                self.newFamilyMemberAdded(key: snapshot.key, value: value)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "fetchGroupsNotification"), object: nil)
            }
        }
        
        //Observe family member removed
        self.ref.child("/members").observe(.childRemoved) { (snapshot) in
            if let value = snapshot.value as? NSMutableDictionary {
                self.familyMemberRemoved(value: value)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "fetchGroupsNotification"), object: nil)
            }
        }
    }
    
    private func familyMembersLocationUpdated(key: String, value: NSMutableDictionary) {
        
        var member = Members()
        member.id = key
        member.lat = value["lat"] as? Double
        member.long = value["long"] as? Double
        member.name = value["name"] as? String
        member.profileUrl = value["profileUrl"] as? String
        member.lastUpdated = value["lastUpdated"] as? String
        member.sosState = value["sosState"] as? Bool

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
        member.profileUrl = value["profileUrl"] as? String
        member.lastUpdated = value["lastUpdated"] as? String
        member.sosState = value["sosState"] as? Bool

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
    
    private func observeSOSChanges() {
        guard let groupId = self.selectedGroup?.id else { return }
        //Observe updated value for sos
        self.refSOS.child(groupId).observe(.value) { (snapshot) in
            if let value = snapshot.value as? NSMutableDictionary {
                if let id = value.value(forKey: "id") as? String, let show = value.value(forKey: "show") as? Bool, let userId = UserDefaults.standard.string(forKey: "userId"), !userId.isEmpty {
                    if id != userId && show {
                        self.showSOSAlert(sosUserId: id)
                    }
                }
            }
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
        
        self.refSOS.child(self.selectedGroup?.id ?? "").removeValue()
        
        let titleOfAlert = "SOS Alert"
        let messageOfAlert = "Emergency! This is \(userName). \nI need help. Press ok to track me."
        
        let action = WKAlertAction.init(title: "OK", style: .default) {
            self.pushController(withName: MapInterfaceController.name, context: (filtered, self.selectedGroup))
        }
    
        self.presentAlert(withTitle: titleOfAlert, message: messageOfAlert, preferredStyle: .alert, actions: [action])

    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        let isIndexValid = itemList.indices.contains(rowIndex)
        if isIndexValid {
            let membersArray: [Members] = [itemList[rowIndex]]
            self.pushController(withName: MapInterfaceController.name, context: (membersArray, selectedGroup))
        }
    }
    
    @IBAction func showOnMapBtnAction() {
        self.pushController(withName: MapInterfaceController.name, context: (itemList, selectedGroup))
    }
    
    @IBAction func swipe(_ sender: WKSwipeGestureRecognizer) {
        switch sender.direction {
        case WKSwipeGestureRecognizerDirection.right:
            print("Swiped right")
            self.pop()
        case WKSwipeGestureRecognizerDirection.down:
            print("Swiped down")
        case WKSwipeGestureRecognizerDirection.left:
            print("Swiped left")
        case WKSwipeGestureRecognizerDirection.up:
            print("Swiped up")
        default:
            break
        }

    }
}
