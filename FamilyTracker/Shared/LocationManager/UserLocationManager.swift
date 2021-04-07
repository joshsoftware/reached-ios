//
//  UserLocationManager.swift
//  FamilyTracker
//
//  Created by Vijay Godse on 08/03/21.
//

import CoreLocation

protocol LocationUpdateDelegate: class {
    func locationDidUpdateToLocation(location : CLLocation)
}

/// Notification on update of location. UserInfo contains CLLocation for key "location"
let kLocationDidChangeNotification = "LocationDidChangeNotification"
let kGroupFoundForCurrentUserNotification = "GroupFoundForCurrentUserNotification"

class UserLocationManager: NSObject, CLLocationManagerDelegate {

    static let shared = UserLocationManager()
    private var locationManager = CLLocationManager()
    var currentLocation : CLLocation?

    weak var delegate : LocationUpdateDelegate?
    
    private override init () {
        super.init()
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        #if os(iOS)
        locationManager.distanceFilter = 100
        #if targetEnvironment(simulator)
        locationManager.startUpdatingLocation()
        #else
        if CLLocationManager.significantLocationChangeMonitoringAvailable() {
            locationManager.startMonitoringSignificantLocationChanges()
        } else {
            locationManager.startUpdatingLocation()
        }
        #endif
        locationManager.pausesLocationUpdatesAutomatically = false

        #elseif os(watchOS)
        locationManager.distanceFilter = 30
        locationManager.startUpdatingLocation()
        #endif
    }
    
    private func geocode(latitude: Double, longitude: Double, completion: @escaping (CLPlacemark?, Error?) -> ())  {
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: latitude, longitude: longitude)) { completion($0?.first, $1) }
    }
    
    // MARK: - CLLocationManagerDelegate
    // Below Mehtod will print error if not able to update location.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error Location")
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        //Access the last object from locations to get perfect current location
        if let location = locations.last {
            
        
            let locationAge = -(location.timestamp.timeIntervalSinceNow)
            if locationAge > 5.0 {
                return
            }

            if location.horizontalAccuracy < 0 {
                return
            }
            
            if currentLocation == nil {
                currentLocation = location
            }
            
            let loc1 = CLLocation(latitude: currentLocation!.coordinate.latitude, longitude: currentLocation!.coordinate.longitude)
            let loc2 = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let distance = loc1.distance(from: loc2)


            if distance > 20 {
                currentLocation = location
                let userInfo : NSDictionary = ["location" : currentLocation!]
                
                if let delegate = self.delegate {
                    delegate.locationDidUpdateToLocation(location: self.currentLocation ?? location)
                } else {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: kLocationDidChangeNotification), object: self, userInfo: userInfo as [NSObject : AnyObject])
                }
            }
            
        }
    }
    
}
