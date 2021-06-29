//
//  HomeInterfaceController.swift
//  FamilyTracker WatchKit Extension
//
//  Created by Mahesh on 21/06/21.
//

import UIKit
import WatchKit

class HomeInterfaceController: BaseInterfaceController, NibLoadableViewController {

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }
    
    @IBAction func logoutBtnAction() {
        let rootVC = WKExtension.shared().rootInterfaceController
        if let vc = rootVC as? InterfaceController {
            vc.reset()
        }
        self.logoutUser()
        self.updateDeviceTokenOnFirebase()
        self.popToRootController()
    }
}
