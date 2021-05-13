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
    private var refGeofencing: DatabaseReference!
    var memberList: [Members] = []
    var groupId: String = ""
    var arrGeoFenceData = [GeotificationData]()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
    }
    
    private func setUp() {
        ref = Database.database().reference(withPath: "groups/\(groupId)")
        refGeofencing = Database.database().reference(withPath: "groups/\(self.groupId)/geofencing")

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
        
        //Observe updated value for geofencing
        self.refGeofencing.observe(.childChanged) { (snapshot) in
            if let value = snapshot.value as? NSMutableDictionary {
                self.geoFencingUpdated(value: value)
            }
        }
        
        self.refGeofencing.observe(.childAdded) { (snapshot) in
            if let value = snapshot.value as? NSMutableDictionary {
                self.geoFencingAdded(value: value)
            }
        }
        
        self.refGeofencing.observe(.childRemoved) { (snapshot) in
            if let value = snapshot.value as? NSMutableDictionary {
                self.geoFencingUpdated(value: value, isRemoved: true)
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
    
    private func geoFencingUpdated(value: NSMutableDictionary, isRemoved: Bool = false) {
        var data = GeotificationData()
        data.lat = value["lat"] as? Double
        data.long = value["long"] as? Double
        data.name = value["name"] as? String
        data.radius = value["radius"] as? Double

        if let index = self.arrGeoFenceData.firstIndex(where: {
                                                    $0.name == data.name }) {
            if isRemoved {
                self.arrGeoFenceData.remove(at: index)
            } else {
                self.arrGeoFenceData[index] = data
            }
            self.getGeoFencing()
        }
    }
    
    private func geoFencingAdded(value: NSMutableDictionary) {
        var data = GeotificationData()
        data.lat = value["lat"] as? Double
        data.long = value["long"] as? Double
        data.name = value["name"] as? String
        data.radius = value["radius"] as? Double
        self.arrGeoFenceData.append(data)
        self.getGeoFencing()
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
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
           guard let circleOverlay = overlay as? MKCircle else {
            return MKOverlayRenderer()
           }
           let circleRender = MKCircleRenderer(circle: circleOverlay)
           circleRender.strokeColor = .blue
           circleRender.fillColor = .blue
           circleRender.alpha = 0.1
           return circleRender
       }
    
}

//Geofencing methods
extension MapViewController {
    //show notification
    
    func showNotification(title:String, message:String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.badge = 1
        content.sound = .default
        let request = UNNotificationRequest(identifier: "notifi", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    func monitorRegionAtLocation(center: CLLocationCoordinate2D, identifier: String, radius: Double ) {
        // Make sure the devices supports region monitoring.
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            // Register the region.
            let maxDistance = CLLocationDistance(radius)
            let region = CLCircularRegion(center: center,
                                          radius: maxDistance, identifier: identifier)
            region.notifyOnEntry = true
            region.notifyOnExit = false
            let circle = MKCircle(center: center, radius: maxDistance)
            mapView.addOverlay(circle)
            
        }
    }
    
    
    private func getGeoFencing() {
        let locationManager = UserLocationManager.shared
        locationManager.generateGeofenceRegion(geotificationDataList: arrGeoFenceData)
        
        for item in arrGeoFenceData {
            if let lat = item.lat, let long = item.long, let radius = item.radius {
                print("Your location with lat and long :- \(item)")
                let cordi = CLLocationCoordinate2D(latitude: lat, longitude: long)
                monitorRegionAtLocation(center: cordi, identifier: "Geofence", radius: radius)
            }
        }
    }
    
    private func render(_ location: CLLocation) {
        let coordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mapView.setRegion(region, animated: true)
        mapView.showsUserLocation = true
    }
}
