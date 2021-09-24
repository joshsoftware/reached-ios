//
//  SearchAddressViewController.swift
//  FamilyTracker
//
//  Created by Mahesh on 02/06/21.
//

import UIKit
import GooglePlaces
import MapKit
import SDWebImage

class SearchAddressViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    var centerPin: UIImageView!

    var tableDataSource: GMSAutocompleteTableDataSource!
    var resultView: UITextView?
    var selectedPlace = Place()
    var groupId: String = ""
    var userId: String = ""
    var profileUrl: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableDataSource = GMSAutocompleteTableDataSource()
        tableDataSource.delegate = self
        tableView.delegate = tableDataSource
        tableView.dataSource = tableDataSource
        mapView.delegate = self
        mapView.mapType = .standard
        mapView.showsUserLocation = true
        if let userLocation = UserLocationManager.shared.currentLocation?.coordinate {
            let viewRegion = MKCoordinateRegion(center: userLocation, latitudinalMeters: 1000, longitudinalMeters: 1000)
            mapView.setRegion(viewRegion, animated: false)
        }
        DatabaseManager.shared.getVersion { (flag) in
            self.showSearchBar(flag: flag ?? false)
        }
    }
    
    func setupCenterPin() {
        self.centerPin = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 40))
        self.centerPin.image = UIImage(named: "pin_Icon")
        self.centerPin.center = self.mapView.center
        self.view.addSubview(self.centerPin)
        self.centerPin.bringSubviewToFront(self.mapView)
    }
    
    func showSearchBar(flag: Bool) {
        self.searchBar.isHidden = !flag
        if !flag {
            setupCenterPin()
        }
    }
    
    @IBAction func nextBtnAction(_ sender: Any) {
        if self.centerPin == nil {
            if let vc = UIStoryboard(name: "Profile", bundle: nil).instantiateViewController(withIdentifier: "SaveAddressViewController") as? SaveAddressViewController {
                vc.selectedPlace = self.selectedPlace
                vc.userId = self.userId
                vc.groupId = self.groupId
                vc.profileUrl = self.profileUrl
                self.navigationController?.pushViewController(vc, animated: true)
            }
        } else {
            if let lat = selectedPlace.lat, let long =  selectedPlace.long {
                let location = CLLocation(latitude: lat, longitude: long)
                location.getAddress { (address) in
                    self.selectedPlace.address = address
                    if let vc = UIStoryboard(name: "Profile", bundle: nil).instantiateViewController(withIdentifier: "SaveAddressViewController") as? SaveAddressViewController {
                        vc.selectedPlace = self.selectedPlace
                        vc.userId = self.userId
                        vc.groupId = self.groupId
                        vc.profileUrl = self.profileUrl
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                }
            }
        }
    }
    
    @IBAction func backBtnAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func sosBtnAction(_ sender: Any) {
        if let userId = UserDefaults.standard.string(forKey: "userId"), !userId.isEmpty {
            ProgressHUD.sharedInstance.show()
            DatabaseManager.shared.updateSOSFor(userWith: userId, sosState: true, completion: { response, error in
                ProgressHUD.sharedInstance.hide()
                if let err = error {
                    print(err)
                } else {
                    print("SOS updated....")
                }
            })
        } else {
            print("User is not logged in")
        }
    }
}

extension SearchAddressViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // Update the GMSAutocompleteTableDataSource with the search text.
        tableView.isHidden = !(searchText.count > 0)
        tableDataSource.sourceTextHasChanged(searchText)
    }
}

extension SearchAddressViewController: GMSAutocompleteTableDataSourceDelegate {
    func didUpdateAutocompletePredictions(for tableDataSource: GMSAutocompleteTableDataSource) {
        // Turn the network activity indicator off.
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        // Reload table data.
        tableView.reloadData()
    }
    
    func didRequestAutocompletePredictions(for tableDataSource: GMSAutocompleteTableDataSource) {
        // Turn the network activity indicator on.
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        // Reload table data.
        tableView.reloadData()
    }
    
    func tableDataSource(_ tableDataSource: GMSAutocompleteTableDataSource, didAutocompleteWith place: GMSPlace) {
        // Do something with the selected place.
        print("Place name: \(place.name)")
        print("Place address: \(place.formattedAddress)")
        print("Place attributions: \(place.attributions)")
        
        self.tableView.isHidden = true

        let allAnnotations = self.mapView.annotations
        self.mapView.removeAnnotations(allAnnotations)
        
        let pin = MKPointAnnotation()
        pin.coordinate = place.coordinate
        pin.title = place.formattedAddress
        self.mapView.addAnnotation(pin)
        
        self.selectedPlace.address = place.formattedAddress
        self.selectedPlace.lat = place.coordinate.latitude
        self.selectedPlace.long = place.coordinate.longitude
        
        if let latitudinalMeters = CLLocationDistance(exactly: 500), let longitudinalMeters = CLLocationDistance(exactly: 500) {
            let region = MKCoordinateRegion( center: place.coordinate, latitudinalMeters: latitudinalMeters, longitudinalMeters: longitudinalMeters)
            self.mapView.setRegion(self.mapView.regionThatFits(region), animated: true)
        }
        
    }
    
    func tableDataSource(_ tableDataSource: GMSAutocompleteTableDataSource, didFailAutocompleteWithError error: Error) {
        // Handle the error.
        print("Error: \(error.localizedDescription)")
    }
    
    func tableDataSource(_ tableDataSource: GMSAutocompleteTableDataSource, didSelect prediction: GMSAutocompletePrediction) -> Bool {
        return true
    }
}

extension SearchAddressViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else { return nil }
        
        let identifier = "AnnotationIdentifier"
        
        var view: CustomAnnotationView? = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? CustomAnnotationView
        if view == nil {
            view = CustomAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }
        
        view?.profileImageView.sd_setImage(with: URL(string: self.profileUrl), placeholderImage: UIImage(named: "userPlaceholder"))
        
        view?.centerOffset = CGPoint(x: 0, y: -35)
        return view
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = mapView.centerCoordinate
        self.selectedPlace.lat = center.latitude
        self.selectedPlace.long = center.longitude
        print(center)
    }
    
}
