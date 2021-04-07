//
//  AppDelegate.swift
//  FamilyTracker
//
//  Created by Vijay Godse on 02/03/21.
//

import UIKit
import Firebase
import WatchConnectivity
import Firebase
import GoogleSignIn
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private var ref: DatabaseReference!
    private var memberList = [Members]()
    private var groupId: String = ""

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        WatchSessionManager.shared.startSession()
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        UINavigationBar.appearance().tintColor = UIColor.white
        
        
        //To update current user's location
        setUpLocationManager()
        NotificationCenter.default.addObserver(self, selector: #selector(groupFoundForCurrentUser), name: NSNotification.Name(rawValue: kGroupFoundForCurrentUserNotification), object: nil)

        return true
    }
    
    @objc private func groupFoundForCurrentUser() {
        self.groupId = UserDefaults.standard.string(forKey: "groupId") ?? ""
        ref = Database.database().reference(withPath: "groups/\(self.groupId)")
        //To get all members
        self.ref.child("/members").observe(.childAdded) { (snapshot) in
            if let value = snapshot.value as? NSMutableDictionary {
                self.newFamilyMemberAdded(key: snapshot.key, value: value)
            }
        }
    }
    
    @available(iOS 9.0, *)
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    let handled = GIDSignIn.sharedInstance().handle(url)
    return handled
    // return GIDSignIn.sharedInstance().handle(url,
    // sourceApplication:options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
    // annotation: [:])
    }

    // MARK: UISceneSession Lifecycle

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


    private func setUpLocationManager() {
        NotificationCenter.default.addObserver(self, selector: #selector(locationUpdateNotification(notification:)), name: NSNotification.Name(rawValue: kLocationDidChangeNotification), object: nil)
        let locationManager = UserLocationManager.shared
        locationManager.delegate = self
    }
    
    private func newFamilyMemberAdded(key: String, value: NSMutableDictionary) {
        
        var member = Members()
        member.id = key
        member.lat = value["lat"] as? Double
        member.long = value["long"] as? Double
        member.name = value["name"] as? String
        member.profileUrl = value["profileUrl"] as? String
        self.memberList.append(member)
    }
    
    // MARK: - Notifications

    @objc private func locationUpdateNotification(notification: NSNotification) {
        let userinfo = notification.userInfo
        if let currentLocation = userinfo?["location"] as? CLLocation {
            print("Latitude : \(currentLocation.coordinate.latitude)")
            print("Longitude : \(currentLocation.coordinate.longitude)")
            updateCurrentUsersLocationOnServer(location: currentLocation)
        }
        
    }
    
    private func updateCurrentUsersLocationOnServer(location: CLLocation) {
        if let userId = UserDefaults.standard.string(forKey: "userId") {
            DatabaseManager.shared.fetchGroupsFor(userWith: userId) { (groups) in
                if let groups = groups {
                    DatabaseManager.shared.updateLocationFor(userWith: userId, groups: groups, location: location)
                }
            }
        }
    }
}

extension AppDelegate: LocationUpdateDelegate {
    
    func locationDidUpdateToLocation(location: CLLocation) {
        print("Latitude : \(location.coordinate.latitude)")
        print("Longitude : \(location.coordinate.longitude)")
        updateCurrentUsersLocationOnServer(location: location)
    }
}
