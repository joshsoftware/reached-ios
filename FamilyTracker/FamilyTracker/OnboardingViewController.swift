//
//  OnboardingViewController.swift
//  FamilyTracker
//
//  Created by Mahesh on 07/05/21.
//

import UIKit
import Panels

class OnboardingViewController: UIViewController {
    lazy var panelManager = Panels(target: self)

    override func viewDidLoad() {
        super.viewDidLoad()
        let panel = UIStoryboard.instantiatePanel(identifier: "Intro")
        let panelConfiguration = PanelConfiguration(size: .oneThird)
        
        panelManager.show(panel: panel, config: panelConfiguration)
        // Do any additional setup after loading the view.
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