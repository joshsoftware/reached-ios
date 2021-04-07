//
//  GroupListViewController.swift
//  FamilyTracker
//
//  Created by Mahesh on 06/04/21.
//

import UIKit
import Floaty
import SDWebImage
import Firebase
import CoreLocation

class GroupListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var floatyBtn: Floaty!
    
    private var ref: DatabaseReference!
    var groups : NSDictionary = NSDictionary()
    private var groupList = [Group]()
    private var currentLocation : CLLocationCoordinate2D = CLLocationCoordinate2D()
    private let locationManager = CLLocationManager()
    var currentUserProfileUrl: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setUpFloatyButton()
        setUpTableView()
        setUpLocationManager()
        fetchGroups()
        // Do any additional setup after loading the view.
    }
    
    func setupNavigationBar() {
        self.title = "My Groups"
        navigationController?.navigationBar.barTintColor = Constant.kColor.KDarkOrangeColor
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        self.navigationItem.setHidesBackButton(true, animated: true)
        let logoutBarButtonItem = UIBarButtonItem(title: "", style: .done, target: self, action: #selector(logoutUser))
        logoutBarButtonItem.setBackgroundImage(UIImage(named: "logout")?.withRenderingMode(.alwaysTemplate), for: .normal, barMetrics: .default)
        logoutBarButtonItem.tintColor = .white
        self.navigationItem.rightBarButtonItem  = logoutBarButtonItem
    }

    private func setUpFloatyButton() {
        floatyBtn.openAnimationType = .pop
        floatyBtn.overlayColor = UIColor.black.withAlphaComponent(0.2)
        floatyBtn.addItem(icon: UIImage(named: "addMember")) { (item) in
            CreateGroupPopUpVC.showPopup(parentVC: self)
            CreateGroupPopUpVC.groupCreatedHandler = { groupId in
                print("Group created..\(groupId)")
                self.fetchGroups()
            }
        }
        
        //TODO: change SOS to join group
        floatyBtn.addItem(icon: UIImage(named: "sos")) { (item) in
            ScanQRCodeViewController.showPopup(parentVC: self)
            ScanQRCodeViewController.groupJoinedHandler = { qrString in
                self.qrScanningSucceededWithCode(qrString: qrString)
            }
        }

        for item in floatyBtn.items {
            item.iconImageView.contentMode = .scaleAspectFit
        }
        
    }
    
    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "MemberTableViewCell", bundle: nil), forCellReuseIdentifier: "MemberTableViewCell")
    }
    
    private func setUpLocationManager() {
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()

        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()

        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }
    
    func fetchGroups() {
        self.groupList.removeAll()
        if let userId = UserDefaults.standard.string(forKey: "userId") {
            LoadingOverlay.shared.showOverlay(view: UIApplication.shared.keyWindow ?? self.view)
            DatabaseManager.shared.fetchGroupsFor(userWith: userId) { (groups) in
                LoadingOverlay.shared.hideOverlayView()
                if let groups = groups {
                    DatabaseManager.shared.fetchGroupData(groups: groups) { (data) in
                        if let data = data {
                            self.groupList.append(data)
                            self.tableView.reloadData()
                        }
                    }
                }
            }
        }
    }
    
    @objc private func logoutUser() {
        LoadingOverlay.shared.showOverlay(view: UIApplication.shared.keyWindow ?? self.view)
        UserDefaults.standard.setValue(false, forKey: "loginStatus")
        UserDefaults.standard.setValue("", forKey: "groupId")
        UserDefaults.standard.setValue("", forKey: "userId")
        UserDefaults.standard.setValue("", forKey: "userName")
        UserDefaults.standard.setValue(nil, forKey: "groupId")
        UserDefaults.standard.synchronize()
        LoadingOverlay.shared.hideOverlayView()
        if let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController {
//            self.sendLoginStatusToWatch()
//            self.sendUserIdToWatch()
            self.navigationController?.setViewControllers([loginVC], animated: true)
        }
    }
    
    private func qrScanningSucceededWithCode(qrString: String?) {
        var memberArray : Array = Array<Any>()
        var createdBy: String?
        
        self.ref.child("groups/\(qrString ?? "")").getData { (error, snapshot) in
            if let error = error {
                print("Error getting data \(error)")
            }
            else if snapshot.exists() {
                print("Got data \(snapshot.value!)")
                let dict = snapshot.value as? NSDictionary
                guard let members = dict?.value(forKey: "members") as? NSArray else {
                    return
                }
                
                guard let createdByStr = dict?.value(forKey: "created_by") as? String else {
                    return
                }
                createdBy = createdByStr
                
                for member in members {
                    let data = member as! NSDictionary
                    let memberData = ["id":data.value(forKey: "id") ?? "", "lat": data.value(forKey: "lat") ?? 0, "long": data.value(forKey: "long") ?? 0, "name": data.value(forKey: "name") ?? "", "profileUrl": data.value(forKey: "profileUrl") ?? ""] as [String : Any]
                    memberArray.append(memberData)
                }
                if let userId = UserDefaults.standard.string(forKey: "userId"), let name = UserDefaults.standard.string(forKey: "userName") {
                    let currentUserData = ["id":userId, "lat": self.currentLocation.latitude, "long": self.currentLocation.longitude, "name": name, "profileUrl": self.currentUserProfileUrl ?? ""] as [String : Any]
                    memberArray.append(currentUserData)
                }
                
                self.ref = Database.database().reference(withPath: "groups/\(qrString ?? "")")
                self.ref.setValue(["created_by": createdBy ?? "", "members": memberArray])
                
                self.fetchGroups()
            }
            else {
                print("No data available")
            }
        }
    }

}

extension GroupListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.groupList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MemberTableViewCell", for: indexPath) as? MemberTableViewCell
        let data = self.groupList[indexPath.row]
        cell?.nameLbl.text = data.name
        cell?.selectionStyle = .none
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let data = self.groupList[indexPath.row]
        if let vc = UIStoryboard.sharedInstance.instantiateViewController(withIdentifier: "MemberListViewController") as? MemberListViewController {
            vc.groupId = data.id ?? ""
            vc.groupName = data.name ?? ""
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}

extension GroupListViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        self.currentLocation = locValue
    }
}