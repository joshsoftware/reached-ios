//
//  LoginViewController.swift
//  FamilyTracker
//
//  Created by Mahesh on 16/03/21.
//

import UIKit
import FirebaseAuth
import GoogleSignIn
import Firebase
import WatchConnectivity

class LoginViewController: UIViewController {

    var connectivityHandler = WatchSessionManager.shared
    private var ref: DatabaseReference!
    private var currentUserProfileUrl: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.barTintColor = Constant.kColor.KDarkOrangeColor
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        ref = Database.database().reference()
        if UserDefaults.standard.bool(forKey: "loginStatus") == true {
            if UserDefaults.standard.string(forKey: "groupId") ?? "" != "" {
                if let vc = UIStoryboard.sharedInstance.instantiateViewController(withIdentifier: "MemberListViewController") as? MemberListViewController {
                    vc.groupId = UserDefaults.standard.string(forKey: "groupId") ?? ""
                    self.navigationController?.pushViewController(vc, animated: false)
                }
            } else {
//                if let vc = UIStoryboard.sharedInstance.instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController {
//                    self.navigationController?.pushViewController(vc, animated: false)
//                }
                if let userId = UserDefaults.standard.string(forKey: "userId") {
                    self.ref.observeSingleEvent(of: .value, with: { (snapshot) in
                        if(snapshot.exists()) {
                            print("Group already created")
                            if let groups = (snapshot.value as? NSDictionary)?.value(forKey: "groups") as? [String:Any] {
                                
                                var found = false
                                
                                for group in groups {
                                    if let data = group.value as? [String:Any] {
                                        if let members = (data as NSDictionary).value(forKey: "members") as? [Any] {
                                            for member in members {
                                                if let id = (member as! NSDictionary).value(forKey: "id") as? String {
                                                    if id == userId {
                                                        
                                                        found = true
                                                        if let vc = UIStoryboard.sharedInstance.instantiateViewController(withIdentifier: "MemberListViewController") as? MemberListViewController {
                                                            vc.groupId = group.key
                                                            self.navigationController?.pushViewController(vc, animated: false)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                if !found {
                                    self.navigateToHomeVC()
                                }
                            } else {
                                self.navigateToHomeVC()
                            }
                        } else {
                            print("Group not created")
                            self.navigateToHomeVC()
                        }
                    }) { (error) in
                        print(error.localizedDescription)
                    }
                }
            }
            return
        }
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance().delegate = self
        // Do any additional setup after loading the view.
    }
    
    private func navigateToHomeVC() {
        if let vc = UIStoryboard.sharedInstance.instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController {
            vc.currentUserProfileUrl = currentUserProfileUrl
            self.navigationController?.pushViewController(vc, animated: false)
        }
    }
    
    @IBAction func googleSignInPressed(_ sender: Any) {
         GIDSignIn.sharedInstance().signIn()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
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

extension LoginViewController: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        guard let auth = user.authentication else { return }
        let credentials = GoogleAuthProvider.credential(withIDToken: auth.idToken, accessToken: auth.accessToken)
        
        LoadingOverlay.shared.showOverlay(view: UIApplication.shared.keyWindow ?? self.view)
        
        Auth.auth().signIn(with: credentials) { (authResult, error) in
            
            LoadingOverlay.shared.hideOverlayView()
            
            if let error = error {
                print(error.localizedDescription)
                UserDefaults.standard.setValue(false, forKey: "loginStatus")
            } else {
                print("Login Successful.")
                if let user = authResult?.user {
                    self.ref.child("users").child(user.uid).setValue(["name": user.displayName, "email":user.email, "profileUrl": user.photoURL?.description ?? ""])
                    UserDefaults.standard.setValue(true, forKey: "loginStatus")
                    UserDefaults.standard.setValue(user.uid, forKey: "userId")
                    UserDefaults.standard.setValue(user.displayName, forKey: "userName")
                    self.currentUserProfileUrl = user.photoURL?.description
                    self.sendLoginStatusToWatch()
                    self.sendUserIdToWatch()
//                    if let vc = UIStoryboard.sharedInstance.instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController {
//                        self.navigationController?.pushViewController(vc, animated: false)
//                    }
                    if let userId = UserDefaults.standard.string(forKey: "userId") {
                        self.ref.observeSingleEvent(of: .value, with: { (snapshot) in
                            if(snapshot.exists()) {
                                print("Group already created")
                                if let groups = (snapshot.value as? NSDictionary)?.value(forKey: "groups") as? [String:Any] {
                                    
                                    var found = false
                                    
                                    for group in groups {
                                        if let data = group.value as? [String:Any] {
                                            if let members = (data as NSDictionary).value(forKey: "members") as? [Any] {
                                                for member in members {
                                                    if let id = (member as! NSDictionary).value(forKey: "id") as? String {
                                                        if id == userId {
                                                            
                                                            found = true
                                                            if let vc = UIStoryboard.sharedInstance.instantiateViewController(withIdentifier: "MemberListViewController") as? MemberListViewController {
                                                                vc.groupId = group.key
                                                                self.navigationController?.pushViewController(vc, animated: false)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    
                                    if !found {
                                        self.navigateToHomeVC()
                                    }
                                } else {
                                    self.navigateToHomeVC()
                                }
                            } else {
                                print("Group not created")
                                self.navigateToHomeVC()
                            }

                        }) { (error) in
                            print(error.localizedDescription)
                        }
                    }
                }
            }
            
        }
    }
    
    private func sendLoginStatusToWatch() {
        self.connectivityHandler.sendMessage(message: ["loginStatus" : true as AnyObject], errorHandler:  { (error) in
            print("Error sending message: \(error)")
        })
    }
    
    private func sendUserIdToWatch() {
        if let userId = UserDefaults.standard.string(forKey: "userId") {
            self.connectivityHandler.sendMessage(message: ["userId" : userId as AnyObject], errorHandler:  { (error) in
                print("Error sending message: \(error)")
            })
        }
    }
}
