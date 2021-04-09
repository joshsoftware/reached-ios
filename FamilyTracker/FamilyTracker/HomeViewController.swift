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
    
    @IBAction func createGroupButtonPressed(_ sender: Any) {
        CreateGroupPopUpVC.currentUserProfileUrl = self.currentUserProfileUrl ?? ""
        CreateGroupPopUpVC.showPopup(parentVC: self)
        CreateGroupPopUpVC.groupCreatedHandler = { groupId in
            print("Group created..\(groupId)")
            self.navigateToShowQRCodeVC(groupId: groupId)
        }
    }
    
    @IBAction func joinbuttonPressed(_ sender: Any) {
        ScanQRCodeViewController.showPopup(parentVC: self)
        ScanQRCodeViewController.groupJoinedHandler = { qrString in
            DatabaseManager.shared.joinToGroupWith(groupId: qrString, currentLocation: self.currentLocation, profileUrl: self.currentUserProfileUrl ?? "") {
                if let vc = UIStoryboard.sharedInstance.instantiateViewController(withIdentifier: "GroupListViewController") as? GroupListViewController {
                    vc.currentUserProfileUrl = self.currentUserProfileUrl
                    self.navigationController?.pushViewController(vc, animated: false)
                }
            }
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
}

extension HomeViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        self.currentLocation = locValue
    }
}
