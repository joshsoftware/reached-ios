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

    var bgImage : UIImage = UIImage()
    var infoImage : UIImage = UIImage()

    override func viewDidLoad() {
        super.viewDidLoad()
        bgImageView.image = self.bgImage
        infoImageView.image = self.infoImage
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
