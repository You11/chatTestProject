//
//  LoginViewController.swift
//  chatTestProject
//
//  Created by Артем Шульпин on 16.05.2018.
//  Copyright © 2018 Артем Шульпин. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseUI

class LoginViewController: UIViewController, FUIAuthDelegate {
    
    //MARK: Parameters
    @IBOutlet weak var loginButton: UIButton!
    private var handle: AuthStateDidChangeListenerHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginButton.addTarget(self, action: #selector(login), for: .touchUpInside)
    }
    
    //after login
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        let db = Firestore.firestore()
        let friends: Array<String> = []
        if let user = authDataResult?.user {
            db.collection("users").document("\(user.uid)").getDocument { (document, error) in
                if let document = document, !document.exists {
                    //create new user
                    db.collection("users").document("\(user.uid)").setData([
                        "name": user.displayName ?? "",
                        "profile_image": user.photoURL ?? "",
                        "date_creation": NSDate.init(),
                        "friends": friends
                    ]) { err in
                        if let err = err {
                            fatalError(err.localizedDescription)
                        } else {
                            print("User created!")
                            self.present(FriendsTableViewController(), animated: true, completion: nil)
                        }
                    }
                }
            }
        } else {
            fatalError("login went wrong")
        }
    }
    
    //login into app
    @objc func login(controller: UINavigationController) {
        let authUI = FUIAuth.defaultAuthUI()
        authUI?.delegate = self
        let authViewController = authUI!.authViewController()
        
        self.present(authViewController, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if (user != nil) {
                let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let newViewController = storyBoard.instantiateViewController(withIdentifier: "NavigationController") as! UINavigationController
                self.present(newViewController, animated: true, completion: nil)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Auth.auth().removeStateDidChangeListener(handle!)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
