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
import Contacts

class GroupListCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var groupNameLbl: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var firstMenuButton: UIButton!
    @IBOutlet weak var secondMenuButton: UIButton!
    @IBOutlet weak var seperatorView: UIView!

    var memberList = [Members]()
    private var ref: DatabaseReference!
    private var isAllMemberSafe = true
    var isCreatorOfGroup = false

    var connectivityHandler = WatchSessionManager.shared
    var groupId: String = ""
    var addMemberHandler: ((_ groupId: String, _ groupName: String) -> Void)?
    var menuHandler: (() -> Void)?
    var deleteGroupHandler: (() -> Void)?
    var leaveGroupHandler: (() -> Void)?
    var onClickMemberHandler: ((_ members: [Members]) -> Void)?
    var onClickMemberProfileHandler: ((_ member: Members) -> Void)?

    
    override func awakeFromNib() {
        super.awakeFromNib()
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        menuView.addGestureRecognizer(tap)
        // Initialization code
    }
    
    func initiateCell(groupId: String) {
        self.memberList.removeAll()
        self.tableView.reloadData()
        self.groupId = groupId
        ref = Database.database().reference(withPath: "groups/\(self.groupId)")
        setUp()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.layer.cornerRadius = 12.0
        menuView.layer.cornerRadius = 12.0
        containerView.setShadowToAllSides()
    }
    
    private func setUp() {
        setUpTableView()
        handleMenu()
        observeFirebaseRealtimeDBChanges()
    }
    
    func handleMenu() {
        if !isCreatorOfGroup {
            firstMenuButton.tag = 2
            firstMenuButton.setTitle("Exit Group", for: .normal)
            seperatorView.isHidden = true
            secondMenuButton.isHidden = true
        }
    }
    
    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "GroupMemberTableViewCell", bundle: nil), forCellReuseIdentifier: "GroupMemberTableViewCell")
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        UIView.animate(withDuration: 0.2) {
            self.menuView.alpha = 0
        }
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
        
        let filterMemberList = self.memberList.filter({ $0.id == member.id })
        if filterMemberList.count == 0 {
            self.memberList.append(member)
            self.tableView.reloadData()
        }
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
    
    @IBAction func addMemberButtonPressed(_ sender: Any) {
        addMemberHandler?(self.groupId, self.groupNameLbl.text!)
    }
    
    @IBAction func menuButtonPressed(_ sender: Any) {
        UIView.animate(withDuration: 0.2) {
            self.menuView.alpha = 1.0
        }
    }
    
    @IBAction func menuOptionButtonPressed(_ sender: UIButton) {
        if sender.tag == 0 {
            UIView.animate(withDuration: 0.2) {
                self.menuView.alpha = 0
                self.menuHandler?()
            }
        } else if sender.tag == 1 {
            UIView.animate(withDuration: 0.2) {
                self.menuView.alpha = 0
                self.deleteGroupHandler?()
            }
        } else {
            UIView.animate(withDuration: 0.2) {
                self.menuView.alpha = 0
                self.leaveGroupHandler?()
            }
        }
    }

}

extension GroupListCollectionViewCell: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return memberList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupMemberTableViewCell", for: indexPath) as? GroupMemberTableViewCell
        let isIndexValid = memberList.indices.contains(indexPath.row)
        if isIndexValid {
            let member = memberList[indexPath.row]
            cell?.updateCell(member: member)
            cell?.onClickMemberHandler = {
                var selectedMember = [Members]()
                selectedMember.append(member)
                self.onClickMemberHandler?(selectedMember)
            }
            cell?.onClickMemberProfileHandler = {
                self.onClickMemberProfileHandler?(member)
            }
        }
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }
}
