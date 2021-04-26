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

        let groupListViewController = UIStoryboard.sharedInstance.instantiateViewController(withIdentifier: "GroupListViewController")
        navigationController.pushViewController(groupListViewController, animated: false)
        
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
            if let vc = UIStoryboard.sharedInstance.instantiateViewController(withIdentifier: "MemberListViewController") as? MemberListViewController {
                vc.groupId = payload?.groupId ?? ""
                navigationController.pushViewController(vc, animated: true)

            }
        case Constant.NotificationType.sos.rawValue:
            if let vc = UIStoryboard.sharedInstance.instantiateViewController(withIdentifier: "MemberListViewController") as? MemberListViewController {
                vc.groupId = payload?.groupId ?? ""
                vc.sosRecievedMemberId = payload?.memberId ?? ""
                navigationController.pushViewController(vc, animated: true)
            }

            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "GoToMapOnSOSRemoteNotification"), object: nil, userInfo: nil)
        default:
            break
        }
    }
}
