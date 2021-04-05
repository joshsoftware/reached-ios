//
//  ApiClient.swift
//  FamilyTracker
//
//  Created by Vijay Godse on 03/03/21.
//

import Foundation

class ApiClient {
    
    class func getFamilyMembersListWithLocations(groupId: String, completion: @escaping (Result<MemberList,APIError>) -> Void) {
        let url = Constant.baseUrl + Constant.kAPINameConstants.kGroupMembers + "\(groupId).json?print=pretty"
        print(url)
        Service.shared.request(url: url, httpMethodType: Constant.kAPIConfigConstants.kHttpGET, parameters: nil) { (result) in
            return completion(result)
        }
    }
    
    class func updateLocation(params: [[String: AnyObject]], groupId: String, completion: @escaping (Result<MemberList,APIError>) -> Void) {
        let url = Constant.baseUrl + Constant.kAPINameConstants.kUpdateGroupMembers + "\(groupId)/members.json"
        print(url)
        Service.shared.request(url: url, httpMethodType: Constant.kAPIConfigConstants.KHttpPUT, parameters: params) { (result) in
            return completion(result)
        }
    }
   
}
