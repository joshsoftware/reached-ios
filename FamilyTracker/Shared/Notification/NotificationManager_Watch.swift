//
//  NotificationManager_Watch.swift
//  FamilyTracker WatchKit Extension
//
//  Created by Vijay Godse on 26/04/21.
//

import Foundation
import UIKit
import WatchKit

class NotificationManager_Watch: NSObject {
    static let shared = NotificationManager_Watch()

    func handleNotification(with data: [String : Any]) {
        guard let type = data["type"] as? String else { return }

        
        guard let initialVC = WKExtension.shared().rootInterfaceController as? InterfaceController else {
            return
        }
        
        var payload: NotificationPayload?
        
        if let payloadStr = (data["payload"] as? Dictionary<String, Any>)?.jsonStringRepresentation {
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
            var group = Group()
            group.id = payload?.groupId ?? ""
            initialVC.pushController(withName: MemberListInterfaceController.name, context: group)

        case Constant.NotificationType.sos.rawValue:
            var group = Group()
            group.id = payload?.groupId ?? ""
            var member = Members()
            member.id = payload?.memberId ?? ""
            var membersArray: [Members] = [Members]()
            membersArray.append(member)
            initialVC.pushController(withName: MapInterfaceController.name, context: (membersArray, group))

        case Constant.NotificationType.leaveGroup.rawValue:
            var group = Group()
            group.id = payload?.groupId ?? ""
            initialVC.pushController(withName: MemberListInterfaceController.name, context: group)
            
        case Constant.NotificationType.geofence.rawValue:
            var group = Group()
            group.id = payload?.groupId ?? ""
            var member = Members()
            member.id = payload?.memberId ?? ""
            var membersArray: [Members] = [Members]()
            membersArray.append(member)
            initialVC.pushController(withName: MapInterfaceController.name, context: (membersArray, group))
            
        case Constant.NotificationType.deleteGroup.rawValue:
            var group = Group()
            group.id = payload?.groupId ?? ""
            initialVC.pushController(withName: MemberListInterfaceController.name, context: group)
        default:
            break
        }
    }
}

extension Dictionary {
    var jsonStringRepresentation: String? {
        guard let theJSONData = try? JSONSerialization.data(withJSONObject: self,
                                                            options: [.prettyPrinted]) else {
            return nil
        }

        return String(data: theJSONData, encoding: .ascii)
    }
}
