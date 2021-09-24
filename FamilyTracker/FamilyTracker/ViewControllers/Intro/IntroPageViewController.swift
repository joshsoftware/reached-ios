//
//  IntroPageViewController.swift
//  FamilyTracker
//
//  Created by Mahesh on 14/05/21.
//

import UIKit

class IntroPageViewController: UIViewController {
    @IBOutlet var bgImageView: UIImageView!
    @IBOutlet var infoImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subTitleLabel: UILabel!
    @IBOutlet var nextButton: UIButton!

    var index: Int = 0
    let data = ["Locating your all family members is now easy.", "Locate your Friends is now easy.", "Create Safe circle for Kids at multiple locations.", "Get timely alerts of your loved ones whereabouts."]
    var nextButtonClickHandler: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        bgImageView.image = UIImage(named: "onboarding_bg_\(index + 1)")!
        infoImageView.image = UIImage(named: "onboarding_\(index + 1)")!
        titleLabel.text = data[index]
        subTitleLabel.isHidden = (index != 2)
        nextButton.tag = index
        // Do any additional setup after loading the view.
    }
    
    @IBAction func nextButtonAction(_ sender: UIButton) {
        if sender.tag == 3 {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "collapsePanelNotification"), object: nil)
        } else {
            self.nextButtonClickHandler?()
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
