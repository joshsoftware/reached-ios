//
//  DashboardViewController.swift
//  FamilyTracker
//
//  Created by Vijay Godse on 13/05/21.
//

import UIKit
import Firebase
import CoreLocation
import SVProgressHUD
import Panels
import MSPeekCollectionViewDelegateImplementation

class DashboardViewController: UIViewController {
    
    @IBOutlet weak var myGroupsLbl: UILabel!
    @IBOutlet weak var addGroupBtn: UIButton!
    @IBOutlet weak var showOnMapBtn: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var infoBtn: UIButton!
    @IBOutlet weak var sosView: UIView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var menuBtn: UIButton!
    
    private let spacing: CGFloat = 20.0
    
    private var ref: DatabaseReference!
    private var groupList = [Group]()
    private var currentLocation : CLLocationCoordinate2D = CLLocationCoordinate2D()
    private let locationManager = CLLocationManager()
    private var connectivityHandler = WatchSessionManager.shared
    private var groups : NSDictionary = NSDictionary()
    private let groupId = UUID().uuidString
    
    lazy var panelManager = Panels(target: self)
    let panel = UIStoryboard.instantiatePanel(identifier: "Home")
    var behavior: MSCollectionViewPeekingBehavior!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        setUp()
        
        if let vc = panel as? Panelable & CreateGroupViewController {
            vc.endEditingHandler = { groupName in
                self.panelManager.dismiss()
                self.createGroup(groupName: groupName)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    private func setUp() {
        setUpCollectionView()
        setUpLocationManager()
        fetchGroups()

        //TODO: get strings from localized file
        myGroupsLbl.text = "My Groups"
        showOnMapBtn.backgroundColor = Constant.kColor.KAppOrangeShade1
        pageControl.hidesForSinglePage = true
    }
    
    func reloadDelegate() {
        behavior = MSCollectionViewPeekingBehavior(cellSpacing: 10, cellPeekWidth: 20, maximumItemsToScroll: 1, numberOfItemsToShow: 1, scrollDirection: .horizontal)
        collectionView.configureForPeekingBehavior(behavior: behavior)
        collectionView.reloadData()
    }
   
    private func setUpCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "GroupListCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "GroupListCollectionViewCell")
        reloadDelegate()
    }
    
    private func setUpLocationManager() {
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()

        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()

        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }
    
    private func fetchGroups() {
        self.groupList.removeAll()
        if let userId = UserDefaults.standard.string(forKey: "userId") {
            SVProgressHUD.show()
            DatabaseManager.shared.fetchGroupsFor(userWith: userId) { (groups) in
                SVProgressHUD.dismiss()
                if let groups = groups {
                    DatabaseManager.shared.fetchGroupData(groups: groups) { (data) in
                        if let data = data {
                            self.groupList.append(data)
                            self.collectionView.reloadData()
                        }
                    }
                }
            }
        }
    }
    
    func createGroup(groupName: String) {
        SVProgressHUD.show()
        if let userId = UserDefaults.standard.string(forKey: "userId") {
            let data = ["lat": self.currentLocation.latitude, "long": self.currentLocation.longitude, "name": "name", "lastUpdated": Date().currentUTCDate(), "profileUrl": "profileUrl"] as [String : Any]
            var memberArray : Array = Array<Any>()
            memberArray.append(data)

            self.ref.child("groups").child(self.groupId).setValue(["created_by": userId, "name": groupName])
            self.ref.child("groups").child(self.groupId).child("members").child(userId).setValue(data)
            
            if var dict = UserDefaults.standard.dictionary(forKey: "groups") {
                dict[self.groupId] = true
                self.ref.child("users").child(userId).child("groups").setValue(dict)
                UserDefaults.standard.setValue(dict, forKey: "groups")
            } else {
                let dict = [self.groupId: true]
                self.ref.child("users").child(userId).child("groups").setValue(dict)
                UserDefaults.standard.setValue(dict, forKey: "groups")
            }
            SVProgressHUD.dismiss()
            fetchGroups()
        }
    }
    
    @IBAction func menuBtnAction(_ sender: Any) {
        revealViewController()?.revealSideMenu()
    }
    
    @IBAction func addGroupBtnAction(_ sender: Any) {
        var panelConfiguration = PanelConfiguration(size: .custom(100.0))
        panelConfiguration.enclosedNavigationBar = false
        panelManager.delegate = self
        panelManager.show(panel: panel, config: panelConfiguration)
        panelManager.expandPanel()
        if let vc = panel as? Panelable & CreateGroupViewController {
            vc.textField.becomeFirstResponder()
        }
    }
    
    
    @IBAction func showOnMapBtnAction(_ sender: Any) {
        navigateToMap()
    }
    
    
    @IBAction func infoBtnAction(_ sender: Any) {
        
    }
    
    private func navigateToMap() {
        if let vc = UIStoryboard(name: "Dashboard", bundle: nil).instantiateViewController(withIdentifier: "MapViewController") as? MapViewController {
            
            let isIndexValid = groupList.indices.contains(pageControl.currentPage)
            if isIndexValid {
                let group = groupList[pageControl.currentPage]
                vc.groupId = group.id ?? ""
                vc.showAllGroupMembers = true
                vc.index = pageControl.currentPage
                vc.groupName = group.name ?? ""
                vc.groupsCount = groupList.count
            }
            vc.groupListHandler = { index in
                let selectedGroup = self.groupList[index]
                vc.groupName = selectedGroup.name ?? ""
                vc.setUp(groupId: selectedGroup.id ?? "")
            }
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
}

extension DashboardViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        setUpPageControl()
        return groupList.count
    }
    
    private func setUpPageControl() {
        pageControl.numberOfPages = groupList.count
        pageControl.currentPage = 0
        pageControl.transform = CGAffineTransform (scaleX: 1.2, y: 1.2)
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.pageIndicatorTintColor = .lightGray
        pageControl.currentPageIndicatorTintColor = .black
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GroupListCollectionViewCell", for: indexPath) as? GroupListCollectionViewCell
        
        let isIndexValid = groupList.indices.contains(indexPath.row)
        if isIndexValid {
            let group = groupList[indexPath.row]
            cell?.groupNameLbl.text = group.name
            cell?.initiateCell(groupId: group.id ?? "")
        }
        
        cell?.addMemberHandler = { groupId, groupName in
            if let vc = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "ShowQRCodeViewController") as? ShowQRCodeViewController {
                vc.groupId = groupId
                vc.groupName = groupName
                vc.iIsFromCreateGroupFlow = false
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
        
        cell?.onClickMemberHandler = { members in
            if let vc = UIStoryboard(name: "Dashboard", bundle: nil).instantiateViewController(withIdentifier: "MapViewController") as? MapViewController {
                
                let isIndexValid = self.groupList.indices.contains(indexPath.row)
                if isIndexValid {
                    let group = self.groupList[indexPath.row]
                    vc.groupId = group.id ?? ""
                    vc.showAllGroupMembers = false
                    vc.memberList = members
                }
                self.navigationController?.pushViewController(vc, animated: true)
            }
             
        }
        
        cell?.menuHandler = {
            if let vc = UIStoryboard(name: "Dashboard", bundle: nil).instantiateViewController(withIdentifier: "ManageGroupViewController") as? ManageGroupViewController {
                let group = self.groupList[indexPath.row]
                vc.memberList = group.members!
                vc.groupId = group.id ?? ""
                vc.groupName = group.name ?? ""
                vc.groupMemberUpdatedHandler = {
                    self.fetchGroups()
                }
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
        
        cell?.onClickMemberProfileHandler = { member in
            if let vc = UIStoryboard(name: "Profile", bundle: nil).instantiateViewController(withIdentifier: "ProfileViewController") as? ProfileViewController {
                let group = self.groupList[indexPath.row]
                vc.groupId = group.id ?? ""
                vc.member = member
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
        return cell ?? UICollectionViewCell()
    }
}

extension DashboardViewController: UICollectionViewDelegate {
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        behavior.scrollViewWillEndDragging(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        print(behavior.currentIndex)
        self.pageControl.currentPage = behavior.currentIndex
    }
}

extension DashboardViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        self.currentLocation = locValue
    }
}

extension DashboardViewController: PanelNotifications {
    func panelDidPresented() {
        if let vc = panel as? Panelable & CreateGroupViewController {
            vc.panelDidPresented()
        }
    }
    
    func panelDidCollapse() {
        if let vc = panel as? Panelable & CreateGroupViewController {
            vc.panelDismiss()
        }
    }
    
    func panelDidOpen() {
        if let vc = panel as? Panelable & CreateGroupViewController {
            vc.panelDidOpen()
        }
    }
}
