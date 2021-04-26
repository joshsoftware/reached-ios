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

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.barTintColor = Constant.kColor.KDarkOrangeColor
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        ref = Database.database().reference()
        if UserDefaults.standard.bool(forKey: "loginStatus") == true {
            LoadingOverlay.shared.showOverlay(view: UIApplication.shared.keyWindow ?? self.view)
            if let userId = UserDefaults.standard.string(forKey: "userId") {
                self.setDeviceTokenOnServer(userId: userId)
                DatabaseManager.shared.fetchGroupsFor(userWith: userId) { (groups) in
                    LoadingOverlay.shared.hideOverlayView()
                    if groups?.allKeys.count ?? 0 > 0 {
                        self.navigateToGroupListVC()
                    } else {
                        self.navigateToHomeVC()
                    }
                    LoadingOverlay.shared.hideOverlayView()
                }
            }
        }
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance().delegate = self
        // Do any additional setup after loading the view.
    }
    
    private func navigateToHomeVC() {
        if let groupId = UserDefaults.standard.string(forKey: "inviteGroupId") {
            JoinLinkManager.shared.joinGroupWith(groupId: groupId) {
                self.navigateToGroupListVC()
            }
            UserDefaults.standard.setValue(nil, forKey: "inviteGroupId")
        } else {
            DispatchQueue.main.async {
                if let vc = UIStoryboard.sharedInstance.instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController {
                    self.navigationController?.pushViewController(vc, animated: false)
                }
            }
        }
    }
    
    private func navigateToGroupListVC() {
        DispatchQueue.main.async {
            if let vc = UIStoryboard.sharedInstance.instantiateViewController(withIdentifier: "GroupListViewController") as? GroupListViewController {
                self.navigationController?.pushViewController(vc, animated: false)
            }
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
            if let error = error {
                print(error.localizedDescription)
                UserDefaults.standard.setValue(false, forKey: "loginStatus")
                LoadingOverlay.shared.hideOverlayView()
            } else {
                print("Login Successful.")
                if let user = authResult?.user {
                    UserDefaults.standard.setValue(true, forKey: "loginStatus")
                    UserDefaults.standard.setValue(user.uid, forKey: "userId")
                    UserDefaults.standard.setValue(user.displayName ?? "", forKey: "userName")
                    UserDefaults.standard.setValue(user.photoURL?.description ?? "", forKey: "userProfileUrl")
                    self.sendLoginStatusToWatch()
                    self.sendUserIdToWatch()
                    DatabaseManager.shared.fetchGroupsFor(userWith: user.uid) { (groups) in
                        LoadingOverlay.shared.hideOverlayView()
                        if groups?.allKeys.count ?? 0 > 0 {
                            self.ref = Database.database().reference()
                            self.ref.child("users").child(user.uid).setValue(["name": user.displayName ?? "", "email":user.email ?? "", "profileUrl": user.photoURL?.description ?? "", "groups": groups!])
                            self.navigateToGroupListVC()
                        } else {
                            self.ref = Database.database().reference()
                            self.ref.child("users").child(user.uid).setValue(["name": user.displayName ?? "", "email":user.email ?? "", "profileUrl": user.photoURL?.description ?? "", "groups": nil])
                            self.navigateToHomeVC()
                        }
                        self.setDeviceTokenOnServer(userId: user.uid)
                    }
                } else {
                    LoadingOverlay.shared.hideOverlayView()
                }
            }
            
        }
    }
    
    private func setDeviceTokenOnServer(userId: String) {
        if let token = UserDefaults.standard.object(forKey: "deviceToken") as? String {
            self.ref.child("users").child(userId).child("token").child("phone").setValue(token)
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
