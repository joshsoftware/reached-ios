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
    
    @IBOutlet weak var scannerContainerView: UIView!
    @IBOutlet weak var scannerView: QRScannerView!
    
    private var ref: DatabaseReference!
    var currentLocation : CLLocationCoordinate2D = CLLocationCoordinate2D()
    let groupId = UUID().uuidString
    let locationManager = CLLocationManager()
    var currentUserProfileUrl: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scannerContainerView.isHidden = true
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
        if !scannerView.isRunning {
            scannerView.stopScanning()
        }
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
        if let userId = UserDefaults.standard.string(forKey: "userId"), let name = UserDefaults.standard.string(forKey: "userName") {
            let data = ["id":userId, "lat": self.currentLocation.latitude, "long": self.currentLocation.longitude, "name": name, "profileUrl": self.currentUserProfileUrl ?? ""] as [String : Any]
            var memberArray : Array = Array<Any>()
            memberArray.append(data)
            self.ref.child("groups").child(self.groupId).setValue(["created_by": userId, "members": memberArray])
        }
        UserDefaults.standard.setValue(self.groupId, forKey: "groupId")
        navigateToShowQRCodeVC(groupId: self.groupId)
    }
    
    @IBAction func joinbuttonPressed(_ sender: Any) {
        
        scannerContainerView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        scannerContainerView.isHidden = false
        scannerView.delegate = self
        if !scannerView.isRunning {
            scannerView.startScanning()
        }
    }

    private func navigateToShowQRCodeVC(groupId: String) {
        if let vc = UIStoryboard.sharedInstance.instantiateViewController(withIdentifier: "ShowQRCodeViewController") as? ShowQRCodeViewController {
            vc.groupId = groupId
            vc.iIsFromCreateGroupFlow = true
            self.navigationController?.pushViewController(vc, animated: false)
        }
    }
}

extension HomeViewController: QRScannerViewDelegate {
    func qrScanningDidStop() {
        dismissScannerView()
    }
    
    func qrScanningDidFail() {
        dismissScannerView()
        presentAlert(withTitle: "Error", message: "Scanning Failed. Please try again", completion: {
            
        })
    }
    
    func qrScanningSucceededWithCode(_ str: String?) {
        var memberArray : Array = Array<Any>()
        var createdBy: String?
        
        self.ref.child("groups/\(str ?? "")").getData { (error, snapshot) in
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
                
//                //TEMP ADDED USER DATA
//                let testData = ["id":"1234", "lat": self.currentLocation.coordinate.latitude, "long": self.currentLocation.coordinate.longitude, "name": "Test"] as [String : Any]
//                memberArray.append(testData)
                
                self.ref = Database.database().reference(withPath: "groups/\(str ?? "")")
                self.ref.setValue(["created_by": createdBy ?? "", "members": memberArray])

                DispatchQueue.main.async {
                    if let vc = UIStoryboard.sharedInstance.instantiateViewController(withIdentifier: "MemberListViewController") as? MemberListViewController {
                        vc.groupId = str ?? ""
                        self.navigationController?.pushViewController(vc, animated: false)
                    }
                }
            }
            else {
                print("No data available")
            }
        }
        dismissScannerView()
    }
    
    @IBAction func closeScannerViewButtonPressed(_ sender: Any) {
        dismissScannerView()
    }
    
    private func dismissScannerView() {
        scannerContainerView.isHidden = true
    }
    
}

extension UIViewController {
    
    func presentAlert(withTitle title: String, message : String, completion: @escaping () -> ()) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { action in
            print("You've pressed OK Button")
            completion()
        }
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)
    }
    func showToast(message : String, seconds: Double = 2.0) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.view.backgroundColor = UIColor.black
        alert.view.alpha = 0.6
        alert.view.layer.cornerRadius = 15
        
        self.present(alert, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + seconds) {
            alert.dismiss(animated: true)
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

extension UIApplication {

    class func getTopViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {

        if let nav = base as? UINavigationController {
            return getTopViewController(base: nav.visibleViewController)

        } else if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return getTopViewController(base: selected)

        } else if let presented = base?.presentedViewController {
            return getTopViewController(base: presented)
        }
        return base
    }
}
