//
//  ProgressHUD.swift
//  FamilyTracker
//
//  Created by Mahesh on 07/06/21.
//

import UIKit
import Lottie

let SCREEN_WIDTH = UIScreen.main.bounds.size.width
let SIZE_CONSTANT = 375.0
let SCREEN_HEIGHT = UIScreen.main.bounds.size.height

class ProgressHUD: NSObject {
    static let sharedInstance = ProgressHUD()
    private var animationView: AnimationView?

    var container = UIView(frame: CGRect(x: 0, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT))
    var subContainer = UIView(frame: CGRect(x: 0, y: 0, width: SCREEN_WIDTH * 0.4, height: SCREEN_WIDTH * 0.4))
    
    override init() {
        //Main Container
        container.backgroundColor = UIColor.clear
        
        //Sub Container
        subContainer.layer.cornerRadius = 10.0
        subContainer.layer.masksToBounds = true
        subContainer.backgroundColor = UIColor.white
    }
    
    func addAnimationView(view: UIView) {
        animationView = .init(name: "Reached_Loader")
        animationView?.frame = CGRect(x: 0, y: 0, width: SCREEN_WIDTH * 0.4, height: SCREEN_WIDTH * 0.4)
        animationView?.contentMode = .scaleAspectFit
        animationView?.loopMode = .loop
        animationView?.animationSpeed = 0.5
        if view == container {
            animationView?.center = CGPoint(x: SCREEN_WIDTH / 2, y: SCREEN_HEIGHT / 2)
        }
        view.addSubview(animationView ?? UIView())
        animationView?.play()
        
        view.sendSubviewToBack(animationView ?? UIView())
    }
    
    func show() -> Void {
        container.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        addAnimationView(view: container)
        if let window = getKeyWindow() {
            window.addSubview(container)
        }
        self.container.alpha = 1.0
    }
    
    func showWithBackgroundView() {
        addAnimationView(view: container)
        if let window = getKeyWindow() {
            window.addSubview(container)
        }
        self.container.alpha = 1.0
    }
    
    func showWithLoader() -> Void {
        container.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        subContainer.center = CGPoint(x: SCREEN_WIDTH / 2, y: SCREEN_HEIGHT / 2)
        container.addSubview(subContainer)
        container.sendSubviewToBack(subContainer)
        addAnimationView(view: subContainer)
        if let window = getKeyWindow() {
            window.addSubview(container)
        }
        self.container.alpha = 1.0
    }
    
    func hide() {
        self.container.alpha = 0.0
        self.animationView?.stop()
        self.animationView?.removeFromSuperview()
        self.subContainer.removeFromSuperview()
        self.container.removeFromSuperview()
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
