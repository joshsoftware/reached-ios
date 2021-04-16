//
//  MemberListViewController.swift
//  FamilyTracker
//
//  Created by Vijay Godse on 03/03/21.
//

import UIKit
import CoreLocation
import Firebase
import WatchConnectivity
import Floaty
import SDWebImage
import Contacts

class MemberListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!    
    @IBOutlet weak var showOnMapBtn: UIButton!
    @IBOutlet weak var floatyBtn: Floaty!
    
    var memberList = [Members]()
    private var ref: DatabaseReference!
    private var refSOS: DatabaseReference!
    private var sosState = false

    var connectivityHandler = WatchSessionManager.shared
    var groupId: String = ""
    var groupName: String = ""

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference(withPath: "groups/\(self.groupId)")
        refSOS = Database.database().reference().child("sos")

        setUp()
    }

    private func setUp() {
       
        setUpFloatyButton()
        observeSOSChanges()
        navigationController?.navigationBar.barTintColor = Constant.kColor.KDarkOrangeColor
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        self.title = groupName

        setUpTableView()
        observeFirebaseRealtimeDBChanges()
        let logoutBarButtonItem = UIBarButtonItem(title: "", style: .done, target: self, action: #selector(logoutUser))
        logoutBarButtonItem.setBackgroundImage(UIImage(named: "logout")?.withRenderingMode(.alwaysTemplate), for: .normal, barMetrics: .default)
        logoutBarButtonItem.tintColor = .white
        self.navigationItem.rightBarButtonItem  = logoutBarButtonItem
    }
    
    private func setUpFloatyButton() {
        floatyBtn.openAnimationType = .pop
        floatyBtn.overlayColor = UIColor.black.withAlphaComponent(0.2)
        
        floatyBtn.addItem("Add Member", icon: UIImage(named: "addMember")) { (item) in
            self.navigateToShowQRCodeVC(groupId: self.groupId)
        }
                
        floatyBtn.addItem("Send SOS", icon: UIImage(named: "sos")) { (item) in
            
            if let userId = UserDefaults.standard.string(forKey: "userId"), let name = UserDefaults.standard.string(forKey: "userName") {
                let data = ["id":userId, "name": name, "show": !self.sosState] as [String : Any]
                self.refSOS.child(self.groupId).setValue(data)
            }

            self.updateCurrentUsersSOSOnServer(sosState: !self.sosState)
        }
                
        for item in floatyBtn.items {
            item.iconImageView.contentMode = .scaleAspectFit
            item.titleLabel.textColor = .black
        }
        
    }
    
    @objc private func logoutUser() {
        LoadingOverlay.shared.showOverlay(view: UIApplication.shared.keyWindow ?? self.view)
        UserDefaults.standard.setValue(false, forKey: "loginStatus")
        UserDefaults.standard.setValue("", forKey: "userId")
        UserDefaults.standard.setValue("", forKey: "userName")
        UserDefaults.standard.setValue(nil, forKey: "groups")
        UserDefaults.standard.setValue("", forKey: "userProfileUrl")

        UserDefaults.standard.synchronize()
        LoadingOverlay.shared.hideOverlayView()
        if let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController {
            self.sendLoginStatusToWatch()
            self.sendUserIdToWatch()
            self.navigationController?.setViewControllers([loginVC], animated: true)
        }
    }
    
    private func sendLoginStatusToWatch() {
        self.connectivityHandler.sendMessage(message: ["loginStatus" : false as AnyObject], errorHandler:  { (error) in
            print("Error sending message: \(error)")
        })
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
    
    private func updateCurrentUsersSOSOnServer(sosState: Bool) {
        if let userId = UserDefaults.standard.string(forKey: "userId"), !userId.isEmpty {
            DatabaseManager.shared.fetchGroupsFor(userWith: userId) { (groups) in
                if let groups = groups {
                    DatabaseManager.shared.updateSOSFor(userWith: userId, groups: groups, sosState: sosState)
                }
            }
        } else {
            print("User is not logged in")
        }
    }
    
    private func observeSOSChanges() {
        //Observe updated value for sos
        self.refSOS.child(self.groupId).observe(.value) { (snapshot) in
            if let value = snapshot.value as? NSMutableDictionary {
                if let id = value.value(forKey: "id"), let name = value.value(forKey: "name"), let show = value.value(forKey: "show"), let userId = UserDefaults.standard.string(forKey: "userId") {
                    if id as! String != userId && show as! Bool {
                        self.presentAlert(withTitle: "SOS Alert", message: "Emergency! This is \(name). \nI need help. Press ok to track me.") {
                            self.refSOS.child(self.groupId).removeValue()
                            let filtered = self.memberList.filter { $0.id!.contains(id as! String) }
                            if let topVC = UIApplication.getTopViewController() {
                                if topVC.isKind(of: MapViewController.self) {
                                    if let vc = topVC as? MapViewController {
                                        vc.memberList = filtered
                                        vc.groupId = self.groupId
                                        vc.showPinForMembersLocation()
                                    }
                                } else {
                                    if let vc = UIStoryboard.sharedInstance.instantiateViewController(withIdentifier: "MapViewController") as? MapViewController {
                                        vc.memberList = filtered
                                        vc.groupId = self.groupId
                                        self.navigationController?.pushViewController(vc, animated: false)
                                    }
                                }
                            }
                        }
                    }
                }
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
        self.setSOSState(member: member)

        if let index = self.memberList.firstIndex(where: { $0.id == member.id }) {
            self.memberList[index] = member
            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
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
        self.setSOSState(member: member)
        
        self.memberList.append(member)
        self.tableView.reloadData()
        
    }
    
    private func familyMemberRemoved(value: NSMutableDictionary) {
        
        var member = Members()
        member.id = value["id"] as? String
        if let index = self.memberList.firstIndex(where: { $0.id == member.id }) {
            self.memberList.remove(at: index)
            self.tableView.reloadData()
        }
    }
    
    private func setSOSState(member: Members) {
        if let userId = UserDefaults.standard.string(forKey: "userId"), !userId.isEmpty {
            if userId == member.id {
                self.sosState = member.sosState ?? false
                if sosState {
                    self.floatyBtn.items.last?.title = "Mark Safe"
                } else {
                    self.floatyBtn.items.last?.title = "Send SOS"
                }
            }
        }
    }
    
    private func sendUserIdToWatch() {
        if let userId = UserDefaults.standard.string(forKey: "userId") {
            self.connectivityHandler.sendMessage(message: ["userId" : userId as AnyObject], errorHandler:  { (error) in
                print("Error sending message: \(error)")
            })
        }
    }
    
    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "MemberTableViewCell", bundle: nil), forCellReuseIdentifier: "MemberTableViewCell")
    }

    private func navigateToShowQRCodeVC(groupId: String) {
        if let vc = UIStoryboard.sharedInstance.instantiateViewController(withIdentifier: "ShowQRCodeViewController") as? ShowQRCodeViewController {
            vc.groupName = self.groupName
            vc.groupId = groupId
            vc.iIsFromCreateGroupFlow = false
            self.navigationController?.pushViewController(vc, animated: false)
        }
    }
    
    
    @IBAction func showOnMapBtnAction(_ sender: Any) {
        navigateToMap(membersArray: self.memberList)
    }
    
}

extension MemberListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return memberList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MemberTableViewCell", for: indexPath) as? MemberTableViewCell
        cell?.selectionStyle = .none
        let isIndexValid = memberList.indices.contains(indexPath.row)
        if isIndexValid {
            let member = memberList[indexPath.row]
            let memberId = member.id
            let userId = UserDefaults.standard.string(forKey: "userId")
            if memberId == userId {
                cell?.nameLbl.text = "Me"
            } else {
                cell?.nameLbl.text = member.name
            }
            
            if let url = URL(string: member.profileUrl ?? "") {
                SDWebImageDownloader.shared.downloadImage(with: url) { (image, _, _, _) in
                    cell?.userProfileImgView.image = image
                }
            }
            cell?.lastUpdatedLbl.text = DateUtils.formatLastUpdated(dateString: member.lastUpdated ?? "")
            
            if let lat = member.lat, let long =  member.long {
                let location = CLLocation(latitude: lat, longitude: long)
                location.fetchCityAndCountry { (name, city, error) in
                    if error == nil {
                        cell?.currentLocationLbl.text = (name ?? "") + ", " + (city ?? "")
                    }
                }
            }
            
            if let sosState = member.sosState, sosState {
                cell?.containerView.layer.borderWidth = 2.0
                cell?.containerView.layer.borderColor = UIColor.red.cgColor
            } else {
                cell?.containerView.layer.borderWidth = 0.0
                cell?.containerView.layer.borderColor = UIColor.clear.cgColor
            }
        }
        
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let isIndexValid = memberList.indices.contains(indexPath.row)
        if isIndexValid {
            let membersArray: [Members] = [memberList[indexPath.row]]
            navigateToMap(membersArray: membersArray)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    private func navigateToMap(membersArray: [Members]) {
        if let vc = UIStoryboard.sharedInstance.instantiateViewController(withIdentifier: "MapViewController") as? MapViewController {
            vc.memberList = membersArray
            vc.groupId = groupId
            self.navigationController?.pushViewController(vc, animated: false)
        }
    }
}
