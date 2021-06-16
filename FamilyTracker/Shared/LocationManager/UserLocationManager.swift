//
//  UserLocationManager.swift
//  FamilyTracker
//
//  Created by Vijay Godse on 08/03/21.
//

import CoreLocation
import UserNotifications

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
    var geofenceRegion = CLCircularRegion()    //FOR GEOFENCE
    var notificationCenter: UNUserNotificationCenter?

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

//MARK: Geofencing methods

extension UserLocationManager {
    
    func generateGeofenceRegion(geotificationDataList: [Place])
    
    {
        for region in geotificationDataList
        {
            if let lat = region.lat, let long = region.long, let radius = region.radius, let id = region.id, let groupId = region.groupId {
                
                let geofenceRegionCenter = CLLocationCoordinate2DMake(lat, long);
                let identifier = [id, groupId].compactMap{ $0 }.joined(separator: "+")
                
                geofenceRegion = CLCircularRegion(
                    
                    center: geofenceRegionCenter,
                    
                    radius: CLLocationDistance(radius),
                    
                    identifier: identifier
                    
                );
                geofenceRegion.notifyOnExit = true;
                geofenceRegion.notifyOnEntry = true;
                #if os(iOS)
                self.locationManager.startMonitoring(for: geofenceRegion)
                #elseif os(watchOS)
                //TODO: Check if available
                #endif
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        self.handleEventForExitRegion(forRegion: region)
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        self.handleEventForEnterRegion(forRegion: region)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("didChangeAuthorization")
    }
    
    func locationManager(_ manager: CLLocationManager, didFinishDeferredUpdatesWithError error: Error?) {
        print("update failure \(String(describing: error))")
        
    }
    
    func handleEventForEnterRegion(forRegion region: CLRegion!) {
        print("Entered in region")
        let regionArray = region.identifier.components(separatedBy: "+")
        if let userId = UserDefaults.standard.string(forKey: "userId"), !regionArray.isEmpty {
            let addressId: String = regionArray[0]
            let groupId: String? = regionArray.count > 1 ? regionArray[1] : nil
            DatabaseManager.shared.updateTransitionFor(userWith: userId, groupId: groupId ?? "", addressId: addressId, transition: "enter")

        }
//        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "eventForEnterRegion"), object: nil, userInfo: ["region": region.identifier])
    }
    
    func handleEventForExitRegion(forRegion region: CLRegion!) {
        print("Exited from region")
        let regionArray = region.identifier.components(separatedBy: "+")
        if let userId = UserDefaults.standard.string(forKey: "userId"), !regionArray.isEmpty {
            let addressId: String = regionArray[0]
            let groupId: String? = regionArray.count > 1 ? regionArray[1] : nil
            DatabaseManager.shared.updateTransitionFor(userWith: userId, groupId: groupId ?? "", addressId: addressId, transition: "exit")

        }
//        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "eventForExitRegion"), object: nil, userInfo: ["region": region.identifier])
    }
}
