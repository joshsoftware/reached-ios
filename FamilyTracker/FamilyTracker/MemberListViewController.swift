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

class MemberListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!    
    @IBOutlet weak var floatyBtn: Floaty!
    
    private var memberList = [Members]()
    private var ref: DatabaseReference!
    private var refSOS: DatabaseReference!
    var connectivityHandler = WatchSessionManager.shared
    var groupId: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        notifyGroupFound()
        setUp()
    }
    
    private func notifyGroupFound() {
        UserDefaults.standard.setValue(self.groupId, forKey: "groupId")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: kGroupFoundForCurrentUserNotification), object: nil)
    }

    private func setUp() {
        setUpFloatyButton()
        navigationController?.navigationBar.barTintColor = Constant.kColor.KDarkOrangeColor
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]

        sendGroupJoinOrCreateStatusToWatch()
        self.title = "Your Family"

        ref = Database.database().reference(withPath: "groups/\(self.groupId)")
        self.ref.queryOrdered(byChild: "created_by").observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()) {
                let createdBy = (snapshot.value as? NSDictionary)?.value(forKey: "created_by")
                if let userId = UserDefaults.standard.string(forKey: "userId") {
//                    self.addBtn.isHidden = (userId != createdBy as? String)
                }
            } else {
                
            }
        })
        setUpTableView()
        observeFirebaseRealtimeDBChanges()
        observeSOSChanges()
        let logoutBarButtonItem = UIBarButtonItem(title: "", style: .done, target: self, action: #selector(logoutUser))
        logoutBarButtonItem.setBackgroundImage(UIImage(named: "logout")?.withRenderingMode(.alwaysTemplate), for: .normal, barMetrics: .default)
        logoutBarButtonItem.tintColor = .white
        self.navigationItem.rightBarButtonItem  = logoutBarButtonItem
        self.navigationItem.setHidesBackButton(true, animated: true)
    }
    
    private func setUpFloatyButton() {
        floatyBtn.openAnimationType = .pop
        floatyBtn.overlayColor = UIColor.black.withAlphaComponent(0.2)
        floatyBtn.addItem(icon: UIImage(named: "addMember")) { (item) in
            self.navigateToShowQRCodeVC(groupId: self.groupId)
        }
        
        floatyBtn.addItem(icon: UIImage(named: "sos")) { (item) in
            if let userId = UserDefaults.standard.string(forKey: "userId"), let name = UserDefaults.standard.string(forKey: "userName") {
                let data = ["id":userId, "name": name, "show": true] as [String : Any]
                self.refSOS.child(self.groupId).setValue(data)
            }
        }
    
        for item in floatyBtn.items {
            item.iconImageView.contentMode = .scaleAspectFit
        }
        
    }
    
    @objc private func logoutUser() {
        LoadingOverlay.shared.showOverlay(view: UIApplication.shared.keyWindow ?? self.view)
        UserDefaults.standard.setValue(false, forKey: "loginStatus")
        UserDefaults.standard.setValue("", forKey: "groupId")
        UserDefaults.standard.setValue("", forKey: "userId")
        UserDefaults.standard.setValue("", forKey: "userName")
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
    
    private func sendGroupJoinOrCreateStatusToWatch() {
        self.connectivityHandler.sendMessage(message: ["groupId" : self.groupId as AnyObject], errorHandler:  { (error) in
            print("Error sending message: \(error)")
        })
    }
    
    private func sendSOSRecievedStatusToWatch(userId: String) {
        self.connectivityHandler.sendMessage(message: ["sosUserId" : userId as AnyObject], errorHandler:  { (error) in
            print("Error sending message: \(error)")
        })
    }
        
    private func observeFirebaseRealtimeDBChanges() {
        //Observe updated value for member
        self.ref.child("/members").observe(.childChanged) { (snapshot) in
            if let value = snapshot.value as? NSMutableDictionary {
                self.familyMembersLocationUpdated(value: value)
            }
        }
        
        //Observe newly added member
        self.ref.child("/members").observe(.childAdded) { (snapshot) in
            if let value = snapshot.value as? NSMutableDictionary {
                self.newFamilyMemberAdded(value: value)
            }
        }
        
        //Observe family member removed
        self.ref.child("/members").observe(.childRemoved) { (snapshot) in
            if let value = snapshot.value as? NSMutableDictionary {
                self.familyMemberRemoved(value: value)
            }
        }
    }
    
    private func observeSOSChanges() {
        //Observe updated value for sos
        self.refSOS = Database.database().reference().child("sos")
        self.refSOS.child(self.groupId).observe(.value) { (snapshot) in
            if let value = snapshot.value as? NSMutableDictionary {
                if let id = value.value(forKey: "id"), let name = value.value(forKey: "name"), let show = value.value(forKey: "show"), let userId = UserDefaults.standard.string(forKey: "userId") {
                    if id as! String != userId && show as! Bool {
                        self.sendSOSRecievedStatusToWatch(userId: id as! String)
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
    
    private func familyMembersLocationUpdated(value: NSMutableDictionary) {
        
        var member = Members()
        member.id = value["id"] as? String
        member.lat = value["lat"] as? Double
        member.long = value["long"] as? Double
        member.name = value["name"] as? String
        member.profileUrl = value["profileUrl"] as? String

        if let index = self.memberList.firstIndex(where: { $0.id == member.id }) {
            self.memberList[index] = member
            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
            
            sendUpdatedMemberListToWatch()
        }
    }
    
    private func newFamilyMemberAdded(value: NSMutableDictionary) {
        
        var member = Members()
        member.id = value["id"] as? String
        member.lat = value["lat"] as? Double
        member.long = value["long"] as? Double
        member.name = value["name"] as? String
        member.profileUrl = value["profileUrl"] as? String

        self.memberList.append(member)
        self.tableView.reloadData()
        
        sendUpdatedMemberListToWatch()

    }
    
    private func familyMemberRemoved(value: NSMutableDictionary) {
        
        var member = Members()
        member.id = value["id"] as? String
        if let index = self.memberList.firstIndex(where: { $0.id == member.id }) {
            self.memberList.remove(at: index)
            self.tableView.reloadData()
        }
        sendUpdatedMemberListToWatch()
    }
    
    private func sendUpdatedMemberListToWatch() {
        self.connectivityHandler.sendMessage(message: ["msg" : "\(self.memberList)" as AnyObject], errorHandler:  { (error) in
            print("Error sending message: \(error)")
        })
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
    
//    private func getMembersList() {
//        self.memberList.removeAll()
//        ApiClient.getFamilyMembersListWithLocations { (result) in
//            switch result {
//                case .success(let result):
//                    print(result)
//                    if let members = result.members {
//                        self.memberList = members
//                        self.tableView.reloadData()
//                    }
//                case .failure(let error):
//                    print(error.description)
//            }
//        }
//
//    }

    private func navigateToShowQRCodeVC(groupId: String) {
        if let vc = UIStoryboard.sharedInstance.instantiateViewController(withIdentifier: "ShowQRCodeViewController") as? ShowQRCodeViewController {
            vc.groupId = groupId
            vc.iIsFromCreateGroupFlow = false
            self.navigationController?.pushViewController(vc, animated: false)
        }
    }
}

extension MemberListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return memberList.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MemberTableViewCell", for: indexPath) as? MemberTableViewCell
        cell?.selectionStyle = .none
        let isIndexValid = memberList.indices.contains(indexPath.row)
        if isIndexValid {
            let memberId = memberList[indexPath.row].id
            let userId = UserDefaults.standard.string(forKey: "userId")
            if memberId == userId {
                cell?.nameLbl.text = "Me"
            } else {
                cell?.nameLbl.text = memberList[indexPath.row].name
            }
            
            if let url = URL(string: memberList[indexPath.row].profileUrl ?? "") {
                SDWebImageDownloader.shared.downloadImage(with: url) { (image, _, _, _) in
                    cell?.userProfileImgView.image = image
                }
            }
        } else if indexPath.row == memberList.count {
            cell?.nameLbl.text = "All Members"
        }
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var membersArray: [Members] = []
        
        if indexPath.row == self.memberList.count {
            membersArray = memberList
        } else {
            let member = memberList[indexPath.row]
            membersArray.append(member)
        }
        
        
        if let vc = UIStoryboard.sharedInstance.instantiateViewController(withIdentifier: "MapViewController") as? MapViewController {
            vc.memberList = membersArray
            vc.groupId = groupId
            tableView.deselectRow(at: indexPath, animated: true)
            self.navigationController?.pushViewController(vc, animated: false)
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}
