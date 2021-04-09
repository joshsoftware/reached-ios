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
import FirebaseDynamicLinks
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private var ref: DatabaseReference!
    private var memberList = [Members]()
    private var groupId: String = ""
    var globalNotificationDictionary: [AnyHashable: Any]?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        WatchSessionManager.shared.startSession()
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        UINavigationBar.appearance().tintColor = UIColor.white
        
        
        //To update current user's location
        setUpLocationManager()
        NotificationCenter.default.addObserver(self, selector: #selector(groupFoundForCurrentUser), name: NSNotification.Name(rawValue: kGroupFoundForCurrentUserNotification), object: nil)

        //Remote Notification
        let remoteNotification = launchOptions?[.remoteNotification]
        if let notificationData = remoteNotification as? NSDictionary {
            globalNotificationDictionary = notificationData as? [AnyHashable: Any]
        }
        registerForPushNotifications()
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
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
         let dynamicLink = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: url)
         if dynamicLink != nil {
              print("Dynamic link : \(String(describing: dynamicLink?.url))")
              return true
         }
         return false
    }
    
    func application(_ application: UIApplication, continue userActivity:
    NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
         guard let inCommingURL = userActivity.webpageURL else { return false }
         print("Incomming Web Page URL: \(inCommingURL)")
         return true
    }
}

extension AppDelegate: LocationUpdateDelegate {
    
    func locationDidUpdateToLocation(location: CLLocation) {
        print("Latitude : \(location.coordinate.latitude)")
        print("Longitude : \(location.coordinate.longitude)")
        updateCurrentUsersLocationOnServer(location: location)
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    //MARK: Remote notification
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            granted, _ in
            print("Permission granted: \(granted)")
            // 1. Check if permission granted
            guard granted else { return }
            // 2. Attempt registration for remote notifications on the main thread
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // 1. Convert device token to string
        let tokenParts = deviceToken.map { data -> String in
            String(format: "%02.2hhx", data)
        }
        let token = tokenParts.joined()
        // 2. Print device token to use for PNs payloads
        print("Device Token: \(token)")
        UserDefaults.standard.set(token, forKey: "DeviceToken")
    }
    
    func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications with error: \(error)")
    }
    
    // This method will be called when app received push notifications in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let notificationData = notification.request.content.userInfo
        globalNotificationDictionary = notificationData
        if let dictionary = globalNotificationDictionary {
            print(dictionary)
        }
        completionHandler([.alert, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        if globalNotificationDictionary != nil {
        } else {
            globalNotificationDictionary = response.notification.request.content.userInfo
            let dictionary = response.notification.request.content.userInfo
            print(dictionary)
        }
    }
}
