//
//  ProgressHUD.swift
//  FamilyTracker
//
//  Created by Mahesh on 07/06/21.
//

import UIKit
import Foundation

let SCREEN_WIDTH = UIScreen.main.bounds.size.width
let SIZE_CONSTANT = 375.0
let SCREEN_HEIGHT = UIScreen.main.bounds.size.height

class ProgressHUD: NSObject {
    static let sharedInstance = ProgressHUD()
    
    var container = UIView(frame: CGRect(x: 0, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT))
    var subContainer = UIView(frame: CGRect(x: 0, y: 0, width: SCREEN_WIDTH / 3.0, height: SCREEN_WIDTH / 4.0))
    var textLabel = UILabel()
    var activityIndicatorView = UIActivityIndicatorView()
    var blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    
    override init() {
        //Main Container
        container.backgroundColor = UIColor.clear
        
        //Sub Container
        subContainer.layer.cornerRadius = 5.0
        subContainer.layer.masksToBounds = true
        subContainer.backgroundColor = UIColor.clear
        
        //Activity Indicator
        activityIndicatorView.hidesWhenStopped = true
        
        //Text Label
        textLabel.textAlignment = .center
        textLabel.numberOfLines = 0
        textLabel.font = UIFont.systemFont(ofSize: 14.0, weight: .medium)
        textLabel.textColor = UIColor.darkGray
        
        //Blur Effect
        //always fill the view
        blurEffectView.frame = container.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    func show() -> Void {
        
        container.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        if #available(iOS 13.0, *) {
            activityIndicatorView.style = UIActivityIndicatorView.Style.large
        } else {
            // Fallback on earlier versions
        }
        activityIndicatorView.center = CGPoint(x: SCREEN_WIDTH / 2, y: SCREEN_HEIGHT / 2)
        activityIndicatorView.color = UIColor.white
        
        activityIndicatorView.startAnimating()
        container.addSubview(activityIndicatorView)
        if let window = getKeyWindow() {
            window.addSubview(container)
        }
        container.alpha = 0.0
        UIView.animate(withDuration: 0.5, animations: {
            self.container.alpha = 1.0
        })
    }
    
    func showWithBlurView() {
        
        //only apply the blur if the user hasn't disabled transparency effects
        if !UIAccessibility.isReduceTransparencyEnabled {
            container.backgroundColor = UIColor.clear
            container.addSubview(blurEffectView)
        } else {
            container.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        }
        
        if #available(iOS 13.0, *) {
            activityIndicatorView.style = UIActivityIndicatorView.Style.large
        } else {
            // Fallback on earlier versions
        }
        activityIndicatorView.center = CGPoint(x: SCREEN_WIDTH / 2, y: SCREEN_HEIGHT / 2)
        activityIndicatorView.color = UIColor.white
        
        activityIndicatorView.startAnimating()
        container.addSubview(activityIndicatorView)
        if let window = getKeyWindow() {
            window.addSubview(container)
        }
        container.alpha = 0.0
        UIView.animate(withDuration: 0.5, animations: {
            self.container.alpha = 1.0
        })
    }
    
    func hide() {
        
        UIView.animate(withDuration: 0.5, animations: {
            self.container.alpha = 0.0
        }) { finished in
            self.activityIndicatorView.stopAnimating()
            
            self.activityIndicatorView.removeFromSuperview()
            self.textLabel.removeFromSuperview()
            self.subContainer.removeFromSuperview()
            self.blurEffectView.removeFromSuperview()
            self.container.removeFromSuperview()
        }
    }
    
    private func getKeyWindow() -> UIWindow? {
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.connectedScenes
                .filter({$0.activationState == .foregroundActive})
                .map({$0 as? UIWindowScene})
                .compactMap({$0})
                .first?.windows
                .filter({$0.isKeyWindow}).first
            return window
        } else {
            // Fallback on earlier versions
            return UIWindow()
        }
    }
}
