//
//  InterfaceController.swift
//  FamilyTracker WatchKit Extension
//
//  Created by Vijay Godse on 02/03/21.
//

import WatchKit
import Foundation
import CoreLocation
import WatchConnectivity
import FirebaseDatabase
import FirebaseCore
import FirebaseAuth
import AuthenticationServices
import CryptoKit

class InterfaceController: BaseInterfaceController, NibLoadableViewController {
    @IBOutlet weak var welcomeToLabel: WKInterfaceLabel!
    @IBOutlet weak var logoImg: WKInterfaceImage!
    @IBOutlet weak var bottomGroup: WKInterfaceGroup!
    @IBOutlet weak var loginInfoGroup: WKInterfaceGroup!
    @IBOutlet weak var emailLabel: WKInterfaceLabel!
    @IBOutlet weak var signInAppleButton: WKInterfaceAuthorizationAppleIDButton!
    fileprivate var currentNonce: String?
    fileprivate var displayName: String?
    var userRefForDeviceToken: DatabaseReference!
    var isDataLoaded = false
    var groupCount: Int = 0

    override func awake(withContext context: Any?) {
        // Configure interface objects here.
        super.awake(withContext: context)
        userRefForDeviceToken = Database.database().reference()
        if UserDefaults.standard.bool(forKey: "loginStatus") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.animation(completion: {
                    self.fetchGroupsCount { (count) in
                        let isLogin = UserDefaults.standard.bool(forKey: "loginStatus")
                        self.handleNavigation(isLogin: isLogin, groupCount: count!)
                    }
                })
            }
        }
    }
    
    private func navigateToGroupList() {
        WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: InterfaceController.name, context: "" as AnyObject)])
    }

    @IBAction func signInWithAppleClicked() {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
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
    func animation(completion: @escaping () -> Void) {
        self.welcomeToLabel.setHidden(true)
        self.logoImg.setHidden(true)
        self.animate(withDuration: 0.5) {
            self.bottomGroup.setRelativeHeight(0.8, withAdjustment: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.loginInfoGroup.setHidden(false)
            if let userEmailId = UserDefaults.standard.string(forKey: "userEmailId") {
                self.emailLabel.setText(userEmailId)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                completion()
            }
        }
    }
    
    func reset() {
        self.welcomeToLabel.setHidden(false)
        self.logoImg.setHidden(false)
        self.bottomGroup.setHeight(40.0)
        self.loginInfoGroup.setHidden(true)
    }
}

extension InterfaceController: ASAuthorizationControllerDelegate {
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
                } else {
                    print("Login Successful.")
                    if let user = authResult?.user {
                        UserDefaults.standard.setValue(true, forKey: "loginStatus")
                        UserDefaults.standard.setValue(user.uid, forKey: "userId")
                        UserDefaults.standard.setValue(self.displayName, forKey: "userName")
                        UserDefaults.standard.setValue("", forKey: "userProfileUrl")
                        self.navigateToGroupList()
                    }
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
        print("Sign in with Apple errored: \(error)")
    }
    
}
