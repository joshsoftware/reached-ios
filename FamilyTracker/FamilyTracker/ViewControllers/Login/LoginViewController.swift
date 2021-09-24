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
import AuthenticationServices
import CryptoKit

class LoginViewController: UIViewController {
    @IBOutlet var topView: UIView!
    fileprivate var currentNonce: String?
    fileprivate var displayName: String?
    
    @IBOutlet weak var stackView: UIStackView!
    var connectivityHandler = WatchSessionManager.shared
    private var ref: DatabaseReference!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.barTintColor = Constant.kColor.KDarkOrangeColor
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance().delegate = self

        setupLoginWithAppleButton()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        topView.roundBottom(radius: 10)
    }
    
    private func navigateToHomeVC() {
        if let groupId = UserDefaults.standard.string(forKey: "inviteGroupId") {
            JoinLinkManager.shared.joinGroupWith(groupId: groupId) {
                self.navigateToGroupListVC()
            }
            UserDefaults.standard.setValue(nil, forKey: "inviteGroupId")
        } else {
            DispatchQueue.main.async {
                if let vc = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController {
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
    
    private func navigateToGroupListVC() {
        DispatchQueue.main.async {
            if let vc = UIStoryboard.dashboardSharedInstance.instantiateViewController(withIdentifier: "MainViewController") as? MainViewController {
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
    
    private func setupLoginWithAppleButton() {
        if #available(iOS 13.2, *) {
            let signInWithAppleButton = ASAuthorizationAppleIDButton(authorizationButtonType: .signUp, authorizationButtonStyle: .white)
            signInWithAppleButton.addTarget(self, action: #selector(signInWithAppleButtonPressed), for: .touchUpInside)
            stackView.addArrangedSubview(signInWithAppleButton)

        } else {
            // Fallback on earlier versions

        }
    }

    @objc private func signInWithAppleButtonPressed() {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }

    private func sha256(_ input: String) -> String {
      let inputData = Data(input.utf8)
      let hashedData = SHA256.hash(data: inputData)
      let hashString = hashedData.compactMap {
        return String(format: "%02x", $0)
      }.joined()

      return hashString
    }
    
    private func randomNonceString(length: Int = 32) -> String {
      precondition(length > 0)
      let charset: Array<Character> =
          Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
      var result = ""
      var remainingLength = length

      while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
          var random: UInt8 = 0
          let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
          if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
          }
          return random
        }

        randoms.forEach { random in
          if remainingLength == 0 {
            return
          }

          if random < charset.count {
            result.append(charset[Int(random)])
            remainingLength -= 1
          }
        }
      }

      return result
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

extension LoginViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent .")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            
            self.displayName = "\(appleIDCredential.fullName?.givenName ?? "") \(appleIDCredential.fullName?.familyName ?? "")"
            // Initialize a Firebase credential.
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)
            // Sign in with Firebase.
            Auth.auth().signIn(with: credential) { (authResult, error) in
                if let error = error {
                    print(error.localizedDescription)
                    UserDefaults.standard.setValue(false, forKey: "loginStatus")
                    self.presentAlert(withTitle: "Alert", message: String(format: "Login failed with error !", error.localizedDescription)) {
                    }
                    LoadingOverlay.shared.hideOverlayView()
                } else {
                    print("Login Successful.")
                    if let user = authResult?.user {
                        UserDefaults.standard.setValue(true, forKey: "loginStatus")
                        UserDefaults.standard.setValue(user.uid, forKey: "userId")
                        UserDefaults.standard.setValue(self.displayName, forKey: "userName")
                        UserDefaults.standard.setValue("", forKey: "userProfileUrl")
                        
                        DatabaseManager.shared.fetchGroupsFor(userWith: user.uid) { (groups) in
                            LoadingOverlay.shared.hideOverlayView()
                            if groups?.allKeys.count ?? 0 > 0 {
                                self.ref = Database.database().reference()
                                self.ref.child("users").child(user.uid).setValue(["name": self.displayName ?? "", "email":user.email ?? "", "profileUrl": user.photoURL?.description ?? "", "groups": groups!])
                                self.navigateToGroupListVC()
                            } else {
                                self.ref = Database.database().reference()
                                self.ref.child("users").child(user.uid).setValue(["name": self.displayName ?? "", "email":user.email ?? "", "profileUrl": user.photoURL?.description ?? "", "groups": nil])
                                self.navigateToHomeVC()
                            }
                            DatabaseManager.shared.setDeviceTokenOnServer(userId: user.uid)
                        }
                    }
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
        print("Sign in with Apple errored: \(error)")
        self.presentAlert(withTitle: "Alert", message: String(format: "Login failed with error !", error.localizedDescription)) {
        }
        
    }
    
}

extension LoginViewController: ASAuthorizationControllerPresentationContextProviding {
    //For present window
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}


extension LoginViewController: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        guard let auth = user.authentication else { return }
        let credentials = GoogleAuthProvider.credential(withIDToken: auth.idToken, accessToken: auth.accessToken)
        
        ProgressHUD.sharedInstance.show()
        Auth.auth().signIn(with: credentials) { (authResult, error) in
            if let error = error {
                print(error.localizedDescription)
                UserDefaults.standard.setValue(false, forKey: "loginStatus")
                ProgressHUD.sharedInstance.hide()
                self.presentAlert(withTitle: "Alert", message: "Login failed!") {
                    
                }
            } else {
                print("Login Successful.")
                if let user = authResult?.user {
                    UserDefaults.standard.setValue(true, forKey: "loginStatus")
                    UserDefaults.standard.setValue(user.uid, forKey: "userId")
                    UserDefaults.standard.setValue(user.displayName ?? "", forKey: "userName")
                    UserDefaults.standard.setValue(user.photoURL?.description ?? "", forKey: "userProfileUrl")
                    UserDefaults.standard.setValue(user.email ?? "", forKey: "userEmailId")
                    //TODO - Change
                    self.sendLoginStatusToWatch()
                    DatabaseManager.shared.fetchGroupsFor(userWith: user.uid) { (groups) in
                        ProgressHUD.sharedInstance.hide()
                        if groups?.allKeys.count ?? 0 > 0 {
                            self.ref = Database.database().reference()
                            self.ref.child("users").child(user.uid).setValue(["name": user.displayName ?? "", "email":user.email ?? "", "profileUrl": user.photoURL?.description ?? "", "groups": groups!])
                            //TODO - Change
                            UserDefaults.standard.setValue(groups, forKey: "groups")
                            self.navigateToGroupListVC()
                        } else {
                            self.ref = Database.database().reference()
                            self.ref.child("users").child(user.uid).setValue(["name": user.displayName ?? "", "email":user.email ?? "", "profileUrl": user.photoURL?.description ?? "", "groups": nil])
                            //TODO - Change
                            self.navigateToHomeVC()
                        }
                        DatabaseManager.shared.setDeviceTokenOnServer(userId: user.uid)
                    }
                } else {
                    ProgressHUD.sharedInstance.hide()
                }
            }
            
        }
    }
    
    private func sendLoginStatusToWatch() {
        if let userId = UserDefaults.standard.string(forKey: "userId"), let userEmailId = UserDefaults.standard.string(forKey: "userEmailId") {
            self.connectivityHandler.sendMessage(message: ["loginStatus" : true as AnyObject, "userId" : userId as AnyObject, "userEmailId" : userEmailId as AnyObject], errorHandler:  { (error) in
                print("Error sending message: \(error)")
            })
        }
    }
}
