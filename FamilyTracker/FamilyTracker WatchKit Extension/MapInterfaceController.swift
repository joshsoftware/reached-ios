//
//  MapInterfaceController.swift
//  FamilyTracker
//
//  Created by Vijay Godse on 03/03/21.
//

import WatchKit
import Foundation
import MapKit
import Contacts
import FirebaseDatabase

class MapInterfaceController: WKInterfaceController, NibLoadableViewController {
    
    @IBOutlet weak var mapView: WKInterfaceMap!
    @IBOutlet weak var namelabel: WKInterfaceLabel!
    @IBOutlet weak var addressLabel: WKInterfaceLabel!
    
    private var ref: DatabaseReference!
    private var selectedGroup: Group?
    
    var itemList: [Members] = [] {
        didSet {
            for index in 0..<itemList.count {
                let item = itemList[index]
                
                if let latitude = item.lat,  let longitude = item.long {
                    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    self.mapView.addAnnotation(coordinate, with: WKInterfaceMapPinColor.red)
//                    if #available(watchOSApplicationExtension 6.1, *) {
//                        self.mapView.setUserTrackingMode(.follow, animated: true)
//                        self.mapView.setShowsUserHeading(true)
//                        self.mapView.setShowsUserLocation(true)
//                    } else {
//                        // Fallback on earlier versions
//                    }
 
                    if itemList.count == 1 {
                        namelabel.setText(item.name)
                        
                        let location = CLLocation(latitude: latitude, longitude: longitude)
                        location.fetchCityAndCountry { (name, city, error) in
                            if error == nil {
                                self.addressLabel.setText((name ?? "") + ", " + (city ?? ""))
                            }
                        }
                        
                    }
                    
                    var region = MKCoordinateRegion()
                    region.center = coordinate
                    region.span.latitudeDelta = 0.04
                    region.span.longitudeDelta = 0.04
                    self.mapView.setRegion(region)
                   
                }
                
            }
        }
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        guard let (membersList, selectedGroup) = context as? ([Members], Group) else {
            return
        }
        self.selectedGroup = selectedGroup
        self.setUp()
        self.itemList.removeAll()
        self.itemList = membersList
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    private func setUp() {
        if let selectedGroup = self.selectedGroup, let groupId = selectedGroup.id {
            ref = Database.database().reference(withPath: "groups/\(groupId)")
            observeFirebaseRealtimeDBChanges()
        }

    }
    
    private func observeFirebaseRealtimeDBChanges() {
        //Observe updated value for member
        self.ref.child("/members").observe(.childChanged) { (snapshot) in
            if let value = snapshot.value as? NSMutableDictionary {
                self.mapView.removeAllAnnotations()
                self.familyMembersLocationUpdated(key: snapshot.key, value: value)
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

        if let index = self.itemList.firstIndex(where: { $0.id == member.id }) {
            self.itemList[index] = member
        }
    }
    
   
}


