//
//  ManageGroupViewController.swift
//  FamilyTracker
//
//  Created by Mahesh on 28/05/21.
//

import UIKit

class ManageGroupViewController: UIViewController {
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!

    var memberList = [Members]()
    var removedMember = [String]()
    var groupId: String = ""
    var groupName: String = ""
    var groupMemberUpdatedHandler: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.groupNameLabel.text = self.groupName
        // Do any additional setup after loading the view.
    }
    
    @IBAction func backBtnAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func saveBtnAction(_ sender: Any) {
        let myGroup = DispatchGroup()

        for userId in removedMember {
            myGroup.enter()
            DatabaseManager.shared.leaveGroup(userWith: userId, groupId: self.groupId) { (response, error) in
                myGroup.leave()
                if (error != nil) {
                    print(error ?? "")
                } else {
                    print("User leave group with id: \(userId)")
                }
            }
        }

        myGroup.notify(queue: .main) {
            print("Finished all requests.")
            self.groupMemberUpdatedHandler?()
            self.navigationController?.popViewController(animated: true)
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension ManageGroupViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return memberList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ManageGroupTableViewCell", for: indexPath) as? ManageGroupTableViewCell else { return UITableViewCell() }
        let member = memberList[indexPath.row]
        cell.memberNameLbl.text = member.name
        cell.removeMemberHandler = {
            self.removedMember.append(member.id ?? "")
            self.memberList.remove(at: indexPath.row)
            self.tableView.reloadData()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}
