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
    let vc = UIStoryboard(name: "SignIn", bundle: nil).instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var panelConfiguration = PanelConfiguration(size: .fullScreen)
        panelConfiguration.enclosedNavigationBar = false
        panelManager.delegate = self
        
        self.embed(vc, inView: self.view)

        if !UserDefaults.standard.bool(forKey: "showIntro") {
            vc.view.isHidden = true
            panelManager.show(panel: panel, config: panelConfiguration)
            UIView.animate(withDuration: 1.0) {
                self.panelManager.expandPanel()
            }
            UserDefaults.standard.setValue(true, forKey: "showIntro")
        } else {
            vc.view.isHidden = UserDefaults.standard.bool(forKey: "loginStatus")
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.collapsePanel), name: NSNotification.Name(rawValue: "collapsePanelNotification"), object: nil)

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
    
    @objc func collapsePanel() {
        vc.view.isHidden = false
        self.panelManager.dismiss()
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

extension UIViewController {
    func embed(_ viewController:UIViewController, inView view:UIView){
        viewController.willMove(toParent: self)
        viewController.view.frame = view.bounds
        view.addSubview(viewController.view)
        self.addChild(viewController)
        viewController.didMove(toParent: self)
    }
}
