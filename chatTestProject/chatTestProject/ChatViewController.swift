//
//  ViewController.swift
//  chatTestProject
//
//  Created by Артем Шульпин on 13.05.2018.
//  Copyright © 2018 Артем Шульпин. All rights reserved.
//

import UIKit
import MessageKit
import FirebaseUI

class ChatViewController: MessagesViewController, MessagesDisplayDelegate, MessagesLayoutDelegate, UISearchBarDelegate {
    
    var loadedMessagesList: [Message] = []
    var displayedMessagesList: [Message] = []
    var currentChat: Chat? = nil
    var loadedMessagesCount = 0
    lazy var searchButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(searchButtonClicked))
    lazy var searchBar = UISearchBar()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //sets title of dialog to friend's name
        title = currentChat?.name
        
        //set up search button
        navigationItem.rightBarButtonItem = searchButton

        //check if null somehow
        guard let currentChat = self.currentChat else {
            return
        }
        
        let db = Firestore.firestore()
        db.collection("chats").document(currentChat.id).addSnapshotListener { (document, error) in
            self.loadedMessagesList.removeAll()
            
            let messagesFromFirestore = document?.get("messages") as! [[String: Any]]
            for message in messagesFromFirestore {
                let text = message["text"] as! String
                let sentDate = message["sentDate"] as! Timestamp
                let senderId = message["sender"] as! String
                
                self.loadedMessagesList.append(Message(text: text, sender: Sender(id: senderId, displayName: "user"), messageId: String(self.loadedMessagesCount), sentDate: sentDate))
                
                self.loadedMessagesCount += 1
            }
            
            self.displayedMessagesList = self.loadedMessagesList
            self.messagesCollectionView.reloadData()
            
            self.messagesCollectionView.scrollToBottom()
        }
        
        messageInputBar.sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        searchBar.delegate = self
    }
    
    @objc private func sendMessage() {

        let db = Firestore.firestore()
        //check if null somehow
        guard let currentChat = self.currentChat?.id else {
            return
        }
        
        let messageText = messageInputBar.inputTextView.text as String
        let message = Message(text: messageText, sender: Sender(id: getCurrentUserId(), displayName: "user"), messageId: String(self.loadedMessagesCount), sentDate: Timestamp.init())
        
        db.collection("chats").document(currentChat).getDocument() { (document, error) in
            var messagesFromFirestore = document?.get("messages") as! [[String: Any]]
            let newMessage = [
                "text": messageText,
                "sentDate": message.sentDate,
                "sender": message.sender.id
                ] as [String : Any]
            messagesFromFirestore.append(newMessage)
            
            db.collection("chats").document(currentChat).setData([
                "messages": messagesFromFirestore
            ], merge: true) { err in
                if let err = err {
                    print("Error sending message: \(err)")
                } else {
                    print("Message sent!")
                }
            }
        }
        
        loadedMessagesList.append(message)
        displayedMessagesList.append(message)
        self.loadedMessagesCount += 1
        
        messagesCollectionView.reloadData()
        
        //Clear input view
        messageInputBar.inputTextView.text = ""
        
        messagesCollectionView.scrollToBottom()
    }
    
    @objc func searchButtonClicked(_ sender: UIBarButtonItem) {
        
        //show search bar
        navigationItem.titleView = searchBar
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelSearch))
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = nil
        searchBar.becomeFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("meow?")
        //performs search
        guard let needle = searchBar.text else {
            return
        }
        
        displayedMessagesList.removeAll()
        
        for (index, message) in loadedMessagesList.enumerated() {
            switch message.data {
            case .text(let text):
                if text.contains(needle) {
                    displayedMessagesList.append(loadedMessagesList[index])
                }
            case .emoji:
                return
            default:
                return
            }
        }
        
        messagesCollectionView.reloadData()
    }
    
    
    @objc private func cancelSearch() {
        searchBar.text = ""
        navigationItem.titleView = nil
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = searchButton
        displayedMessagesList = loadedMessagesList
        messagesCollectionView.reloadData()
        becomeFirstResponder()
        messagesCollectionView.scrollToBottom()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func heightForLocation(message: MessageType, at indexPath: IndexPath, with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return maxWidth
    }
}


extension ChatViewController: MessagesDataSource {
    func currentSender() -> Sender {
        return Sender(id: getCurrentUserId(), displayName: "me")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return displayedMessagesList[indexPath.section]
    }
    
    func numberOfMessages(in messagesCollectionView: MessagesCollectionView) -> Int {
        return displayedMessagesList.count
    }
    
}

private func getCurrentUserId() -> String {
    guard let currentUser = Auth.auth().currentUser?.uid else {
        fatalError("uid is nil")
    }
    return currentUser
}
