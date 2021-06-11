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
        guard let type = data["type"] as? String else { return }

        let initialVC = UIStoryboard.sharedInstance.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController

        let navigationController = UINavigationController(rootViewController: initialVC)

        UIApplication.shared.windows.first?.rootViewController = navigationController
        UIApplication.shared.windows.first?.makeKeyAndVisible()

        if let vc = UIStoryboard.dashboardSharedInstance.instantiateViewController(withIdentifier: "MainViewController") as? MainViewController {
            navigationController.pushViewController(vc, animated: false)
        }
        
        var payload: NotificationPayload?
        
        if let payloadStr = data["payload"] as? String {
            let data = Data(payloadStr.utf8)
            do {
                let decoder = JSONDecoder()
                let responseData = try decoder.decode(NotificationPayload.self, from: data)
                payload = responseData
            } catch let error {
                print(error)
            }
        }
        
        switch type {
        case Constant.NotificationType.joinGroup.rawValue:
            if let vc = UIStoryboard.dashboardSharedInstance.instantiateViewController(withIdentifier: "GroupListViewController") as? GroupListViewController {
//                vc.groupId = payload?.groupId ?? ""
                navigationController.pushViewController(vc, animated: true)
            }
        case Constant.NotificationType.sos.rawValue:
            if let vc = UIStoryboard.dashboardSharedInstance.instantiateViewController(withIdentifier: "MapViewController") as? MapViewController {
                vc.groupId = payload?.groupId ?? ""
                vc.memberId = payload?.memberId ?? ""
                vc.isFromSOSNotification = true
                navigationController.pushViewController(vc, animated: false)
            }
        default:
            break
        }
    }
}
