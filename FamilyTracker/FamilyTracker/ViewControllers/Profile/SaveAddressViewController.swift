//
//  SaveAddressViewController.swift
//  FamilyTracker
//
//  Created by Mahesh on 02/06/21.
//

import UIKit
import CoreLocation
import MapKit

class SaveAddressViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var mapViewbg: UIView!
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var workButton: UIButton!
    @IBOutlet weak var otherTextField: UITextField!

    var selectedPlace = Place()
    var groupId: String = ""
    var userId: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        mapView.mapType = .standard
        mapViewbg.setShadowToAllSides()
        
        addressLabel.text = selectedPlace.address
        
        let pin = MKPointAnnotation()
        pin.coordinate = CLLocationCoordinate2D(latitude: selectedPlace.lat!, longitude: selectedPlace.long!)
        self.mapView.addAnnotation(pin)
        
        if let latitudinalMeters = CLLocationDistance(exactly: 500), let longitudinalMeters = CLLocationDistance(exactly: 500) {
            let region = MKCoordinateRegion( center: CLLocationCoordinate2D(latitude: selectedPlace.lat!, longitude: selectedPlace.long!), latitudinalMeters: latitudinalMeters, longitudinalMeters: longitudinalMeters)
            self.mapView.setRegion(self.mapView.regionThatFits(region), animated: true)
        }
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func saveBtnAction(_ sender: Any) {
        let value = ["name": self.selectedPlace.name ?? "", "lat": self.selectedPlace.lat ?? 0, "long": self.selectedPlace.long ?? 0, "address": self.selectedPlace.address ?? "", "radius": 200, "transition": "exit"] as [String : Any]
        DatabaseManager.shared.addAddress(userId: self.userId, groupId: self.groupId, placeData: value)
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "fetchAddressNotification"), object: nil)

        self.navigationController?.popToViewController(ofClass: ProfileViewController.self)
    }
    
    @IBAction func homeBtnAction(_ sender: Any) {
        self.homeButton.isSelected = true
        self.workButton.isSelected = false
        self.selectedPlace.name = "Home"
    }
    
    @IBAction func workBtnAction(_ sender: Any) {
        self.homeButton.isSelected = false
        self.workButton.isSelected = true
        self.selectedPlace.name = "Work"
    }
    
    @IBAction func otherBtnAction(_ sender: Any) {
        self.homeButton.isSelected = false
        self.workButton.isSelected = false
        self.selectedPlace.name = self.otherTextField.text
        
        let value = ["name": self.selectedPlace.name ?? "", "lat": self.selectedPlace.lat ?? 0, "long": self.selectedPlace.long ?? 0, "address": self.selectedPlace.address ?? "", "radius": 200, "transition": "exit"] as [String : Any]
        DatabaseManager.shared.addAddress(userId: self.userId, groupId: self.groupId, placeData: value)
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "fetchAddressNotification"), object: nil)

        self.navigationController?.popToViewController(ofClass: ProfileViewController.self)
    }
    
    @IBAction func backBtnAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func sosBtnAction(_ sender: Any) {
        if let userId = UserDefaults.standard.string(forKey: "userId"), !userId.isEmpty {
            DatabaseManager.shared.updateSOSFor(userWith: userId, sosState: true)
        } else {
            print("User is not logged in")
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

extension SaveAddressViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else { return nil }

        let identifier = "Annotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }
        annotationView?.centerOffset = CGPoint(x: 0, y: -40)
        annotationView?.image = UIImage(named: "pin_with_profile_pic")

        return annotationView
    }
    
}

extension SaveAddressViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
    }
}
