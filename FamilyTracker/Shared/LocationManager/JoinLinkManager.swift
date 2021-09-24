//
//  JoinLinkManager.swift
//  FamilyTracker
//
//  Created by Mahesh on 05/04/21.
//

import UIKit
import FirebaseDynamicLinks
import CoreLocation

class JoinLinkManager: NSObject {
    static let shared = JoinLinkManager()

    func createJoinLinkFor(groupId: String, groupName: String, completion: @escaping (_ url: URL) -> Void) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.google.com"
        components.path = ""
        let queryItem1 = URLQueryItem(name: "groupId", value: groupId)
        let queryItem2 = URLQueryItem(name: "groupName", value: groupName)
        components.queryItems = [queryItem1, queryItem2]
        
        guard let link = components.url else { return }
        let dynamicLinksDomainURIPrefix = "https://reached1.page.link"
        let linkBuilder = DynamicLinkComponents(link: link, domainURIPrefix: dynamicLinksDomainURIPrefix)
        
        if let bundleID = Bundle.main.bundleIdentifier {
            linkBuilder?.iOSParameters = DynamicLinkIOSParameters(bundleID: bundleID)
            linkBuilder?.iOSParameters?.appStoreID = "1561609913"
            linkBuilder?.iOSParameters?.minimumAppVersion = "1.0"
            linkBuilder?.androidParameters = DynamicLinkAndroidParameters(packageName: "com.joshsoftware.reached")
            linkBuilder?.androidParameters?.minimumVersion = 1
        }
        
        linkBuilder?.socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
        linkBuilder?.socialMetaTagParameters?.title = "Reached - kids & kins are safe"
        linkBuilder?.socialMetaTagParameters?.descriptionText = ""
        linkBuilder?.socialMetaTagParameters?.imageURL = URL(string: "https://firebasestorage.googleapis.com/v0/b/reached-ce772.appspot.com/o/bannerTest.png?alt=media&token=61f2c287-5ec6-464f-ad68-c16ebe04d4df")
        
        guard let longDynamicLink = linkBuilder?.url else { return }
        print("The long URL is: \(longDynamicLink)")
        
        DynamicLinkComponents.shortenURL(longDynamicLink, options: nil) { (url, warnings, error) in
            if let shortURL = url {
                print("The short URL is: \(shortURL)")
                completion(shortURL)
            }
        }
    }
    
    func linkHandling(_ inCommingURL: URL) {
        _ = DynamicLinks.dynamicLinks().handleUniversalLink(inCommingURL) { (dynamiclink, error) in
            
            guard error == nil else {
                print("Found an error: \(error?.localizedDescription ?? "")")
                return
            }
            print("Dynamic link : \(String(describing: dynamiclink?.url))")
            var groupId = ""
            var groupName = ""
            let components = URLComponents(url: (dynamiclink?.url)!, resolvingAgainstBaseURL: false)
            if let components = components {
                if let queryItems = components.queryItems {
                    groupId = queryItems[0].value ?? ""
                    groupName = queryItems[1].value ?? ""
                }
            }
            let groupNameString = groupName.replacingOccurrences(of: "+", with: " ")
            print("Group Id: \(groupId)")
            print("Group Name: \(groupNameString)")
            self.handleJoinLinkNavigation(groupId: groupId, groupName: groupNameString)
        }
    }
    
    func handleJoinLinkNavigation(groupId: String, groupName: String) {
        if let topVC = UIApplication.getTopViewController() {
            topVC.presentConfirmationAlert(withTitle: "Greetings!", message: "You have been invited to the group \"\(groupName)\". Please press ok to join.") { (flag) in
                if let topVC = UIApplication.getTopViewController() {
                    if flag {
                        if topVC.isKind(of: DashboardViewController.self) || topVC.isKind(of: MainViewController.self) {
                            self.joinGroupWith(groupId: groupId, completion: {
                                if let vc = topVC as? DashboardViewController {
                                    vc.fetchGroups()
                                } else if topVC is MainViewController {
                                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "fetchGroupsNotification"), object: nil)
                                }
                            })
                        } else if topVC.isKind(of: MapViewController.self) || topVC.isKind(of: ProfileViewController.self) || topVC.isKind(of: SearchAddressViewController.self) || topVC.isKind(of: SaveAddressViewController.self) || topVC.isKind(of: ScanQRCodeViewController.self) || topVC.isKind(of: ShowQRCodeViewController.self) || topVC.isKind(of: ManageGroupViewController.self) {
                            self.joinGroupWith(groupId: groupId, completion: {
                                self.navigateToDashboardVC(topVC: topVC)
                            })
                        } else if topVC.isKind(of: WelcomeViewController.self) || topVC.isKind(of: LoginViewController.self) {
                            UserDefaults.standard.setValue(groupId, forKey: "inviteGroupId")
                            topVC.presentAlert(withTitle: "Alert", message: "Please login first to join group!") {
                                
                            }
                        }
                    }
                }else {
                    //Do nothing
                }
            }
        }
    }
    
    private func navigateToDashboardVC(topVC: UIViewController) {
        DispatchQueue.main.async {
            if let vc = UIStoryboard.dashboardSharedInstance.instantiateViewController(withIdentifier: "DashboardViewController") as? DashboardViewController {
                topVC.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func joinGroupWith(groupId: String, completion: @escaping () -> Void) {
        DatabaseManager.shared.joinToGroupWith(groupId: groupId, currentLocation: UserLocationManager.shared.currentLocation?.coordinate ?? CLLocationCoordinate2D()) {
            completion()
        }
    }
}
