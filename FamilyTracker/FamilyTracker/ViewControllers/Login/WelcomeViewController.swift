//
//  WelcomeViewController.swift
//  FamilyTracker
//
//  Created by Mahesh on 13/05/21.
//

import UIKit
import Panels

class WelcomeViewController: UIViewController, PanelNotifications {
    lazy var panelManager = Panels(target: self)
    let panel = UIStoryboard.instantiatePanel(identifier: "Intro")

    override func viewDidLoad() {
        super.viewDidLoad()
        var panelConfiguration = PanelConfiguration(size: .fullScreen)
        panelConfiguration.enclosedNavigationBar = false
        panelManager.delegate = self
        
        panelManager.show(panel: panel, config: panelConfiguration)
        // Do any additional setup after loading the view.
    }
    
    func panelDidPresented() {
        if let vc = panel as? Panelable & IntroViewController {
            vc.panelDidPresented()
        }
    }
    
    func panelDidCollapse() {
        if let vc = panel as? Panelable & IntroViewController {
            vc.panelDidCollapse()
        }
    }
    
    func panelDidOpen() {
        if let vc = panel as? Panelable & IntroViewController {
            vc.panelDidOpen()
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
