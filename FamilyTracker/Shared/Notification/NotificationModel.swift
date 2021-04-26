//
//  NotificationModel.swift
//  FamilyTracker
//
//  Created by Vijay Godse on 26/04/21.
//

import Foundation


struct NotificationPayload : Codable {
    let groupId : String?
    let memberId : String?
    
    enum CodingKeys: String, CodingKey {

        case groupId = "groupId"
        case memberId = "memberId"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        groupId = try values.decodeIfPresent(String.self, forKey: .groupId)
        memberId = try values.decodeIfPresent(String.self, forKey: .memberId)
    }

}
