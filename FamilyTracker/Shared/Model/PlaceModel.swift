//
//  PlaceModel.swift
//  FamilyTracker
//
//  Created by Mahesh on 02/06/21.
//

import Foundation

struct Place : Codable {
    var lat : Double?
    var long : Double?
    var address : String?
    var name : String?
    var radius : Double?

    init() {
    }
    
    enum CodingKeys: String, CodingKey {

        case lat = "lat"
        case long = "long"
        case address = "address"
        case name = "name"
        case radius = "radius"

    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        lat = try values.decodeIfPresent(Double.self, forKey: .lat)
        long = try values.decodeIfPresent(Double.self, forKey: .long)
        address = try values.decodeIfPresent(String.self, forKey: .address)
        name = try values.decodeIfPresent(String.self, forKey: .name)
        radius = try values.decodeIfPresent(Double.self, forKey: .radius)
    }

}

