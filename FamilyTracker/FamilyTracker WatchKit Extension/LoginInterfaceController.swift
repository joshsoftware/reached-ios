//
//  LoginInterfaceController.swift
//  FamilyTracker WatchKit Extension
//
//  Created by Vijay Godse on 20/04/21.
//

import WatchKit
import Foundation
import FirebaseAuth
import AuthenticationServices
import CryptoKit
import FirebaseDatabase

class LoginInterfaceController: WKInterfaceController, NibLoadableViewController {
    
    @IBOutlet weak var signInGroup: WKInterfaceGroup!
    @IBOutlet weak var signInBtn: WKInterfaceButton!
    
    private var currentNonce: String?
    private var displayName: String?
    private var ref: DatabaseReference!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
   
        if UserDefaults.standard.bool(forKey: "loginStatus") == true, let userId = UserDefaults.standard.string(forKey: "userId"), !userId.isEmpty {
            self.navigateToGroupList()
        }
    }
    
    private func navigateToGroupList() {
        WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: InterfaceController.name, context: "" as AnyObject)])
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    @IBAction func signInBtnAction() {
        self.startSignInWithAppleFlow()
    }
    
    //MARK: Sign in with apple setup methods
    private func startSignInWithAppleFlow() {
      let nonce = randomNonceString()
      currentNonce = nonce
      let appleIDProvider = ASAuthorizationAppleIDProvider()
      let request = appleIDProvider.createRequest()
      request.requestedScopes = [.fullName, .email]
      request.nonce = sha256(nonce)

      let authorizationController = ASAuthorizationController(authorizationRequests: [request])
      authorizationController.delegate = self
//      authorizationController.presentationContextProvider = self
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

}

extension LoginInterfaceController: ASAuthorizationControllerDelegate {
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

//extension LoginInterfaceController: ASAuthorizationControllerPresentationContextProviding {
//    //For present window
//    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
//        return self.view.window!
//    }
//}
