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
import FirebaseDatabase
import SDWebImage

class MapInterfaceController: WKInterfaceController, NibLoadableViewController {
    
    @IBOutlet weak var mapView: WKInterfaceMap!

    private var ref: DatabaseReference!
    private var selectedGroup: Group?
    var zoomRect = MKMapRect.null;

    var itemList: [Members] = [] {
        didSet {
            for index in 0..<itemList.count {
                let item = itemList[index]
                
                if let latitude = item.lat,  let longitude = item.long {
                    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    if let url = URL(string: item.profileUrl ?? "") {
                        SDWebImageDownloader.shared.downloadImage(with: url) { (image, _, _, _) in
                            
                            if let img = image, let roundedImage = ImageTools.imageWithRoundedCornerSize(cornerRadius: 35, usingImage: img) {
                                let bgImage = UIImage(named: "annotation_bg", in: Bundle(identifier: "com.joshsoftware.app.reached.watchkitapp"), with: nil)
                                let annotationImg = bgImage?.overlayWith(image: roundedImage.scaleImage(toSize: CGSize(width: 10, height: 10)) ?? UIImage(), posX: 3, posY: 3)
                                self.mapView.addAnnotation(coordinate, with: annotationImg, centerOffset: CGPoint(x: 0, y: -35))
                            }
         
                        }
                    } else {
                        let bgImage = UIImage(named: "annotation_bg", in: Bundle(identifier: "com.joshsoftware.app.reached.watchkitapp"), with: nil)
                        let annotation = UIImage(named: "userPlaceholder", in: Bundle(identifier: "com.joshsoftware.app.reached.watchkitapp"), with: nil)
                        let annotationImg = bgImage?.overlayWith(image: annotation?.scaleImage(toSize: CGSize(width: 10, height: 10)) ?? UIImage(), posX: 3, posY: 3)
                        self.mapView.addAnnotation(coordinate, with: annotationImg, centerOffset: CGPoint(x: 0, y: -35))
                    }
                    
                    let annotationPoint = MKMapPoint(coordinate)
                    let pointRect       = MKMapRect(x: annotationPoint.x, y: annotationPoint.y, width: 0.01, height: 0.01);
                    zoomRect            = zoomRect.union(pointRect);
                }
                self.mapView.setVisibleMapRect(zoomRect)
            }
        }
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        guard let (membersList, selectedGroup) = context as? ([Members], Group) else {
            return
        }
        self.selectedGroup = selectedGroup
        self.setUp()
        self.itemList.removeAll()
        if membersList.first?.lat != nil {
            self.itemList = membersList
        } else {
            if let groupId = selectedGroup.id, let memberId = membersList.first?.id {
                DatabaseManager.shared.fetchGroupData(groups: [groupId:""]) { (groupData) in
                    if let group = groupData {
                        let filterdMembers = (group.members?.filter { $0.id!.contains(memberId) } )! as [Members]
                        self.itemList.append(filterdMembers.first ?? Members())
                    }
                }
            }
        }
    }
    
    private func setUp() {
        if let selectedGroup = self.selectedGroup, let groupId = selectedGroup.id {
            ref = Database.database().reference(withPath: "groups/\(groupId)")
            observeFirebaseRealtimeDBChanges()
        }

    }
    
    private func observeFirebaseRealtimeDBChanges() {
        //Observe updated value for member
        self.ref.child("/members").observe(.childChanged) { (snapshot) in
            if let value = snapshot.value as? NSMutableDictionary {
                self.mapView.removeAllAnnotations()
                self.familyMembersLocationUpdated(key: snapshot.key, value: value)
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

        if let index = self.itemList.firstIndex(where: { $0.id == member.id }) {
            self.itemList[index] = member
        }
    }
    
    @IBAction func showListBtnAction() {
        self.pop()
    }
}

extension UIImage {

  func overlayWith(image: UIImage, posX: CGFloat, posY: CGFloat) -> UIImage {
    let newWidth = size.width < posX + image.size.width ? posX + image.size.width : size.width
    let newHeight = size.height < posY + image.size.height ? posY + image.size.height : size.height
    let newSize = CGSize(width: newWidth, height: newHeight)

    UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
    draw(in: CGRect(origin: CGPoint.zero, size: size))
    image.draw(in: CGRect(origin: CGPoint(x: posX, y: posY), size: image.size))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()

    return newImage
  }

}

extension UIImage {
    func scaleImage(toSize newSize: CGSize) -> UIImage? {
        var newImage: UIImage?
        let newRect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height).integral
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        if let context = UIGraphicsGetCurrentContext(), let cgImage = self.cgImage {
            context.interpolationQuality = .high
            let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: newSize.height)
            context.concatenate(flipVertical)
            context.draw(cgImage, in: newRect)
            if let img = context.makeImage() {
                newImage = UIImage(cgImage: img)
            }
            UIGraphicsEndImageContext()
        }
        return newImage
    }
}
