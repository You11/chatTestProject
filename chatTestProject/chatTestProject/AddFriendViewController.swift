//
//  AddFriendViewController.swift
//  chatTestProject
//
//  Created by Артем Шульпин on 17.05.2018.
//  Copyright © 2018 Артем Шульпин. All rights reserved.
//

import UIKit
import FirebaseUI

class AddFriendViewController: UIViewController {

    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var friendIdTextField: UITextField!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var resultLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        resultLabel.isHidden = true
        saveButton.isEnabled = false
        searchButton.addTarget(self, action: #selector(checkValidation), for: .touchUpInside)
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        guard let button = sender as? UIBarButtonItem, button === saveButton else {
            return
        }
    }

    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func checkValidation() {
        let db = Firestore.firestore()
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            return
        }
        
        var success: Bool = false
        let group = DispatchGroup()
        group.enter()
        
        db.collection("users").document(currentUserId).getDocument { (document, error) in
            
            let typedFriendId = self.friendIdTextField.text
            let friends = document?.get("friends") as! [String: Bool]
            for friend in friends {
                if (typedFriendId == friend.key) {
                    self.resultLabel.text = "This friend is already added"
                    self.resultLabel.isHidden = false
                    success = false
                    group.leave()
                    return
                }
            }
            
            db.collection("users").document(typedFriendId!).getDocument { (document, error) in
                
                if (document?.exists)! {
                    success = true
                    group.leave()
                } else {
                    self.resultLabel.text = "Friend not found"
                    self.resultLabel.isHidden = false
                    success = false
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            if (success) {
                self.resultLabel.text = "Friend found"
                self.saveButton.isEnabled = true
            }
        }
    }
}
