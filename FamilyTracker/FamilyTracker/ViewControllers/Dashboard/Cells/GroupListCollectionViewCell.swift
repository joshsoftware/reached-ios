//
//  GroupListCollectionViewCell.swift
//  FamilyTracker
//
//  Created by Vijay Godse on 13/05/21.
//

import UIKit
import CoreLocation
import Firebase
import WatchConnectivity
import Floaty
import SDWebImage
import Contacts

class GroupListCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var groupNameLbl: UILabel!
    @IBOutlet weak var menuImageView: UIImageView!
    @IBOutlet weak var addGroupMemberImgView: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var trackingLocationLbl: UILabel!
    @IBOutlet weak var allMembersLbl: UILabel!
    @IBOutlet weak var safeUnsafeLbl: UILabel!
    
    var memberList = [Members]()
    private var userRef: DatabaseReference!
    private var ref: DatabaseReference!
    private var isAllMemberSafe = true
    
    var connectivityHandler = WatchSessionManager.shared
    var groupId: String = ""
//    var createdBy: String = ""
//    var groupRefreshHandler: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func initiateCell(groupId: String) {
        self.memberList.removeAll()
        self.groupId = groupId
        userRef = Database.database().reference()
        ref = Database.database().reference(withPath: "groups/\(self.groupId)")
        setUp()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.layer.cornerRadius = 12.0
        containerView.setShadowToAllSides()
    }
    
    private func setUp() {
        setUpTableView()
        observeFirebaseRealtimeDBChanges()
        updateSafeUnsafeText()
    }
    
    private func updateSafeUnsafeText() {
        if isAllMemberSafe {
            safeUnsafeLbl.text = "SAFE"
            safeUnsafeLbl.textColor = Constant.kColor.KAppGreen
        } else {
            safeUnsafeLbl.text = "UNSAFE"
            safeUnsafeLbl.textColor = .red
        }
    }
    
    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "GroupMemberTableViewCell", bundle: nil), forCellReuseIdentifier: "GroupMemberTableViewCell")
    }
    
    private func observeFirebaseRealtimeDBChanges() {
        //Observe updated value for member
        self.ref.child("/members").observe(.childChanged) { (snapshot) in
            if let value = snapshot.value as? NSMutableDictionary {
                self.familyMembersLocationUpdated(key: snapshot.key, value: value)
            }
        }
        
        //Observe newly added member
        self.ref.child("/members").observe(.childAdded) { (snapshot) in
            if let value = snapshot.value as? NSMutableDictionary {
                self.newFamilyMemberAdded(key: snapshot.key, value: value)
            }
        }
        
        //Observe family member removed
        self.ref.child("/members").observe(.childRemoved) { (snapshot) in
            if let value = snapshot.value as? NSMutableDictionary {
                self.familyMemberRemoved(value: value)
            }
        }
    }
    
    private func updateCurrentUsersSOSOnServer(sosState: Bool) {
        if let userId = UserDefaults.standard.string(forKey: "userId"), !userId.isEmpty {
            DatabaseManager.shared.fetchGroupsFor(userWith: userId) { (groups) in
                if let groups = groups {
                    DatabaseManager.shared.updateSOSFor(userWith: userId, groups: groups, sosState: sosState)
                }
            }
        } else {
            print("User is not logged in")
        }
    }
    
    private func familyMembersLocationUpdated(key: String, value: NSMutableDictionary) {
        
        var member = Members()
        member.id = key
        member.lat = value["lat"] as? Double
        member.long = value["long"] as? Double
        member.name = value["name"] as? String
        member.profileUrl = value["profileUrl"] as? String
        member.lastUpdated = value["lastUpdated"] as? String
        member.sosState = value["sosState"] as? Bool

        if let index = self.memberList.firstIndex(where: { $0.id == member.id }) {
            self.memberList[index] = member
            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        }
    }
    
    private func newFamilyMemberAdded(key: String, value: NSMutableDictionary) {
        
        var member = Members()
        member.id = key
        member.lat = value["lat"] as? Double
        member.long = value["long"] as? Double
        member.name = value["name"] as? String
        member.profileUrl = value["profileUrl"] as? String
        member.lastUpdated = value["lastUpdated"] as? String
        member.sosState = value["sosState"] as? Bool
        
        self.memberList.append(member)
        self.tableView.reloadData()
        
    }
    
    private func familyMemberRemoved(value: NSMutableDictionary) {
        
        var member = Members()
        member.id = value["id"] as? String
        if let index = self.memberList.firstIndex(where: { $0.id == member.id }) {
            self.memberList.remove(at: index)
            self.tableView.reloadData()
        }
    }

    private func sendUserIdToWatch() {
        if let userId = UserDefaults.standard.string(forKey: "userId") {
            self.connectivityHandler.sendMessage(message: ["userId" : userId as AnyObject], errorHandler:  { (error) in
                print("Error sending message: \(error)")
            })
        }
    }
    

}

extension GroupListCollectionViewCell: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return memberList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupMemberTableViewCell", for: indexPath) as? GroupMemberTableViewCell
        cell?.selectionStyle = .none
        let isIndexValid = memberList.indices.contains(indexPath.row)
        if isIndexValid {
            let member = memberList[indexPath.row]
            cell?.updateCell(member: member)
        }
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
}
