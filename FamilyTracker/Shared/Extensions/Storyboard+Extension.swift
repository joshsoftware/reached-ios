//
//  Storyboard+Extension.swift
//  FamilyTracker
//
//  Created by Vijay Godse on 03/03/21.
//

import UIKit
extension UIStoryboard {
    public enum Storyboard: Int {
        case MainTvOS
        case MainiOS

        var filename: String {
            switch self {
            case .MainTvOS:
                return "MainTvOS"
            case .MainiOS:
                return "SignIn"
            }
        }
    }

    public convenience init(storyboard: Storyboard) {
        self.init(name: storyboard.filename, bundle: nil)
    }

    public convenience init(storyboard: Storyboard, bundle: Bundle?) {
        self.init(name: storyboard.filename, bundle: bundle)
    }

    //Util for Obj-C
    @objc func instantiate(controller: AnyClass) -> AnyObject? {
        let className = String(describing: controller.self)
        return self.instantiateViewController(withIdentifier: className)
    }

    public func instantiateViewController<T: UIViewController>() -> T {
        let className = String(describing: T.self)
        guard let vc = self.instantiateViewController(withIdentifier: className) as? T else {
            fatalError("Could not load view controller: \(className)")
        }
        return vc
    }
    
    class var sharedInstance: UIStoryboard {
        struct Singleton {
            #if os(iOS)
            static let instance = UIStoryboard(name: "SignIn", bundle: nil)
            #elseif os(tvOS)
            static let instance = UIStoryboard(name: "Main_tvOS", bundle: nil)
            #endif
        }
        return Singleton.instance
    }
    
    class var dashboardSharedInstance: UIStoryboard {
        struct Singleton {
            static let dashboardInstance = UIStoryboard(name: "Dashboard", bundle: nil)
        }
        return Singleton.dashboardInstance
    }
}
