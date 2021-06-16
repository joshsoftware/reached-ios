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
    }
    
    @IBAction func nextBtnAction(_ sender: Any) {
        if let vc = UIStoryboard(name: "Profile", bundle: nil).instantiateViewController(withIdentifier: "SaveAddressViewController") as? SaveAddressViewController {
            vc.selectedPlace = self.selectedPlace
            vc.userId = self.userId
            vc.groupId = self.groupId
            vc.profileUrl = self.profileUrl
            self.navigationController?.pushViewController(vc, animated: true)
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
    
}
