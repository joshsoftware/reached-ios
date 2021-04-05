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

class InterfaceController: WKInterfaceController, NibLoadableViewController {
    
    @IBOutlet weak var tableView: WKInterfaceTable!
    @IBOutlet weak var refreshBtn: WKInterfaceButton!
    
    @IBOutlet weak var signInGroup: WKInterfaceGroup!
    @IBOutlet weak var signInBtn: WKInterfaceButton!
    
    var connectivityHandler = WatchSessionManager.shared
    private var timer = Timer()
    let session = WCSession.default
    var groupId: String = ""
    
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
        // Configure interface objects here.
        super.awake(withContext: context)
        watchKitSetup()
        signInGroup.setHidden(true)
        signInBtn.setBackgroundImageNamed("google")
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
        
        groupId = UserDefaults.standard.value(forKey: "groupId") as? String ?? ""
         
        if UserDefaults.standard.bool(forKey: "loginStatus") == true && !groupId.isEmpty{
            self.tableView.setHidden(false)
            self.refreshBtn.setHidden(true)
            self.signInGroup.setHidden(true)

            self.setTitle("Your Family")
            getMemberList()
            
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: kLocationDidChangeNotification), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(locationUpdateNotification(notification:)), name: NSNotification.Name(rawValue: kLocationDidChangeNotification), object: nil)
            let locationManager = UserLocationManager.shared
            locationManager.delegate = self
        } else if UserDefaults.standard.bool(forKey: "loginStatus") == true && groupId.isEmpty {
            self.setTitle("")
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
    
    private func watchKitSetup() {
        if (WCSession.isSupported()) {
            session.delegate = self
            session.activate()
            sleep(5)
            if session.isReachable {
                timer.invalidate()
            } else {
                setUpTimer()
            }
        }
    }
    
    private func setUpTimer() {
        timer.invalidate()
        // start the timer
        timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
    }
    
    // called every time interval from the timer
    @objc private func timerAction() {
        getMemberList()
    }

    private func getMemberList() {
        ApiClient.getFamilyMembersListWithLocations(groupId: groupId) { (result) in
            switch result {
                case .success(let result):
                    self.itemList = result.members ?? []
                case .failure(let error):
                    print(error.description)
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
        var membersArray: [Members] = []
        
        if rowIndex == self.itemList.count {
            membersArray = itemList
        } else {
            let member = itemList[rowIndex]
            membersArray.append(member)
        }
        
        self.pushController(withName: MapInterfaceController.name, context: membersArray)
    }
    
    func updateCurrentUserLocation(location: CLLocation) {
        //Do not update location if watch is connected with phone
//        guard !(session.isReachable) else {
//            return
//        }
        
        if groupId.isEmpty {
            return
        }
        
        guard let userId = UserDefaults.standard.string(forKey: "userId"), !userId.isEmpty else {
            return
        }
        
        var updatedParams = [[String: AnyObject]]()
        for item in itemList {
            if item.id == userId {
                let data = ["id": item.id!, "lat": location.coordinate.latitude, "long": location.coordinate.longitude, "name": item.name!, "profileUrl": item.profileUrl ?? ""] as [String : AnyObject]
                updatedParams.append(data)
            } else {
                let data = ["id": item.id!, "lat": item.lat!, "long": item.long!, "name": item.name!, "profileUrl": item.profileUrl ?? ""] as [String : AnyObject]
                updatedParams.append(data)
            }
        }

        if updatedParams.count > 0 {
            ApiClient.updateLocation(params: updatedParams, groupId: groupId) {(result) in
                switch result {
                case .success(let result):
                    print(result)
                case .failure(let error):
                    print(error.description)
                }
                self.getMemberList()
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
                if loginStatus {
//                    DispatchQueue.main.async {
//                        self.dismiss()
//                    }
                } else {
                    UserDefaults.standard.setValue("", forKey: "groupId")
                }
                self.setUp()
            }
            
            if let userId = tuple.message["userId"] as? String {
                UserDefaults.standard.setValue(userId, forKey: "userId")
            }
            
            
            if let groupId = tuple.message["groupId"] as? String {
                UserDefaults.standard.setValue(groupId, forKey: "groupId")
                DispatchQueue.main.async {
                    self.dismiss()
                }
                self.setUp()
            }
            
            if let _ = tuple.message["msg"] {
//                                print(msg as! [Members])
                //TODO: instead of API call, parse msg object to membersArray and use it
                self.getMemberList()
            }
            
            if let sosUserId = tuple.message["sosUserId"] as? String {
                DispatchQueue.main.async {
                    self.showSOSAlert(sosUserId: sosUserId)
                }
            }
            
            
        }
    }
    
}

extension InterfaceController: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            timer.invalidate()
        } else {
            setUpTimer()
        }
    }
}

