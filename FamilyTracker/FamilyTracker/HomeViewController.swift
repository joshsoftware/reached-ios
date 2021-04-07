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
        
    private var ref: DatabaseReference!
    var currentLocation : CLLocationCoordinate2D = CLLocationCoordinate2D()
    let groupId = UUID().uuidString
    let locationManager = CLLocationManager()
    var currentUserProfileUrl: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    @IBAction func createGroupButtonPressed(_ sender: Any) {            CreateGroupPopUpVC.showPopup(parentVC: self)
        CreateGroupPopUpVC.groupCreatedHandler = { groupId in
            print("Group created..\(groupId)")
            UserDefaults.standard.setValue(groupId, forKey: "groupId")
            self.navigateToShowQRCodeVC(groupId: groupId)
        }
    }
    
    @IBAction func joinbuttonPressed(_ sender: Any) {
        
        ScanQRCodeViewController.showPopup(parentVC: self)
        ScanQRCodeViewController.groupJoinedHandler = { qrString in
            self.qrScanningSucceededWithCode(qrString: qrString)
        }
    }

    private func navigateToShowQRCodeVC(groupId: String) {
        if let vc = UIStoryboard.sharedInstance.instantiateViewController(withIdentifier: "ShowQRCodeViewController") as? ShowQRCodeViewController {
            vc.groupId = groupId
            vc.iIsFromCreateGroupFlow = true
            vc.currentUserProfileUrl = currentUserProfileUrl
            self.navigationController?.pushViewController(vc, animated: false)
        }
    }
    
    func qrScanningSucceededWithCode(qrString: String?) {
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
                
                DispatchQueue.main.async {
                    if let vc = UIStoryboard.sharedInstance.instantiateViewController(withIdentifier: "GroupListViewController") as? GroupListViewController {
                        vc.currentUserProfileUrl = self.currentUserProfileUrl
                        self.navigationController?.pushViewController(vc, animated: false)
                    }
                }
            }
            else {
                print("No data available")
            }
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
