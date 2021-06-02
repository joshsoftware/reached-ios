//
//  DatabaseManager.swift
//  FamilyTracker
//
//  Created by Mahesh on 06/04/21.
//

import UIKit
#if os(iOS)
import Firebase
#elseif os(watchOS)
import FirebaseDatabase
#endif
import CoreLocation
import Foundation

class DatabaseManager: NSObject {
    static let shared = DatabaseManager()
    private var ref: DatabaseReference!
    let group = DispatchGroup()

    func fetchGroupsFor(userWith id: String, completion: @escaping (_ result: NSDictionary?) -> Void) {
        self.ref = Database.database().reference().child("users").child(id).child("groups")
        self.ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()) {
                if let data = snapshot.value as? NSDictionary {
                    print("Groups fetched...")
                    completion(data)
                } else {
                    completion(nil)
                }
            } else {
                print("Group not created")
                completion(nil)
            }
        })
    }
    
    func updateLocationFor(userWith id: String, groups: NSDictionary, location: CLLocation) {
        let dtf = DateFormatter()
        dtf.timeZone = TimeZone(identifier: "UTC")
        dtf.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let currentDate = dtf.string(from: Date())
        
        for groupId in groups.allKeys {
            self.ref = Database.database().reference(withPath: "groups/\(groupId)")
            self.ref.child("/members").child("\(id)/lat").setValue(location.coordinate.latitude)
            self.ref.child("/members").child("\(id)/long").setValue(location.coordinate.longitude)
            self.ref.child("/members").child("\(id)/lastUpdated").setValue(currentDate)
        }
        print("Location updated...")
    }
    
    func fetchGroupData(groups: NSDictionary, completion: @escaping (_ groups: Group?) -> Void) {
        for groupId in groups.allKeys {
            self.ref = Database.database().reference().child("groups/\(groupId)")
            self.ref.observeSingleEvent(of: .value, with: { (snapshot) in
                if(snapshot.exists()) {
                    if let data = snapshot.value as? NSDictionary {
                        var group = Group()
                        group.id = groupId as? String
                        group.name = data["name"] as? String
                        group.createdBy = data["created_by"] as? String
                        
                        var memberList = [Members]()
                        if let members = data["members"] as? NSDictionary {
                            for (key, member) in members {
                                if let data = member as? NSDictionary {
                                    var member = Members()
                                    member.id = key as? String
                                    member.lat = data["lat"] as? Double
                                    member.long = data["long"] as? Double
                                    member.name = data["name"] as? String
                                    member.lastUpdated = data["lastUpdated"] as? String
                                    member.sosState = data["sosState"] as? Bool

                                    memberList.append(member)
                                }
                            }
                        }
                        group.members = memberList
                        completion(group)
                    }
                } else {
                    print("Group not created")
                    completion(nil)
                }
            })
        }
        completion(nil)
    }
    
    func joinToGroupWith(groupId: String, currentLocation: CLLocationCoordinate2D, completion: @escaping () -> Void) {
        ref = Database.database().reference()
        if let userId = UserDefaults.standard.string(forKey: "userId"), let name = UserDefaults.standard.string(forKey: "userName"), let profileUrl = UserDefaults.standard.string(forKey: "userProfileUrl") {
            let dtf = DateFormatter()
            dtf.timeZone = TimeZone(identifier: "UTC")
            dtf.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let currentDate = dtf.string(from: Date())
            
            let data = ["lat": currentLocation.latitude, "long": currentLocation.longitude, "name": name, "lastUpdated": currentDate, "profileUrl": profileUrl] as [String : Any]
            self.ref.child("groups").child(groupId).child("members").child(userId).setValue(data)
            
            if var dict = UserDefaults.standard.dictionary(forKey: "groups") {
                dict[groupId] = true
                self.ref.child("users").child(userId).child("groups").setValue(dict)
                UserDefaults.standard.setValue(dict, forKey: "groups")
            } else {
                let dict = [groupId: true]
                self.ref.child("users").child(userId).child("groups").setValue(dict)
                UserDefaults.standard.setValue(dict, forKey: "groups")
            }
            completion()
        }
    }
    
    func updateSOSFor(userWith id: String, groups: NSDictionary, sosState: Bool) {
       
        for groupId in groups.allKeys {
            self.ref = Database.database().reference(withPath: "groups/\(groupId)")
            self.ref.child("/members").child("\(id)/sosState").setValue(sosState)
        }
        print("SOS updated...")
    }
    
    func leaveGroup(userWith id: String, groupId: String, completion: @escaping (_ response: String?, _ error: String?) -> Void) {
        self.ref = Database.database().reference(withPath: "groups/\(groupId)").child("members").child(id)
        self.ref.removeValue { (error, reference) in
            if (error != nil) {
                completion(nil, "Error while leaving group")
            } else {
                self.ref = Database.database().reference().child("users").child(id).child("groups").child(groupId)
                self.ref.removeValue { (error, reference) in
                    if (error != nil) {
                        completion(nil, "Error while leaving group")
                    } else {
                        completion("Leave group sucessfully", nil)
                    }
                }
            }
        }
    }
    
    func deleteGroup(groupId: String, completion: @escaping (_ response: String?, _ error: String?) -> Void) {
        self.ref = Database.database().reference().child("groups/\(groupId)").child("members")
        self.ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()) {
                if let members = snapshot.value as? NSDictionary {
                    for key in members.allKeys {
                        self.group.enter()
                        self.ref = Database.database().reference().child("users").child(key as! String).child("groups").child(groupId)
                        self.ref.removeValue { (error, reference) in
                            if (error != nil) {
                                completion(nil, "Error while deleting group")
                            } else {
                                // Do nothing
                            }
                            self.group.leave()
                        }
                    }
                    self.ref = Database.database().reference().child("groups/\(groupId)")
                    self.ref.removeValue { (error, reference) in
                        if (error != nil) {
                            completion(nil, "Error while deleting group")
                        } else {
                            completion("Leave group sucessfully", nil)
                        }
                    }
                }
            } else {
                completion(nil, "Error while deleting group")
            }
        })
    }
    
    func requestForLeaveGroup(groupId: String, groupName: String, createBy: String, completion: @escaping (_ response: String?, _ error: String?) -> Void) {
        if let userId = UserDefaults.standard.string(forKey: "userId"), let name = UserDefaults.standard.string(forKey: "userName") {
            let data = ["from": ["id": userId, "name": name], "group": ["id": groupId, "name": groupName], "to": createBy] as [String : Any]
            let value = ["data": data, "type": "LEAVE"] as [String : Any]
            self.ref = Database.database().reference().child("requests").childByAutoId()
            self.ref.setValue(value) { (error, reference) in
                if (error != nil) {
                    completion(nil, "Error while creating leave group request")
                } else {
                    completion("Request for leave group raise sucessfully", nil)
                }
            }
        }
    }
    
    func setDeviceTokenOnServer(userId: String) {
        ref = Database.database().reference()
        if let token = UserDefaults.standard.object(forKey: "deviceToken") as? String {
            self.ref.child("users").child(userId).child("token").child("phone").setValue(token)
        }
    }
}
