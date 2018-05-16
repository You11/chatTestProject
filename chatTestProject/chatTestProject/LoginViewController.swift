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
    
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        present(FriendsTableViewController(), animated: true, completion: nil)
    }
    
    @objc func login(controller: UINavigationController) {
        let authUI = FUIAuth.defaultAuthUI()
        authUI?.delegate = self
        let authViewController = authUI!.authViewController()
        
        self.present(authViewController, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if (user != nil) {
                let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let newViewController = storyBoard.instantiateViewController(withIdentifier: "FriendsViewController") as! FriendsTableViewController
                self.present(newViewController, animated: true, completion: nil)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
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
