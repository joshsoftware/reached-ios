//
//  CreateGroupPopUpVC.swift
//  FamilyTracker
//
//  Created by Mahesh on 07/04/21.
//

import UIKit
import Firebase
import CoreLocation

class CreateGroupPopUpVC: UIViewController {

    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var popupViewCenterYConstraint: NSLayoutConstraint!
    
    private var ref: DatabaseReference!
    var currentLocation = CLLocationCoordinate2D()
    let groupId = UUID().uuidString
    let locationManager = CLLocationManager()
    static var groupCreatedHandler: ((_ groupId: String, _ groupName: String) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        setUpLocationManager()
        popupView.layer.cornerRadius = 6.0
        // Do any additional setup after loading the view.
    }

    @IBAction func cancelButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func createButtonPressed(_ sender: Any) {
        if textField.text?.count ?? 0 > 0 {
            createGroup(groupName: textField.text ?? "My Group")
        } else {
            print("Enter group name..")
        }
    }
    
    static func showPopup(parentVC: UIViewController){
        let  vc =  CreateGroupPopUpVC(nibName:"CreateGroupPopUpVC", bundle:Bundle.main)
        vc.modalPresentationStyle = .custom
        vc.modalTransitionStyle = .crossDissolve
        parentVC.present(vc, animated: true)
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
    
    func createGroup(groupName: String) {
        if let userId = UserDefaults.standard.string(forKey: "userId") {
            let data = ["lat": self.currentLocation.latitude, "long": self.currentLocation.longitude, "name": "Mahesh Nagpure", "lastUpdated": Date().currentUTCDate(), "profileUrl": "https://lh6.googleusercontent.com/-QfO37tyTDL0/AAAAAAAAAAI/AAAAAAAAAAA/AMZuucnWQWmDWdCnDpyhjy4kQFlUHWKEgA/s96-c/photo.jpg", "sosState": false] as [String : Any]
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
            self.dismiss(animated: true, completion: {
                CreateGroupPopUpVC.self.groupCreatedHandler?(self.groupId, groupName)
            })
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension CreateGroupPopUpVC: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.3, animations: {
            self.popupViewCenterYConstraint.constant = -100
            self.view.layoutIfNeeded()
        })
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.3, animations: {
            self.popupViewCenterYConstraint.constant = 0
            self.view.layoutIfNeeded()
        })
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
    }
}

extension CreateGroupPopUpVC: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        self.currentLocation = locValue
    }
}
