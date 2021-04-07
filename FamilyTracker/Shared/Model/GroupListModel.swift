//
//  GroupListModel.swift
//  FamilyTracker
//
//  Created by Mahesh on 06/04/21.
//

import Foundation

struct GroupList: Codable {
    let groups : [Group]?

    enum CodingKeys: String, CodingKey {

        case groups = "group"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        groups = try values.decodeIfPresent([Group].self, forKey: .groups)
    }

}

struct Group : Codable {
    var name : String?
    var createdBy : String?
    var members : [Members]?
    var id : String?

    init() {
    }
    
    enum CodingKeys: String, CodingKey {

        case name = "name"
        case createdBy = "created_by"
        case members = "members"
        case id = "id"

    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decodeIfPresent(String.self, forKey: .name)
        createdBy = try values.decodeIfPresent(String.self, forKey: .createdBy)
        members = try values.decodeIfPresent([Members].self, forKey: .members)
        id = try values.decodeIfPresent(String.self, forKey: .id)
    }

}

