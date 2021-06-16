//
//  MapViewController.swift
//  FamilyTracker
//
//  Created by Vijay Godse on 02/03/21.
//

import UIKit
import Firebase
import MapKit
import Contacts
import SDWebImage

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var safetyStatusLbl: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var memberDetailsView: UIView!
    @IBOutlet weak var groupsNameLbl: UILabel!
    @IBOutlet weak var safetyGroupStatusLbl: UILabel!
    @IBOutlet weak var groupDetailsView: UIView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var safeUnsafeButton: UIButton!

    private var ref: DatabaseReference!
    var memberList: [Members] = []
    var groupId: String = ""
    var userId: String = ""
    var groupName: String = ""
    var memberName: String = ""
    var memberId: String = ""
    var createdBy: String = ""
    var showAllGroupMembers = false
    var isFromSOSNotification = false
    var index: Int = 0
    var groupsCount: Int = 0
    var groupListHandler: ((_ index: Int) -> Void)?
    var addressList = [Place]()

    override func viewDidLoad() {
        super.viewDidLoad()
        handleButtons()
        setUp(groupId: self.groupId)
    }
    
    func setUp(groupId: String) {
        ref = Database.database().reference(withPath: "groups/\(groupId)")
        mapView.delegate = self
        mapView.mapType = .standard
        
        memberDetailsView.isHidden = showAllGroupMembers
        if showAllGroupMembers {
            groupDetailsView.addTopShadow(shadowColor: UIColor.gray, shadowOpacity: 0.5, shadowRadius: 3, offset: CGSize(width: 0.0, height : -5.0))
            backButton.setTitle("Show List", for: .normal)
            groupsNameLbl.text = groupName
        } else {
            memberDetailsView.addTopShadow(shadowColor: UIColor.gray, shadowOpacity: 0.5, shadowRadius: 3, offset: CGSize(width: 0.0, height : -5.0))
            backButton.setTitle("Back", for: .normal)
            if isFromSOSNotification {
                ProgressHUD.sharedInstance.show()
                DatabaseManager.shared.fetchGroupData(groups: [memberId:""]) { (groupData) in
                    ProgressHUD.sharedInstance.hide()
                    if let group = groupData {
                        let filterdMembers = (group.members?.filter { $0.id!.contains(self.memberId) } )! as [Members]
                        self.memberList.append(filterdMembers.first ?? Members())
                        self.memberName = self.memberList.first?.name ?? ""
                        if let userId = UserDefaults.standard.string(forKey: "userId") {
                            self.safeUnsafeButton.isHidden = (userId == self.memberId)
                        }
                        self.nameLbl.text = self.memberName
                        self.fetchCurrentAddress(member: self.memberList.first)
                        self.fetchAddress(memberId: self.memberList.first?.id ?? "", groupId: self.groupId)
                        self.showPinForMembersLocation()
                    }
                }
            } else {
                self.memberName = self.memberList.first?.name ?? ""
                self.nameLbl.text = self.memberName
                self.memberId = self.memberList.first?.id ?? ""
                if let userId = UserDefaults.standard.string(forKey: "userId") {
                    self.safeUnsafeButton.isHidden = (userId == self.memberId)
                }
                self.fetchCurrentAddress(member: self.memberList.first)
                self.fetchAddress(memberId: self.memberList.first?.id ?? "", groupId: self.groupId)
                self.showPinForMembersLocation()
            }
        }
        observeFirebaseRealtimeDBChanges()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.eventForEnterRegion(_:)), name: NSNotification.Name(rawValue: "eventForEnterRegion"), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(self.eventForExitRegion(_:)), name: NSNotification.Name(rawValue: "eventForExitRegion"), object: nil)

    }
    
    func fetchSafetyStatusFor(memberId: String?) {
        self.ref = Database.database().reference().child("users").child(memberId ?? "").child("sosState")
        self.ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()) {
                if let flag = snapshot.value as? Bool {
                    if flag {
                        if let userId = UserDefaults.standard.string(forKey: "userId") {
                            self.nameLbl.text = (userId == memberId) ? "You have send SOS!" : "\(self.memberName) needs help!"
                        }
                        self.nameLbl.textColor = UIColor.red
                        self.safeUnsafeButton.isSelected = true
                        self.safeUnsafeButton.isUserInteractionEnabled = true
                    }
                }
            }
        })
    }
    
    func fetchCurrentAddress(member: Members?) {
        if let lat = member?.lat, let long =  member?.long {
            let location = CLLocation(latitude: lat, longitude: long)
            location.fetchAddress { (name, city, country, error) in
                if error == nil {
                    let address =  (name ?? "")
                    let cityCountry =  (city ?? "") + ", " + (country ?? "")
                    self.safetyStatusLbl.text = address + ", " + cityCountry
                }
            }
        }
    }
    
    @objc func eventForEnterRegion(_ notification: NSNotification) {
        if let dict = notification.userInfo as NSDictionary? {
            if let region = dict["region"] as? String{
                self.presentAlert(withTitle: "Alert", message: "User enter region: \(region)") {
                    
                }
            }
        }
    }
    
    @objc func eventForExitRegion(_ notification: NSNotification) {
        if let dict = notification.userInfo as NSDictionary? {
            if let region = dict["region"] as? String{
                self.presentAlert(withTitle: "Alert", message: "User leave region: \(region)") {
                    
                }
            }
        }
    }
    
    func fetchAddress(memberId: String, groupId: String) {
        ProgressHUD.sharedInstance.show()
        DatabaseManager.shared.fetchAddressFor(userWith: memberId, groupId: groupId) { (response) in
            ProgressHUD.sharedInstance.hide()
            if let address = response {
                for (key, value) in address {
                    if let data = value as? NSDictionary {
                        var place = Place()
                        place.id = key as? String
                        place.groupId = self.groupId
                        place.lat = data["lat"] as? Double
                        place.long = data["long"] as? Double
                        place.address = data["address"] as? String
                        place.name = data["name"] as? String
                        place.radius = data["radius"] as? Double
                        self.addressList.append(place)
                    }
                }
            }
            self.getGeoFencing()
            self.fetchSafetyStatusFor(memberId: memberId)
        }
    }
    
    private func observeFirebaseRealtimeDBChanges() {
        //Observe updated value for member
        self.memberList.removeAll()
        self.ref.removeAllObservers()
        self.ref.child("/members").observe(.childChanged) { (snapshot) in
            if let value = snapshot.value as? NSMutableDictionary {
                self.familyMembersLocationUpdated(key: snapshot.key, value: value)
            }
        }
        
        if showAllGroupMembers {
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

        if showAllGroupMembers {
            if let index = self.memberList.firstIndex(where: {
                                                        $0.id == member.id }) {
                self.memberList[index] = member
                self.showPinForMembersLocation()
            }
        } else {
            if let index = self.memberList.firstIndex(where: {
            $0.id == member.id }) {
                self.memberList[index] = member
                self.showPinForMembersLocation()
            } else {
                self.memberList.append(member)
                self.showPinForMembersLocation()
            }
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
        self.showPinForMembersLocation()
        
    }
    
    private func familyMemberRemoved(value: NSMutableDictionary) {
        
        var member = Members()
        member.id = value["id"] as? String
        if let index = self.memberList.firstIndex(where: { $0.id == member.id }) {
            self.memberList.remove(at: index)
            self.showPinForMembersLocation()
        }
    }
    
    func showPinForMembersLocation() {
        let allAnnotations = self.mapView.annotations
        self.mapView.removeAnnotations(allAnnotations)
        
        for index in 0..<memberList.count {
            let item = memberList[index]
            
            if let latitude = item.lat,  let longitude = item.long {
                
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                
                let pin = MKPointAnnotation()
                pin.title = item.name ?? ""
                pin.subtitle = item.profileUrl ?? ""

                let location = CLLocation(latitude: latitude, longitude: longitude)
                location.fetchCityAndCountry { (name, city, error) in
                    if error == nil {
                        pin.subtitle = (name ?? "") + ", " + (city ?? "")
                    }
                }
                
                pin.coordinate = coordinate
                self.mapView.addAnnotation(pin)
                
                if self.memberList.count > 1 {
                    self.mapView.fitAll()
                } else {
                    if let latitudinalMeters = CLLocationDistance(exactly: 1000), let longitudinalMeters = CLLocationDistance(exactly: 1000) {
                        let region = MKCoordinateRegion( center: coordinate, latitudinalMeters: latitudinalMeters, longitudinalMeters: longitudinalMeters)
                        self.mapView.setRegion(self.mapView.regionThatFits(region), animated: true)
                    }
                }
            }
            
        }
        
        if memberList.count > 1 {
            self.mapView.showAnnotations(self.mapView.annotations, animated: true)
        }

    }
    
    @IBAction func showListBtnAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func sosBtnAction(_ sender: Any) {
        if let userId = UserDefaults.standard.string(forKey: "userId"), !userId.isEmpty {
            ProgressHUD.sharedInstance.show()
            DatabaseManager.shared.updateSOSFor(userWith: userId, sosState: true, completion: { response, error in
                ProgressHUD.sharedInstance.hide()
                if let err = error {
                    print(err)
                } else {
                    print("SOS updated....")
                    self.nameLbl.text = "You have send SOS!"
                    self.nameLbl.textColor = UIColor.red
                    self.safeUnsafeButton.isSelected = true
                    self.safeUnsafeButton.isUserInteractionEnabled = true
                }
            })
        } else {
            print("User is not logged in")
        }
    }
    
    @IBAction func nextBtnAction(_ sender: Any) {
        index = index + 1
        groupListHandler?(index)
        handleButtons()
    }
    
    @IBAction func previousBtnAction(_ sender: Any) {
        index = index - 1
        groupListHandler?(index)
        handleButtons()
    }
    
    @IBAction func safeUnsafetBtnAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        ProgressHUD.sharedInstance.show()
        DatabaseManager.shared.updateSOSFor(userWith: memberId, sosState: false, completion: { response, error in
            ProgressHUD.sharedInstance.hide()
            if let err = error {
                print(err)
            } else {
                print("SOS updated....")
                self.nameLbl.text = self.memberName
                self.nameLbl.textColor = UIColor.black
                self.safeUnsafeButton.isUserInteractionEnabled = false
            }
        })
    }
    
    func handleButtons() {
        previousButton.isEnabled = !(index == 0)
        nextButton.isEnabled = !(index == groupsCount - 1)
    }
}

