//
//  InterfaceController.swift
//  FamilyTracker WatchKit Extension
//
//  Created by Vijay Godse on 02/03/21.
//

import WatchKit
import Foundation
import CoreLocation
import FirebaseDatabase
import FirebaseCore

class InterfaceController: WKInterfaceController, NibLoadableViewController {
    
    @IBOutlet weak var tableView: WKInterfaceTable!
    @IBOutlet weak var headerLbl: WKInterfaceLabel!
    @IBOutlet weak var refreshBtn: WKInterfaceButton!
    @IBOutlet weak var logoutBtn: WKInterfaceButton!
    
    private var userRef: DatabaseReference!
    var groups : NSDictionary = NSDictionary()
    
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
        fetchGroups()
        observeFirebaseRealtimeDBChanges()
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
    }
        
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
    }
    
    private func setUp() {
                 
        if groupList.count > 0 {
    
            self.tableView.setHidden(false)
            self.headerLbl.setHidden(false)
            self.refreshBtn.setHidden(true)

            //TODO - make nav title to center
            self.setTitle("Reached")
            
        } else {
            self.setTitle("")
            self.tableView.setHidden(true)
            self.headerLbl.setHidden(true)
            self.refreshBtn.setHidden(false)

            let titleOfAlert = ""
            let messageOfAlert = "Create or Join group from your connected phone"
            self.presentAlert(withTitle: titleOfAlert, message: messageOfAlert, preferredStyle: .alert, actions: [WKAlertAction(title: "OK", style: .default){
                //something after clicking OK
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

    @IBAction func refreshBtnAction() {
        setUp()
    }
    
    
    @IBAction func logoutBtnAction() {
        UserDefaults.standard.setValue(false, forKey: "loginStatus")
        UserDefaults.standard.setValue("", forKey: "userId")
        UserDefaults.standard.setValue("", forKey: "userName")
//        UserDefaults.standard.setValue("", forKey: "userProfileUrl")
        UserDefaults.standard.synchronize()
        DispatchQueue.main.async() {
            WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: LoginInterfaceController.name, context: "" as AnyObject)])
        }
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {

        let isIndexValid = self.groupList.indices.contains(rowIndex)
        
        if isIndexValid {
            let group = self.groupList[rowIndex]
            self.pushController(withName: MemberListInterfaceController.name, context: group)
        }
    }
    
}
