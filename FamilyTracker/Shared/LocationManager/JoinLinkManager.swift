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
    var currentLocation : CLLocation?

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
            linkBuilder?.androidParameters = DynamicLinkAndroidParameters(packageName: bundleID)
            linkBuilder?.androidParameters?.minimumVersion = 1
        }
        
        linkBuilder?.socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
        linkBuilder?.socialMetaTagParameters?.title = "Title Of Promotion"
        linkBuilder?.socialMetaTagParameters?.descriptionText = "Description Of Promotion"
        linkBuilder?.socialMetaTagParameters?.imageURL = URL(string: "ImageURL")
        
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
            print("Group Id: \(groupId)")
            print("Group Name: \(groupName)")
            self.handleJoinLinkNavigation(groupId: groupId, groupName: groupName)
        }
    }
    
    func handleJoinLinkNavigation(groupId: String, groupName: String) {
        if let topVC = UIApplication.getTopViewController() {
            topVC.presentConfirmationAlert(withTitle: "Alert", message: "Do you want to join Group \(groupName)?") { (flag) in
                if flag {
                    if topVC.isKind(of: GroupListViewController.self) {
                        self.joinGroupWith(groupId: groupId, completion: {
                            if let vc = topVC as? GroupListViewController {
                                vc.fetchGroups()
                            }
                        })
                    } else if topVC.isKind(of: MemberListViewController.self) {
                        self.joinGroupWith(groupId: groupId, completion: {
                            if let vc = topVC as? MemberListViewController {
                                self.navigateToGroupListVC(topVC: vc)
                            }
                        })
                    } else if topVC.isKind(of: MapViewController.self) {
                        self.joinGroupWith(groupId: groupId, completion: {
                            if let vc = topVC as? MemberListViewController {
                                self.navigateToGroupListVC(topVC: vc)
                            }
                        })
                    } else if topVC.isKind(of: ScanQRCodeViewController.self) {
                        self.joinGroupWith(groupId: groupId, completion: {
                            if let vc = topVC as? ScanQRCodeViewController {
                                self.navigateToGroupListVC(topVC: vc)
                            }
                        })
                    } else if topVC.isKind(of: ShowQRCodeViewController.self) {
                        self.joinGroupWith(groupId: groupId, completion: {
                            if let vc = topVC as? ShowQRCodeViewController {
                                self.navigateToGroupListVC(topVC: vc)
                            }
                        })
                    } else if topVC.isKind(of: LoginViewController.self) {
                        UserDefaults.standard.setValue(groupId, forKey: "inviteGroupId")
                    } else if topVC.isKind(of: HomeViewController.self) {
                        self.joinGroupWith(groupId: groupId, completion: {
                            if let vc = topVC as? MemberListViewController {
                                self.navigateToGroupListVC(topVC: vc)
                            }
                        })
                    }
                } else {
                    //Do nothing
                }
            }
        }
    }
    
    private func navigateToGroupListVC(topVC: UIViewController) {
        DispatchQueue.main.async {
            if let vc = UIStoryboard.sharedInstance.instantiateViewController(withIdentifier: "GroupListViewController") as? GroupListViewController {
                topVC.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func joinGroupWith(groupId: String, completion: @escaping () -> Void) {
        DatabaseManager.shared.joinToGroupWith(groupId: groupId, currentLocation: self.currentLocation?.coordinate ?? CLLocationCoordinate2D()) {
            completion()
        }
    }
}
