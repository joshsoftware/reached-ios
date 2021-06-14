//
//  HomeViewController.swift
//  FamilyTracker
//
//  Created by Mahesh on 16/03/21.
//

import UIKit
import Firebase
import CoreLocation

class HomeViewController: UIViewController {
    @IBOutlet var topView: UIView!
    @IBOutlet var textField: UITextField!
    @IBOutlet var groupNameView: UIView!

    
    private var ref: DatabaseReference!
    var currentLocation : CLLocationCoordinate2D = CLLocationCoordinate2D()
    let groupId = UUID().uuidString
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        setUpLocationManager()
        self.navigationItem.setHidesBackButton(true, animated: true)
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        topView.roundBottom(radius: 10)
    }
    
    func showCreateGroupView(flag: Bool) {
        if flag {
            self.textField.text = ""
            self.textField.becomeFirstResponder()
        } else {
            self.textField.endEditing(true)
        }
        self.groupNameView.isHidden = !flag
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
        self.showCreateGroupView(flag: true)
    }
    
    @IBAction func createGroupButtonDonePressed(_ sender: Any) {
        if self.textField.text!.count > 0 {
            self.showCreateGroupView(flag: false)
            self.createGroup(groupName: textField.text ?? "My Group")
        }
    }
    
    @IBAction func joinbuttonPressed(_ sender: Any) {
        ScanQRCodeViewController.showPopup(parentVC: self)
        ScanQRCodeViewController.groupJoinedHandler = { qrString in
            DatabaseManager.shared.joinToGroupWith(groupId: qrString, currentLocation: self.currentLocation) {
                if let vc = UIStoryboard.dashboardSharedInstance.instantiateViewController(withIdentifier: "MainViewController") as? MainViewController {
                    self.navigationController?.pushViewController(vc, animated: false)
                }
            }
        }
    }

    private func navigateToShowQRCodeVC(groupId: String, groupName: String) {
        if let vc = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "ShowQRCodeViewController") as? ShowQRCodeViewController {
            vc.groupId = groupId
            vc.groupName = groupName
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func createGroup(groupName: String) {
        ProgressHUD.sharedInstance.show()
        if let userId = UserDefaults.standard.string(forKey: "userId") {
            let data = ["lat": self.currentLocation.latitude, "long": self.currentLocation.longitude, "name": "Mahesh Nagpure", "lastUpdated": Date().currentUTCDate(), "profileUrl": "https://homepages.cae.wisc.edu/~ece533/images/airplane.png"] as [String : Any]
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
            ProgressHUD.sharedInstance.hide()
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

extension HomeViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.showCreateGroupView(flag: false)
        return true
    }
}
