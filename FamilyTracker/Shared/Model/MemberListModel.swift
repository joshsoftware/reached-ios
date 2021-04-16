//
//  MemberListModel.swift
//  FamilyTracker
//
//  Created by Vijay Godse on 03/03/21.
//

import Foundation
import MapKit

class Location: NSObject, MKAnnotation {
    var userName: String?
    var coordinate: CLLocationCoordinate2D
    
    init(userName: String, coordinate: CLLocationCoordinate2D) {
        self.userName = userName
        self.coordinate = coordinate
    }
}

struct MemberList: Codable {
    let members : [Members]?

    enum CodingKeys: String, CodingKey {

        case members = "members"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        members = try values.decodeIfPresent([Members].self, forKey: .members)
    }

}

struct Members : Codable {
    var lat : Double?
    var long : Double?
    var name : String?
    var id : String?
    var profileUrl : String?
    var lastUpdated: String?
    var sosState: Bool?

    init() {
    }
    
    enum CodingKeys: String, CodingKey {

        case lat = "lat"
        case long = "long"
        case name = "name"
        case id = "id"
        case profileUrl = "profileUrl"
        case lastUpdated = "lastUpdated"
        case sosState = "sosState"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        lat = try values.decodeIfPresent(Double.self, forKey: .lat)
        long = try values.decodeIfPresent(Double.self, forKey: .long)
        name = try values.decodeIfPresent(String.self, forKey: .name)
        id = try values.decodeIfPresent(String.self, forKey: .id)
        profileUrl = try values.decodeIfPresent(String.self, forKey: .profileUrl)
        lastUpdated = try values.decodeIfPresent(String.self, forKey: .lastUpdated)
        sosState = try values.decodeIfPresent(Bool.self, forKey: .sosState)
    }

}

