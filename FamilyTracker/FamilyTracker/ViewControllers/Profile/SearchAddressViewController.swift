//
//  SearchAddressViewController.swift
//  FamilyTracker
//
//  Created by Mahesh on 02/06/21.
//

import UIKit

class SearchAddressViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func nextBtnAction(_ sender: Any) {
        if let vc = UIStoryboard(name: "Profile", bundle: nil).instantiateViewController(withIdentifier: "SaveAddressViewController") as? SaveAddressViewController {
            self.navigationController?.pushViewController(vc, animated: true)
        }
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
