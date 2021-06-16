//
//  IntroViewController.swift
//  FamilyTracker
//
//  Created by Mahesh on 07/05/21.
//

import UIKit
import Panels

class IntroViewController: UIViewController, Panelable {
    @IBOutlet var headerHeight: NSLayoutConstraint!
    @IBOutlet var headerPanel: UIView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var pageControl: UIPageControl!

    var pageViewController: PageViewController? {
        didSet {
            pageViewController?.introDelegate = self
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let pageViewController = segue.destination as? PageViewController {
            self.pageViewController = pageViewController
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func panelDidPresented() {
        
    }
    
    func panelDidCollapse() {
        UIView.animate(withDuration: 0.5, animations: {
            self.imageView.transform = .identity
        })
    }
    
    func panelDidOpen() {
        UIView.animate(withDuration: 0.5, animations: {
            self.imageView.transform = CGAffineTransform(rotationAngle: (180.0 * .pi) / 180.0)
        })
    }
    
    @IBAction func skipButtonAction(_ sender: Any) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "collapsePanelNotification"), object: nil)
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

extension IntroViewController: PageViewControllerDelegate {
    func pageViewController(pageViewController: PageViewController, didUpdatePageCount count: Int) {
        self.pageControl.numberOfPages = count
    }
    
    func pageViewController(pageViewController: PageViewController, didUpdatePageIndex index: Int) {
        self.pageControl.currentPage = index
    }
}
