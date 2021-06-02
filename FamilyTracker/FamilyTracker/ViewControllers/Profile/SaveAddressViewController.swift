//
//  SaveAddressViewController.swift
//  FamilyTracker
//
//  Created by Mahesh on 02/06/21.
//

import UIKit

class SaveAddressViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func saveBtnAction(_ sender: Any) {
        self.navigationController?.popToViewController(ofClass: ProfileViewController.self)
    }
    
    @IBAction func backBtnAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
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
