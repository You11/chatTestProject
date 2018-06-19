//
//  FriendsTableViewController.swift
//  chatTestProject
//
//  Created by Артем Шульпин on 13.05.2018.
//  Copyright © 2018 Артем Шульпин. All rights reserved.
//

import UIKit
import FirebaseUI

class ChatsTableViewController: UITableViewController, FUIAuthDelegate {
    
    //MARK: Properties
    private var chats = [Chat]()
    private var handle: AuthStateDidChangeListenerHandle?
    private var chatListener: ListenerRegistration?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        loadChats()
        
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
        self.chatListener?.remove()
        Auth.auth().removeStateDidChangeListener(handle!)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return chats.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "ChatTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? ChatTableViewCell else {
            fatalError("The dequeued cell is not an instance of ChatTableViewCell.")
        }

        let chat = chats[indexPath.row]
        cell.chatNameLabel.text = chat.name
        //amount of unread messages
        if (chat.unreadMessagesCountForCurrentUser != 0) {
            cell.unreadMessagesNumberLabel.text = String(chat.unreadMessagesCountForCurrentUser)
        } else {
            cell.unreadMessagesNumberLabel.text = ""
        }

        return cell
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        switch(segue.identifier ?? "") {
            
        case "AddFriend":
            return
            
        case "ShowChat":
            guard let chatViewContoller = segue.destination as? ChatViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            guard let selectedCell = sender as? ChatTableViewCell else {
                fatalError("Unexpected sender: \(sender ?? "Identifier not found")")
            }
            
            guard let indexPath = tableView.indexPath(for: selectedCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            
            let selectedChat = chats[indexPath.row]
            chatViewContoller.currentChat = selectedChat
        default:
            fatalError("Unexpected Segue Identifier; \(segue.identifier ?? "Identifier not found")")
        }
    }

    //MARK: Private Methods
    private func loadChats() {
        chats.removeAll()
        
        let db = Firestore.firestore()
        let currentUserId = Auth.auth().currentUser?.uid
        
        //gets user info in firebase
        db.collection("users").document(currentUserId!).getDocument { (document, error) in
            let group = DispatchGroup()
            //all chat ids user is in
            guard let chatsIds = document?.get("chats_ids") as! [String: Bool]? else {
                return
            }
            
            var isChatUpdated = false
            
            for id in chatsIds {
                group.enter()
                
                var chatName: String = ""
                
                //TODO: Make it optimal
                //loads chat
                //id.key = id of chat room
                self.chatListener = db.collection("chats").document(id.key).addSnapshotListener { (chatDocument, error) in
                    self.chats.removeAll()
                    if (isChatUpdated == true) {
                        //TODO: Hack
                        group.enter()
                    }
                    
                    let chatUsers = chatDocument?.get("user_ids") as! [String: [String: Any]]
                    //if chat only for 2 users, sets chat name as friend name
                    if (chatUsers.count == 2) {
                        for user in chatUsers {
                            //runs only one time
                            if (user.key != currentUserId) {
                                db.collection("users").document(user.key).getDocument { (userDocument, error) in
                                    //friend name
                                    chatName = userDocument?.get("name") as! String
                                    let chat = Chat(id: id.key, name: chatName)
                                    chat.unreadMessagesCountForCurrentUser = self.getUnreadMessagesCount(document: chatDocument)
                                    self.chats += [chat]
                                    //TODO: crashes here sometimes
                                    group.leave()
                                }
                            }
                        }
                    } else {
                        chatName = ""
                        let chat = Chat(id: id.key, name: chatName)
                        chat.unreadMessagesCountForCurrentUser = self.getUnreadMessagesCount(document: chatDocument)
                        self.chats += [chat]
                        group.leave()
                    }
                    
                    group.notify(queue: .main) {
                        isChatUpdated = true
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }
    
    
    private func getUnreadMessagesCount(document: DocumentSnapshot?) -> Int {
        let users = document?.get("user_ids") as! [String: [String: Any]]
        for user in users {
            if (user.key == Auth.auth().currentUser?.uid) {
                let lastReadMessageNumber = user.value["lastReadChatMessageNumber"] as! Int
                let messages = document?.get("messages") as! [[String: Any]]
                var unreadMessageCount = messages.count - lastReadMessageNumber
                if (unreadMessageCount < 0) {
                    unreadMessageCount = 0
                }
                return unreadMessageCount
            }
        }
        
        fatalError("unread message count error")
    }
    
    //MARK: Unwind
    @IBAction func unwindToFriendList(sender: UIStoryboardSegue) {
        //adds friend
        if let addFriendViewController = sender.source as? AddFriendViewController, let friendId = addFriendViewController.friendIdTextField.text {
            
            let db = Firestore.firestore()
            let group = DispatchGroup()
            group.enter()
            db.collection("users").document("\(friendId)").getDocument { (document, error) in
                //checking if friend with id exists
                if let document = document, document.exists {
                    
                    let currentUserId = Auth.auth().currentUser?.uid
                    
                    db.collection("users").document(currentUserId!).getDocument { (document, error) in
                        
                        if (document == nil) {
                            return
                        }
                        
                        group.enter()
                        //add new chat
                        let ref = db.collection("chats").addDocument(data: [
                            "name": "",
                            "messages": [],
                            "user_ids": [
                                currentUserId!: true,
                                friendId: true
                            ]
                        ]) { err in
                            if let err = err {
                                print("Error updating adding chat: \(err)")
                                group.leave()
                            } else {
                                print("Chat added")
                                group.leave()
                            }
                        }
                        
                        group.enter()
                        //update user profile with new friend and chat id
                        db.collection("users").document(currentUserId!).setData([
                            "friends": [friendId: true],
                            "chats_ids": [ref.documentID: true]
                        ], merge: true) { err in
                            if let err = err {
                                print("Error updating friend list: \(err)")
                                group.leave()
                            } else {
                                print("Friend list updated")
                                group.leave()
                            }
                        }
                        
                        //update friend profile with new chat
                        group.enter()
                        db.collection("users").document(friendId).setData([
                            "chats_ids": [ref.documentID: true]
                        ], merge: true) { err in
                            if let err = err {
                                print("Error updating friend list: \(err)")
                                group.leave()
                            } else {
                                print("Friend list updated")
                                group.leave()
                            }
                        }
                        
                        group.leave()
                    }
                    
                } else {
                    print("Friend not found")
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self.loadChats()
            }
        }
    }
}


extension Dictionary {
    
    static func += (lhs: inout Dictionary, rhs: Dictionary) {
        lhs.merge(rhs) { (_, new) in new }
    }
}
