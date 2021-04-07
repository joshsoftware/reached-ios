//
//  GroupListViewController.swift
//  FamilyTracker
//
//  Created by Mahesh on 06/04/21.
//

import UIKit
import Floaty
import SDWebImage
import Firebase

class GroupListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var floatyBtn: Floaty!
    
    private var ref: DatabaseReference!
    var groups : NSDictionary = NSDictionary()
    private var groupList = [Group]()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setUpFloatyButton()
        setUpTableView()
        fetchGroups()
        // Do any additional setup after loading the view.
    }
    
    func setupNavigationBar() {
        self.title = "My Groups"
        navigationController?.navigationBar.barTintColor = Constant.kColor.KDarkOrangeColor
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        self.navigationItem.setHidesBackButton(true, animated: true)
        let logoutBarButtonItem = UIBarButtonItem(title: "", style: .done, target: self, action: #selector(logoutUser))
        logoutBarButtonItem.setBackgroundImage(UIImage(named: "logout")?.withRenderingMode(.alwaysTemplate), for: .normal, barMetrics: .default)
        logoutBarButtonItem.tintColor = .white
        self.navigationItem.rightBarButtonItem  = logoutBarButtonItem
    }

    private func setUpFloatyButton() {
        floatyBtn.openAnimationType = .pop
        floatyBtn.overlayColor = UIColor.black.withAlphaComponent(0.2)
        floatyBtn.addItem(icon: UIImage(named: "addMember")) { (item) in
            CreateGroupPopUpVC.showPopup(parentVC: self)
            CreateGroupPopUpVC.groupCreatedHandler = { groupId in
                print("Group created..\(groupId)")
                self.fetchGroups()
            }
        }
        
        floatyBtn.addItem(icon: UIImage(named: "sos")) { (item) in

        }

        for item in floatyBtn.items {
            item.iconImageView.contentMode = .scaleAspectFit
        }
        
    }
    
    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "MemberTableViewCell", bundle: nil), forCellReuseIdentifier: "MemberTableViewCell")
    }
    
    func fetchGroups() {
        self.groupList.removeAll()
        if let userId = UserDefaults.standard.string(forKey: "userId") {
            LoadingOverlay.shared.showOverlay(view: UIApplication.shared.keyWindow ?? self.view)
            DatabaseManager.shared.fetchGroupsFor(userWith: userId) { (groups) in
                LoadingOverlay.shared.hideOverlayView()
                if let groups = groups {
                    DatabaseManager.shared.fetchGroupData(groups: groups) { (data) in
                        if let data = data {
                            self.groupList.append(data)
                            self.tableView.reloadData()
                        }
                    }
                }
            }
        }
    }
    
    @objc private func logoutUser() {
        LoadingOverlay.shared.showOverlay(view: UIApplication.shared.keyWindow ?? self.view)
        UserDefaults.standard.setValue(false, forKey: "loginStatus")
        UserDefaults.standard.setValue("", forKey: "groupId")
        UserDefaults.standard.setValue("", forKey: "userId")
        UserDefaults.standard.setValue("", forKey: "userName")
        UserDefaults.standard.setValue(nil, forKey: "groupId")
        UserDefaults.standard.synchronize()
        LoadingOverlay.shared.hideOverlayView()
        if let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController {
//            self.sendLoginStatusToWatch()
//            self.sendUserIdToWatch()
            self.navigationController?.setViewControllers([loginVC], animated: true)
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

extension GroupListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.groupList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MemberTableViewCell", for: indexPath) as? MemberTableViewCell
        let data = self.groupList[indexPath.row]
        cell?.nameLbl.text = data.name
        cell?.selectionStyle = .none
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let data = self.groupList[indexPath.row]
        if let vc = UIStoryboard.sharedInstance.instantiateViewController(withIdentifier: "MemberListViewController") as? MemberListViewController {
            vc.groupId = data.id ?? ""
            vc.groupName = data.name ?? ""
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}

