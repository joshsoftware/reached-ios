//
//  Constant.swift
//  FamilyTracker
//
//  Created by Vijay Godse on 03/03/21.
//

import Foundation
import UIKit

struct Constant {
   
    static let baseUrl = "https://reached-stage.firebaseio.com/"

    struct kAPINameConstants {
        static let kGroupMembers = "/groups/"
        static let kUpdateGroupMembers = "/groups/"

    }

    // MARK: - API Configuration Constants
    //TODO: This should be in ApiEndpoint
    struct kAPIConfigConstants {
        static let kHttpGET = "GET"
        static let kHttpPOST = "POST"
        static let KHttpPUT = "PUT"
        static let kHttpDELETE = "DELETE"
        static let kHttpPATCH = "PATCH"

        static let kAcceptKey = "Accept"
        static let kContentTypeKey = "Content-Type"
        static let kAuthTokenKey = "Authorization"
        static let kDeviceIdKey = "Device-Id"
    }

    // MARK: - Color Constants

    struct kColor {

        static let KDarkOrangeColor = UIColor(red: 175.0 / 255.0, green: 127.0 / 255.0, blue: 16.0 / 255.0, alpha: 1.0)
        
        static let KAppOrangeShade1 = UIColor(red: 239.0 / 255.0, green: 189.0 / 255.0, blue: 65.0 / 255.0, alpha: 1.0)

        static let KAppGray = UIColor(red: 112.0 / 255.0, green: 112.0 / 255.0, blue: 112.0 / 255.0, alpha: 1.0)

        static let KAppGreen = UIColor(red: 21.0 / 255.0, green: 207.0 / 255.0, blue: 0.0 / 255.0, alpha: 1.0)

    }
    
    enum NotificationType: String {
        case joinGroup = "join_group"
        case sos = "sos"
    }
}

