//
//  CreateGroupViewController.swift
//  FamilyTracker
//
//  Created by Mahesh on 18/05/21.
//

import UIKit
import Panels

class CreateGroupViewController: UIViewController, Panelable {
    @IBOutlet var headerHeight: NSLayoutConstraint!
    @IBOutlet var headerPanel: UIView!
    @IBOutlet var textField: UITextField!
    @IBOutlet var groupNameView: UIView!

    var endEditingHandler: ((_ groupName: String) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func createGroupButtonAction(_ sender: Any) {
        if textField.text!.count > 0 {
            self.endEditingHandler?(textField.text ?? "")
        }
    }
    
    func panelDidPresented() {
        
    }
    
    func panelDidCollapse() {
        groupNameView.isHidden = true
    }
    
    func panelDidOpen() {
        groupNameView.isHidden = false
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

extension CreateGroupViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.text!.count > 0 {
            self.endEditingHandler?(textField.text ?? "")
        }
        return true
    }
}
