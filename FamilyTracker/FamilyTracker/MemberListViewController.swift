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
    var connectivityHandler = WatchSessionManager.shared
    var groupId: String = ""
    var groupName: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setUp()
    }

    private func setUp() {
        setUpFloatyButton()
        navigationController?.navigationBar.barTintColor = Constant.kColor.KDarkOrangeColor
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        self.title = groupName

        ref = Database.database().reference(withPath: "groups/\(self.groupId)")
        setUpTableView()
        observeFirebaseRealtimeDBChanges()
        observeSOSChanges()
        let logoutBarButtonItem = UIBarButtonItem(title: "", style: .done, target: self, action: #selector(logoutUser))
        logoutBarButtonItem.setBackgroundImage(UIImage(named: "logout")?.withRenderingMode(.alwaysTemplate), for: .normal, barMetrics: .default)
        logoutBarButtonItem.tintColor = .white
        self.navigationItem.rightBarButtonItem  = logoutBarButtonItem
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
        UserDefaults.standard.setValue("", forKey: "userId")
        UserDefaults.standard.setValue("", forKey: "userName")
        UserDefaults.standard.setValue(nil, forKey: "groups")

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
    
    private func sendSOSRecievedStatusToWatch(userId: String) {
        self.connectivityHandler.sendMessage(message: ["sosUserId" : userId as AnyObject], errorHandler:  { (error) in
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
    
    private func familyMembersLocationUpdated(key: String, value: NSMutableDictionary) {
        
        var member = Members()
        member.id = key
        member.lat = value["lat"] as? Double
        member.long = value["long"] as? Double
        member.name = value["name"] as? String
        member.profileUrl = value["profileUrl"] as? String
        member.lastUpdated = value["lastUpdated"] as? String

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
            cell?.lastUpdatedLbl.text = DateUtils.formatLastUpdated(dateString: memberList[indexPath.row].lastUpdated ?? "")
            
            if let lat = memberList[indexPath.row].lat, let long =  memberList[indexPath.row].long {
                let location = CLLocation(latitude: lat, longitude: long)
                location.fetchCityAndCountry { (name, city, error) in
                    if error == nil {
                        cell?.currentLocationLbl.text = "at " + (name ?? "") + ", " + (city ?? "")
                    }
                }
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
