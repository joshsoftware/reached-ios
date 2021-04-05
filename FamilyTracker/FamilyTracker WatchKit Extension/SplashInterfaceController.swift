//
//  SplashInterfaceController.swift
//  FamilyTracker WatchKit Extension
//
//  Created by Vijay Godse on 22/03/21.
//

import WatchKit
import Foundation


class SplashInterfaceController: WKInterfaceController {

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        sleep(1)
        self.presentController(withName: InterfaceController.name, context: nil)
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