extension MapViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else { return nil }

        let identifier = "AnnotationIdentifier"

        var view: CustomAnnotationView? = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? CustomAnnotationView
        if view == nil {
            view = CustomAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }
        
        view?.profileImageView.sd_setImage(with: URL(string: (annotation.subtitle ?? "") ?? ""), placeholderImage: UIImage(named: "userPlaceholder"))

        view?.centerOffset = CGPoint(x: 0, y: -35)
        
        return view
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let circleOverlay = overlay as? MKCircle else {
            return MKOverlayRenderer()
        }
        let circleRender = MKCircleRenderer(circle: circleOverlay)
        circleRender.strokeColor = UIColor.init(hexString: "#15CF00")
        circleRender.fillColor = UIColor.init(hexString: "#15CF00")
        circleRender.alpha = 0.1
        return circleRender
    }
    
}

extension MapViewController {
    
    func showNotification(title:String, message:String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.badge = 1
        content.sound = .default
        let request = UNNotificationRequest(identifier: "notifi", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    func monitorRegionAtLocation(center: CLLocationCoordinate2D, identifier: String, radius: Double ) {
        // Make sure the devices supports region monitoring.
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            // Register the region.
            let maxDistance = CLLocationDistance(radius)
            let region = CLCircularRegion(center: center,
                                          radius: maxDistance, identifier: identifier)
            region.notifyOnEntry = true
            region.notifyOnExit = true
            let circle = MKCircle(center: center, radius: maxDistance)
            mapView.addOverlay(circle)
        }
    }
    
    
    private func getGeoFencing() {
        let locationManager = UserLocationManager.shared
        locationManager.generateGeofenceRegion(geotificationDataList: self.addressList)
        
        for item in self.addressList {
            if let lat = item.lat, let long = item.long, let radius = item.radius {
                print("Your location with lat and long :- \(item)")
                let cordi = CLLocationCoordinate2D(latitude: lat, longitude: long)
                monitorRegionAtLocation(center: cordi, identifier: item.name ?? "Geofence", radius: radius)
            }
        }
    }
    
    private func render(_ location: CLLocation) {
        let coordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mapView.setRegion(region, animated: true)
        mapView.showsUserLocation = true
    }
}
