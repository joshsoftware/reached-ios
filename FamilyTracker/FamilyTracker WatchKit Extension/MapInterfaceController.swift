//
//  MapInterfaceController.swift
//  FamilyTracker
//
//  Created by Vijay Godse on 03/03/21.
//

import WatchKit
import Foundation
import MapKit
import WatchConnectivity
import Contacts

class MapInterfaceController: WKInterfaceController, NibLoadableViewController {
    
    @IBOutlet weak var mapView: WKInterfaceMap!
    @IBOutlet weak var namelabel: WKInterfaceLabel!
    @IBOutlet weak var addressLabel: WKInterfaceLabel!
    
    private var connectivityHandler = WatchSessionManager.shared
    private var timer = Timer()
    private let session = WCSession.default
    var groupId: String = ""

    var itemList: [Members] = [] {
        didSet {
            for index in 0..<itemList.count {
                let item = itemList[index]
                
                if let latitude = item.lat,  let longitude = item.long {
                    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    self.mapView.addAnnotation(coordinate, with: WKInterfaceMapPinColor.red)
//                    if #available(watchOSApplicationExtension 6.1, *) {
//                        self.mapView.setUserTrackingMode(.follow, animated: true)
//                        self.mapView.setShowsUserHeading(true)
//                        self.mapView.setShowsUserLocation(true)
//                    } else {
//                        // Fallback on earlier versions
//                    }

                    var region = MKCoordinateRegion()
                    region.center = coordinate
                    region.span.latitudeDelta = 0.005
                    region.span.longitudeDelta = 0.005
                    self.mapView.setRegion(region)
                    
                    if itemList.count == 1 {
                        namelabel.setText(item.name)
                        let location = CLLocation(latitude: latitude, longitude: longitude)
                        CLGeocoder().reverseGeocodeLocation(location, preferredLocale: nil) { (clPlacemark: [CLPlacemark]?, error: Error?) in
                            guard let place = clPlacemark?.first else {
                                print("No placemark from Apple: \(String(describing: error))")
                                return
                            }

                            let postalAddressFormatter = CNPostalAddressFormatter()
                            postalAddressFormatter.style = .mailingAddress
                            var addressString: String?
                            if let postalAddress = place.postalAddress {
                                addressString = postalAddressFormatter.string(from: postalAddress)
                                self.addressLabel.setText(addressString)
                            }
                        }
                    }
                }
                
            }
        }
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        guard let membersList = context as? [Members] else {
            return
        }
        itemList = membersList
        watchKitSetup()
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        groupId = UserDefaults.standard.value(forKey: "groupId") as? String ?? ""
        connectivityHandler.startSession()
        connectivityHandler.watchOSDelegate = self
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    private func watchKitSetup() {
        if (WCSession.isSupported()) {
            session.delegate = self
            session.activate()
            if session.isReachable {
                timer.invalidate()
            } else {
                setUpTimer()
            }
        }
    }
    
    private func setUpTimer() {
        timer.invalidate()
        // start the timer
        timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
    }
    
    // called every time interval from the timer
    @objc private func timerAction() {
        getMemberList()
    }
    
    private func getMemberList() {
        ApiClient.getFamilyMembersListWithLocations(groupId: groupId) { (result) in
            switch result {
                case .success(let result):
                    
                    if self.itemList.count > 1 {
                        self.itemList = result.members ?? []
                    } else {
                        if let filtered = result.members?.filter({ ($0.id?.contains(self.itemList.first?.id ?? "") ?? false) }) {
                            self.itemList = filtered
                        }
                    }
                    
                case .failure(let error):
                    print(error.description)
            }
        }
    }
    
}

extension MapInterfaceController: WatchOSDelegate {
    
    func applicationContextReceived(tuple: ApplicationContextReceived) {
    }
    
    
    func messageReceived(tuple: MessageReceived) {
        DispatchQueue.main.async() {
            WKInterfaceDevice.current().play(.notification)
            if let loginStatus = tuple.message["loginStatus"] as? Bool {
                UserDefaults.standard.setValue(loginStatus, forKey: "loginStatus")
                if !loginStatus {
                    self.pop()
                }
            }
            
            if let groupId = tuple.message["groupId"] as? String {
                UserDefaults.standard.setValue(groupId, forKey: "groupId")
            }
            
            if let _ = tuple.message["msg"] {
//                                print(msg as! [Members])
                //TODO: instead of API call, parse msg object to membersArray and use it
                self.getMemberList()
            }
            
        }
    }
    
}

extension MapInterfaceController: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            timer.invalidate()
        } else {
            setUpTimer()
        }
    }
}
