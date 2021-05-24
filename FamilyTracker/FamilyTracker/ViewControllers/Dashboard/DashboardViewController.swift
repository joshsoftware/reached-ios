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
    
    private var visibleGroupIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        setUp()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    private func setUp() {
        setUpCollectionView()
        setUpLocationManager()
        fetchGroups()

        //TODO: get strings from localized file
        myGroupsLbl.text = "My Groups"
        showOnMapBtn.setTitle("Show on MAP", for: .normal)
        showOnMapBtn.backgroundColor = Constant.kColor.KAppOrangeShade1
        pageControl.hidesForSinglePage = true
    }
   
    private func setUpCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "GroupListCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "GroupListCollectionViewCell")
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)
        layout.minimumLineSpacing = spacing
        layout.minimumInteritemSpacing = spacing
        collectionView.setCollectionViewLayout(layout, animated: true)
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
    
    @IBAction func menuBtnAction(_ sender: Any) {
        revealViewController()?.revealSideMenu()
    }
    
    @IBAction func addGroupBtnAction(_ sender: Any) {
    }
    
    
    @IBAction func showOnMapBtnAction(_ sender: Any) {
        navigateToMap()
    }
    
    
    @IBAction func infoBtnAction(_ sender: Any) {
    }
    
    private func navigateToMap() {
        if let vc = UIStoryboard.sharedInstance.instantiateViewController(withIdentifier: "MapViewController") as? MapViewController {
            
            let isIndexValid = groupList.indices.contains(visibleGroupIndex)
            if isIndexValid {
                let group = groupList[visibleGroupIndex]
                vc.groupId = group.id ?? ""
                vc.toShowAllGroupMembers = true
            }
            self.navigationController?.pushViewController(vc, animated: false)
        }
    }
    
}

extension DashboardViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
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
        return cell ?? UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
                
        let numberOfItemsPerRow: CGFloat = 1
        let spacingBetweenCells: CGFloat = 30

        let totalSpacing = (2 * spacing) + (numberOfItemsPerRow * spacingBetweenCells) // Amount of total spacing in a row

        let width = (collectionView.frame.width - totalSpacing) / numberOfItemsPerRow
        
        return CGSize(width: width, height: collectionView.frame.size.height)
    }
    
    
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        pageControl.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
        self.collectionView.scrollToNearestVisibleCollectionViewCell()
        for cell in collectionView.visibleCells {
            let indexPath = collectionView.indexPath(for: cell)
            self.visibleGroupIndex = indexPath?.row ?? 0
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.collectionView.scrollToNearestVisibleCollectionViewCell()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offSet = scrollView.contentOffset.x
        let width = scrollView.frame.width
        let horizontalCenter = width / 2

        pageControl.currentPage = Int(offSet + horizontalCenter) / Int(width)
    }
}

extension DashboardViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        self.currentLocation = locValue
    }
}



extension UICollectionView {
    func scrollToNearestVisibleCollectionViewCell() {
        self.decelerationRate = UIScrollView.DecelerationRate.fast
        let visibleCenterPositionOfScrollView = Float(self.contentOffset.x + (self.bounds.size.width / 2))
        var closestCellIndex = -1
        var closestDistance: Float = .greatestFiniteMagnitude
        for i in 0..<self.visibleCells.count {
            let cell = self.visibleCells[i]
            let cellWidth = cell.bounds.size.width
            let cellCenter = Float(cell.frame.origin.x + cellWidth / 2)

            // Now calculate closest cell
            let distance: Float = fabsf(visibleCenterPositionOfScrollView - cellCenter)
            if distance < closestDistance {
                closestDistance = distance
                closestCellIndex = self.indexPath(for: cell)!.row
            }
        }
        if closestCellIndex != -1 {
            self.isPagingEnabled = false
            self.scrollToItem(at: IndexPath(row: closestCellIndex, section: 0), at: .centeredHorizontally, animated: true)
            self.isPagingEnabled = true
        }
    }
}