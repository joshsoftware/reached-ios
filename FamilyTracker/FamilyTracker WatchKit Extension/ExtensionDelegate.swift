//
//  ExtensionDelegate.swift
//  FamilyTracker WatchKit Extension
//
//  Created by Vijay Godse on 02/03/21.
//

import WatchKit
import WatchConnectivity
import FirebaseCore
import Firebase

class ExtensionDelegate: NSObject, WKExtensionDelegate, MessagingDelegate {

    var globalNotificationDictionary: [AnyHashable: Any]?

    func applicationDidFinishLaunching() {
        FirebaseApp.configure()
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            if granted {
                WKExtension.shared().registerForRemoteNotifications()
            }
        }
        Messaging.messaging().delegate = self

        //Location update set up
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: kLocationDidChangeNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(locationUpdateNotification(notification:)), name: NSNotification.Name(rawValue: kLocationDidChangeNotification), object: nil)
        let locationManager = UserLocationManager.shared
        locationManager.delegate = self
    }
    
    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                backgroundTask.setTaskCompletedWithSnapshot(false)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                // Be sure to complete the relevant-shortcut task once you're done.
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                // Be sure to complete the intent-did-run task once you're done.
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
    
    /// MessagingDelegate
    func messaging(_: Messaging, didReceiveRegistrationToken fcmToken: String?) {
      print("token:\n" + (fcmToken ?? ""))
      Messaging.messaging().subscribe(toTopic: "watch") { error in
        guard error == nil else {
          print("error:" + error.debugDescription)
          return
        }
        print("Successfully subscribed to topic")
      }
    }

    /// WKExtensionDelegate
    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
      /// Swizzling should be disabled in Messaging for watchOS, set APNS token manually.
      print("Set APNS Token\n")
      Messaging.messaging().apnsToken = deviceToken
    }

}

extension ExtensionDelegate: LocationUpdateDelegate {
    
    // MARK: - Notifications

    @objc private func locationUpdateNotification(notification: NSNotification) {
        let userinfo = notification.userInfo
        if let currentLocation = userinfo?["location"] as? CLLocation {
            print("Latitude : \(currentLocation.coordinate.latitude)")
            print("Longitude : \(currentLocation.coordinate.longitude)")
            self.updateCurrentUserLocation(location: currentLocation)
        }
        
    }
    
    
    private func updateCurrentUserLocation(location: CLLocation) {
        
        if let userId = UserDefaults.standard.string(forKey: "userId"), !userId.isEmpty{
            DatabaseManager.shared.fetchGroupsFor(userWith: userId) { (groups) in
                if let groups = groups {
                    DatabaseManager.shared.updateLocationFor(userWith: userId, groups: groups, location: location)
                }
            }
        } else {
            print("User is not logged in")
        }
    }
    
    func locationDidUpdateToLocation(location: CLLocation) {
        print("Latitude : \(location.coordinate.latitude)")
        print("Longitude : \(location.coordinate.longitude)")
        self.updateCurrentUserLocation(location: location)
    }
}
