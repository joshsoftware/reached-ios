//
//  SearchAddressViewController.swift
//  FamilyTracker
//
//  Created by Mahesh on 02/06/21.
//

import UIKit
import GooglePlaces
import MapKit

class SearchAddressViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!

    var resultsViewController: GMSAutocompleteResultsViewController?
    var searchController: UISearchController?
    var resultView: UITextView?
    var selectedPlace = Place()
    var groupId: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        resultsViewController = GMSAutocompleteResultsViewController()
        resultsViewController?.delegate = self
        
        searchController = UISearchController(searchResultsController: resultsViewController)
        searchController?.searchResultsUpdater = resultsViewController
        
        let subView = UIView(frame: CGRect(x: 0, y: 110.0, width: UIScreen.main.bounds.width, height: 50.0))
        
        subView.addSubview((searchController?.searchBar)!)
        view.addSubview(subView)
        searchController?.searchBar.sizeToFit()
        searchController?.hidesNavigationBarDuringPresentation = false
        searchController?.obscuresBackgroundDuringPresentation = false
        
        // When UISearchController presents the results view, present it in
        // this view controller, not one further up the chain.
        definesPresentationContext = true
        
        mapView.delegate = self
        mapView.mapType = .standard
    }
    
    @IBAction func nextBtnAction(_ sender: Any) {
        if let vc = UIStoryboard(name: "Profile", bundle: nil).instantiateViewController(withIdentifier: "SaveAddressViewController") as? SaveAddressViewController {
            vc.selectedPlace = self.selectedPlace
            vc.groupId = self.groupId
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func backBtnAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}

// Handle the user's selection.
extension SearchAddressViewController: GMSAutocompleteResultsViewControllerDelegate {
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didAutocompleteWith place: GMSPlace) {
        searchController?.isActive = false
        // Do something with the selected place.
        print("Place name: \(place.name)")
        print("Place address: \(place.formattedAddress)")
        print("Place attributions: \(place.attributions)")
        
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
    
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didFailAutocompleteWithError error: Error){
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(forResultsController resultsController: GMSAutocompleteResultsViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(forResultsController resultsController: GMSAutocompleteResultsViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}

extension SearchAddressViewController : MKMapViewDelegate {
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
