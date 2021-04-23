//
//  NotificationManager.swift
//  FamilyTracker
//
//  Created by Vijay Godse on 23/04/21.
//

import UIKit

class NotificationManager: NSObject {
    static let shared = NotificationManager()
    
    func handleNotification(with data: [String : Any]) {
        guard let type = data["key"] as? String else { return }
        if let topVC = UIApplication.getTopViewController() {
            if type == "join_group" {
                if let vc = UIStoryboard.sharedInstance.instantiateViewController(withIdentifier: "MemberListViewController") as? MemberListViewController {
                    vc.groupId = data["groupId"] as? String ?? ""
                    vc.groupName = data["groupName"] as? String ?? ""
                    topVC.navigationController?.pushViewController(vc, animated: true)
                }
            } else if type == "SOS" {
                if let vc = UIStoryboard.sharedInstance.instantiateViewController(withIdentifier: "MapViewController") as? MapViewController {
                    vc.groupId = data["groupId"] as? String ?? ""
                    topVC.navigationController?.pushViewController(vc, animated: false)
                }
            } else {
                
            }
        }
    }
}
