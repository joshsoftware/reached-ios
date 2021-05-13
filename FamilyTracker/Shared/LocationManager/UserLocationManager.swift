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

class UserLocationManager: NSObject, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {

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
        
        // get the singleton object

        self.notificationCenter = UNUserNotificationCenter.current()

        // register as it's delegate

        notificationCenter?.delegate = self

        // define what do you need permission to use

        let options: UNAuthorizationOptions = [.alert, .sound]

        // request permission

        notificationCenter?.requestAuthorization(options: options) { (granted, error) in

            if !granted {

                print("Permission not granted")

            }

        }

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
    
    func generateGeofenceRegion(geotificationDataList: [GeotificationData])
    
    {
        
//        geofenceRegion.notifyOnExit = true
//        
//        geofenceRegion.notifyOnEntry = true;
        
        for region in geotificationDataList
        
        {
            
            if let lat = region.lat, let long = region.long, let radius = region.radius {
                
                let geofenceRegionCenter = CLLocationCoordinate2DMake(lat, long);
                
                geofenceRegion = CLCircularRegion(
                    
                    center: geofenceRegionCenter,
                    
                    radius: CLLocationDistance(radius),
                    
                    identifier:region.name ?? ""
                    
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
        if region is CLCircularRegion {
            // Do what you want if this information
            self.handleEventForExitRegion(forRegion: region)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region is CLCircularRegion {
            // Do what you want if this information
            self.handleEventForEnterRegion(forRegion: region)
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("didChangeAuthorization")
    }
    
    func locationManager(_ manager: CLLocationManager, didFinishDeferredUpdatesWithError error: Error?) {
        
        print("update failure \(String(describing: error))")
        
    }
    
    func handleEventForEnterRegion(forRegion region: CLRegion!) {
        
        // customize your notification content
        print("Entered in region")
        
    }
    func handleEventForExitRegion(forRegion region: CLRegion!) {
        print("Exited from region")

    }
}
