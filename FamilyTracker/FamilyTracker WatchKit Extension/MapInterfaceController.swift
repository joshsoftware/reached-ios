//
//  MapInterfaceController.swift
//  FamilyTracker
//
//  Created by Vijay Godse on 03/03/21.
//

import WatchKit
import Foundation
import MapKit
import WatchConnectivity
import Contacts
import FirebaseDatabase

class MapInterfaceController: WKInterfaceController, NibLoadableViewController {
    
    @IBOutlet weak var mapView: WKInterfaceMap!
    @IBOutlet weak var namelabel: WKInterfaceLabel!
    @IBOutlet weak var addressLabel: WKInterfaceLabel!
    
    private var connectivityHandler = WatchSessionManager.shared
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

                    var region = MKCoordinateRegion()
                    region.center = coordinate
                    region.span.latitudeDelta = 0.04
                    region.span.longitudeDelta = 0.04
                    self.mapView.setRegion(region)
                    
                    if itemList.count == 1 {
                        namelabel.setText(item.name)
                        let location = CLLocation(latitude: latitude, longitude: longitude)
                        CLGeocoder().reverseGeocodeLocation(location, preferredLocale: nil) { (clPlacemark: [CLPlacemark]?, error: Error?) in
                            guard let place = clPlacemark?.first else {
                                print("No placemark from Apple: \(String(describing: error))")
                                return
                            }

                            let postalAddressFormatter = CNPostalAddressFormatter()
                            postalAddressFormatter.style = .mailingAddress
                            var addressString: String?
                            if let postalAddress = place.postalAddress {
                                addressString = postalAddressFormatter.string(from: postalAddress)
                                self.addressLabel.setText(addressString)
                            }
                        }
                    }
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
        connectivityHandler.startSession()
        connectivityHandler.watchOSDelegate = self
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

        if let index = self.itemList.firstIndex(where: { $0.id == member.id }) {
            self.itemList[index] = member
        }
    }
    
   
}

extension MapInterfaceController: WatchOSDelegate {
    
    func applicationContextReceived(tuple: ApplicationContextReceived) {
    }
    
    
    func messageReceived(tuple: MessageReceived) {
        DispatchQueue.main.async() {
            WKInterfaceDevice.current().play(.notification)
            if let loginStatus = tuple.message["loginStatus"] as? Bool {
                UserDefaults.standard.setValue(loginStatus, forKey: "loginStatus")
                if !loginStatus {
                    //TODO
                    self.popToRootController()
                }
            }
            
        }
    }
    
}

