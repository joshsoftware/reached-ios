//
//  JoinLinkManager.swift
//  FamilyTracker
//
//  Created by Mahesh on 05/04/21.
//

import UIKit
import FirebaseDynamicLinks

class JoinLinkManager: NSObject {
    static let shared = JoinLinkManager()
    
    func createLink() {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.google.com"
        components.path = ""
        let queryItem = URLQueryItem(name: "id", value: "12345")
        components.queryItems = [queryItem]
        
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
                self.linkHandling(shortURL)
            }
        }
    }
    
    fileprivate func linkHandling(_ inCommingURL: URL) {
        
        _ = DynamicLinks.dynamicLinks().handleUniversalLink(inCommingURL) { (dynamiclink, error) in
            
            guard error == nil else {
                print("Found an error: \(error?.localizedDescription ?? "")")
                return
            }
            print("Dynamic link : \(String(describing: dynamiclink?.url))")
            let path = dynamiclink?.url?.path
            var id = 0
            if let query = dynamiclink?.url?.query {
                let dataArray = query.components(separatedBy: "=")
                id = Int(dataArray[1]) ?? 0
            }
            print("Group Id: \(id)")
        }
    }
}
