//
//  HomeViewController.swift
//  FamilyTracker
//
//  Created by Mahesh on 16/03/21.
//

import UIKit
import Firebase
import CoreLocation
import Panels
import SVProgressHUD

class HomeViewController: UIViewController {
    @IBOutlet var topView: UIView!
    
    private var ref: DatabaseReference!
    var currentLocation : CLLocationCoordinate2D = CLLocationCoordinate2D()
    let groupId = UUID().uuidString
    let locationManager = CLLocationManager()

    lazy var panelManager = Panels(target: self)
    let panel = UIStoryboard.instantiatePanel(identifier: "Home")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var panelConfiguration = PanelConfiguration(size: .custom(100.0))
        panelConfiguration.enclosedNavigationBar = false
        panelManager.delegate = self
        panelManager.show(panel: panel, config: panelConfiguration)
        
        if let vc = panel as? Panelable & CreateGroupViewController {
            vc.endEditingHandler = { groupName in
                self.panelManager.collapsePanel()
                self.createGroup(groupName: groupName)
            }
        }
        
        ref = Database.database().reference()
        setUpLocationManager()
        self.navigationItem.setHidesBackButton(true, animated: true)
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
 
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        topView.roundBottom(radius: 10)
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
    
    @IBAction func createGroupButtonPressed(_ sender: Any) {
        self.panelManager.expandPanel()
        if let vc = panel as? Panelable & CreateGroupViewController {
            vc.textField.becomeFirstResponder()
        }
    }
    
    @IBAction func joinbuttonPressed(_ sender: Any) {
        ScanQRCodeViewController.showPopup(parentVC: self)
        ScanQRCodeViewController.groupJoinedHandler = { qrString in
            DatabaseManager.shared.joinToGroupWith(groupId: qrString, currentLocation: self.currentLocation) {
                if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GroupListViewController") as? GroupListViewController {
                    self.navigationController?.pushViewController(vc, animated: false)
                }
            }
        }
    }

    private func navigateToShowQRCodeVC(groupId: String, groupName: String) {
        if let vc = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "ShowQRCodeViewController") as? ShowQRCodeViewController {
            vc.groupId = groupId
            vc.groupName = groupName
            vc.iIsFromCreateGroupFlow = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func createGroup(groupName: String) {
        SVProgressHUD.show()
        if let userId = UserDefaults.standard.string(forKey: "userId") {
            let data = ["lat": self.currentLocation.latitude, "long": self.currentLocation.longitude, "name": "name", "lastUpdated": Date().currentUTCDate(), "profileUrl": "profileUrl"] as [String : Any]
            var memberArray : Array = Array<Any>()
            memberArray.append(data)

            self.ref.child("groups").child(self.groupId).setValue(["created_by": userId, "name": groupName])
            self.ref.child("groups").child(self.groupId).child("members").child(userId).setValue(data)
            
            if var dict = UserDefaults.standard.dictionary(forKey: "groups") {
                dict[self.groupId] = true
                self.ref.child("users").child(userId).child("groups").setValue(dict)
                UserDefaults.standard.setValue(dict, forKey: "groups")
            } else {
                let dict = [self.groupId: true]
                self.ref.child("users").child(userId).child("groups").setValue(dict)
                UserDefaults.standard.setValue(dict, forKey: "groups")
            }
            SVProgressHUD.dismiss()
            self.navigateToShowQRCodeVC(groupId: self.groupId, groupName: groupName)
        }
    }
}

extension HomeViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        self.currentLocation = locValue
    }
}

extension HomeViewController: PanelNotifications {
    func panelDidPresented() {
        if let vc = panel as? Panelable & CreateGroupViewController {
            vc.panelDidPresented()
        }
    }
    
    func panelDidCollapse() {
        if let vc = panel as? Panelable & CreateGroupViewController {
            vc.panelDidCollapse()
        }
    }
    
    func panelDidOpen() {
        if let vc = panel as? Panelable & CreateGroupViewController {
            vc.panelDidOpen()
        }
    }
}
