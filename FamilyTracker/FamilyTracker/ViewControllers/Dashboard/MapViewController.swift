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
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var safetyStatusLbl: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var memberDetailsView: UIView!
    @IBOutlet weak var groupsNameLbl: UILabel!
    @IBOutlet weak var safetyGroupStatusLbl: UILabel!
    @IBOutlet weak var groupDetailsView: UIView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var previousButton: UIButton!

    private var ref: DatabaseReference!
    var memberList: [Members] = []
    var groupId: String = ""
    var groupName: String = ""
    var showAllGroupMembers = false
    var index: Int = 0
    var groupsCount: Int = 0
    var groupListHandler: ((_ index: Int) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        handleButtons()
        setUp(groupId: self.groupId)
    }
    
    func setUp(groupId: String) {
        ref = Database.database().reference(withPath: "groups/\(groupId)")
        mapView.delegate = self
        mapView.mapType = .standard
        
        memberDetailsView.isHidden = showAllGroupMembers
        if showAllGroupMembers {
            groupDetailsView.addTopShadow(shadowColor: UIColor.gray, shadowOpacity: 0.5, shadowRadius: 3, offset: CGSize(width: 0.0, height : -5.0))
            backButton.setTitle("Show List", for: .normal)
            groupsNameLbl.text = groupName
        } else {
            memberDetailsView.addTopShadow(shadowColor: UIColor.gray, shadowOpacity: 0.5, shadowRadius: 3, offset: CGSize(width: 0.0, height : -5.0))
            backButton.setTitle("Back", for: .normal)
            nameLbl.text = memberList[0].name
            showPinForMembersLocation()
        }
        observeFirebaseRealtimeDBChanges()
    }
    
    private func observeFirebaseRealtimeDBChanges() {
        //Observe updated value for member
        self.memberList.removeAll()
        self.ref.removeAllObservers()
        self.ref.child("/members").observe(.childChanged) { (snapshot) in
            if let value = snapshot.value as? NSMutableDictionary {
                self.familyMembersLocationUpdated(key: snapshot.key, value: value)
            }
        }
        
        if showAllGroupMembers {
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
        self.showPinForMembersLocation()
        
    }
    
    private func familyMemberRemoved(value: NSMutableDictionary) {
        
        var member = Members()
        member.id = value["id"] as? String
        if let index = self.memberList.firstIndex(where: { $0.id == member.id }) {
            self.memberList.remove(at: index)
            self.showPinForMembersLocation()
        }
    }
    
    func showPinForMembersLocation() {
        let allAnnotations = self.mapView.annotations
        self.mapView.removeAnnotations(allAnnotations)
        
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
    
    @IBAction func showListBtnAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func sosBtnAction(_ sender: Any) {

    }
    
    @IBAction func nextBtnAction(_ sender: Any) {
        index = index + 1
        groupListHandler?(index)
        handleButtons()
    }
    
    @IBAction func previousBtnAction(_ sender: Any) {
        index = index - 1
        groupListHandler?(index)
        handleButtons()
    }
    
    func handleButtons() {
        previousButton.isEnabled = !(index == 0)
        nextButton.isEnabled = !(index == groupsCount - 1)
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
