//
//  MapViewController.swift
//  FamilyTracker
//
//  Created by Vijay Godse on 02/03/21.
//

import UIKit
import Firebase
import MapKit
import Contacts

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    private var ref: DatabaseReference!
    var memberList: [Members] = []
    var groupId: String = ""
    var toShowAllGroupMembers = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
    }
    
    private func setUp() {
        ref = Database.database().reference(withPath: "groups/\(groupId)")
        mapView.delegate = self
        mapView.mapType = .standard
        showPinForMembersLocation()
        observeFirebaseRealtimeDBChanges()
    }
    
    private func observeFirebaseRealtimeDBChanges() {
        //Observe updated value for member
        self.ref.child("/members").observe(.childChanged) { (snapshot) in
            if let value = snapshot.value as? NSMutableDictionary {
                self.familyMembersLocationUpdated(key: snapshot.key, value: value)
            }
        }
        
        if toShowAllGroupMembers {
            //Observe newly added member
            self.ref.child("/members").observe(.childAdded) { (snapshot) in
                if let value = snapshot.value as? NSMutableDictionary {
                    self.newFamilyMemberAdded(key: snapshot.key, value: value)
                }
            }
            
            //Observe family member removed
            self.ref.child("/members").observe(.childRemoved) { (snapshot) in
                if let value = snapshot.value as? NSMutableDictionary {
                    self.familyMemberRemoved(value: value)
                }
            }
        }
    }
    
    private func familyMembersLocationUpdated(key: String, value: NSMutableDictionary) {
        var member = Members()
        member.id = key
        member.lat = value["lat"] as? Double
        member.long = value["long"] as? Double
        member.name = value["name"] as? String
        member.profileUrl = value["profileUrl"] as? String
        member.lastUpdated = value["lastUpdated"] as? String
        member.sosState = value["sosState"] as? Bool

        if let index = self.memberList.firstIndex(where: {
                                                    $0.id == member.id }) {
            let allAnnotations = self.mapView.annotations
            self.mapView.removeAnnotations(allAnnotations)
            self.memberList[index] = member
            self.showPinForMembersLocation()
        }
    }
    
    private func newFamilyMemberAdded(key: String, value: NSMutableDictionary) {
        
        var member = Members()
        member.id = key
        member.lat = value["lat"] as? Double
        member.long = value["long"] as? Double
        member.name = value["name"] as? String
        member.profileUrl = value["profileUrl"] as? String
        member.lastUpdated = value["lastUpdated"] as? String
        member.sosState = value["sosState"] as? Bool
        self.memberList.append(member)
        let allAnnotations = self.mapView.annotations
        self.mapView.removeAnnotations(allAnnotations)
        self.showPinForMembersLocation()
        
    }
    
    private func familyMemberRemoved(value: NSMutableDictionary) {
        
        var member = Members()
        member.id = value["id"] as? String
        if let index = self.memberList.firstIndex(where: { $0.id == member.id }) {
            self.memberList.remove(at: index)
            let allAnnotations = self.mapView.annotations
            self.mapView.removeAnnotations(allAnnotations)
            self.showPinForMembersLocation()
        }
    }
    
    func showPinForMembersLocation() {
        for index in 0..<memberList.count {
            let item = memberList[index]
            
            if let latitude = item.lat,  let longitude = item.long {
                
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                
                let pin = MKPointAnnotation()
                pin.title = item.name ?? ""
                
                let location = CLLocation(latitude: latitude, longitude: longitude)
                location.fetchCityAndCountry { (name, city, error) in
                    if error == nil {
                        pin.subtitle = (name ?? "") + ", " + (city ?? "")
                    }
                }
                
                pin.coordinate = coordinate
                self.mapView.addAnnotation(pin)

                if let latitudinalMeters = CLLocationDistance(exactly: 500), let longitudinalMeters = CLLocationDistance(exactly: 500) {
                    let region = MKCoordinateRegion( center: coordinate, latitudinalMeters: latitudinalMeters, longitudinalMeters: longitudinalMeters)
                    self.mapView.setRegion(self.mapView.regionThatFits(region), animated: true)
                }
            }
            
        }
        
        if memberList.count > 1 {
            self.mapView.showAnnotations(self.mapView.annotations, animated: true)
        }

    }
    
}

extension MapViewController : MKMapViewDelegate {
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

        return annotationView
    }
    
}
