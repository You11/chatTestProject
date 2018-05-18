//
//  FriendsTableViewController.swift
//  chatTestProject
//
//  Created by Артем Шульпин on 13.05.2018.
//  Copyright © 2018 Артем Шульпин. All rights reserved.
//

import UIKit
import FirebaseUI

class FriendsTableViewController: UITableViewController, FUIAuthDelegate {
    
    //MARK: Properties
    private var friends = [User]()
    private var handle: AuthStateDidChangeListenerHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadFriends()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    @IBAction func signOut(_ sender: UIBarButtonItem) {
        let authUI = FUIAuth.defaultAuthUI()
        authUI?.delegate = self
        do {
            try authUI?.signOut()
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if (auth.currentUser == nil) {
                let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let newViewController = storyBoard.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
                self.present(newViewController, animated: true, completion: nil)
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Auth.auth().removeStateDidChangeListener(handle!)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return friends.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "FriendTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? FriendTableViewCell else {
            fatalError("The dequeued cell is not an instance of FriendTableViewCell.")
        }

        let friend = friends[indexPath.row]
        cell.friendNameLabel.text = friend.name

        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    //MARK: Private Methods
    private func loadFriends() {
        friends.removeAll()
        
        let db = Firestore.firestore()
        let currentUserId = Auth.auth().currentUser?.uid
        
        db.collection("users").document(currentUserId!).getDocument { (document, error) in
            let group = DispatchGroup()
            guard let friendsIds = document?.get("friends") as! [String]? else {
                return
            }
            for id in friendsIds {
                group.enter()
                db.collection("users").document(id).getDocument { (document, error) in
                    let friendName = document?.get("name") as! String
                    self.friends += [User(name: friendName)]
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self.tableView.reloadData()
            }
        }
    }
    
    @IBAction func unwindToFriendList(sender: UIStoryboardSegue) {
        if let addFriendViewController = sender.source as? AddFriendViewController, let friendId = addFriendViewController.friendIdTextField.text {
            
            let db = Firestore.firestore()
            let group = DispatchGroup()
            group.enter()
            db.collection("users").document("\(friendId)").getDocument { (document, error) in
                if let document = document, document.exists {
                    
                    let currentUserId = Auth.auth().currentUser?.uid
                    
                    db.collection("users").document(currentUserId!).getDocument { (document, error) in
                        var friends = document?.get("friends") as! [String]
                        friends += ["\(friendId)"]
                        
                        db.collection("users").document(currentUserId!).updateData([
                            "friends": friends
                        ]) { err in
                            if let err = err {
                                print("Error updating document: \(err)")
                                group.leave()
                            } else {
                                print("Document successfully updated")
                                group.leave()
                            }
                        }
                    }
                } else {
                    print("friend not found")
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self.loadFriends()
            }
        }
    }
}
