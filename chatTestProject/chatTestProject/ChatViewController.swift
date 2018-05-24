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

class ChatViewController: MessagesViewController {
    
    var messagesList: [Message] = []
    var currentChat: Chat? = nil
    var messageCount = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //check if null somehow
        guard let currentChat = self.currentChat else {
            return
        }
        
        let db = Firestore.firestore()
        db.collection("chats").document(currentChat.id).addSnapshotListener { (document, error) in
            self.messagesList.removeAll()
            
            let messagesFromFirestore = document?.get("messages") as! [[String: Any]]
            for message in messagesFromFirestore {
                let text = message["text"] as! String
                let sentDate = message["sentDate"] as! Timestamp
                let senderId = message["sender"] as! String
                
                self.messagesList.append(Message(text: text, sender: Sender(id: senderId, displayName: "user"), messageId: String(self.messageCount), sentDate: sentDate))
                
                self.messageCount += 1
            }
            
            self.messagesCollectionView.reloadData()
        }
        
        messageInputBar.sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    @objc private func sendMessage() {
        let db = Firestore.firestore()
        //check if null somehow
        guard let currentChat = self.currentChat?.id else {
            return
        }
//        let group = DispatchGroup()
//        group.enter()
        
        let messageText = messageInputBar.inputTextView.text as String
        let message = Message(text: messageText, sender: Sender(id: getCurrentUserId(), displayName: "user"), messageId: String(self.messageCount), sentDate: Timestamp.init())
        
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
                    //                group.leave()
                } else {
                    print("Message sent!")
                    //                group.leave()
                }
            }
        }
        
        messagesList.append(message)
        self.messageCount += 1
        
        messagesCollectionView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ChatViewController: MessagesDataSource {
    func currentSender() -> Sender {
        return Sender(id: getCurrentUserId(), displayName: "me")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messagesList[indexPath.section]
    }
    
    func numberOfMessages(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messagesList.count
    }
    
}

extension ChatViewController: MessagesDisplayDelegate {
    
}

extension ChatViewController: MessagesLayoutDelegate {
    func heightForLocation(message: MessageType, at indexPath: IndexPath, with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        
        //TODO: ?
        return CGFloat(50)
    }
    
}

private func getCurrentUserId() -> String {
    guard let currentUser = Auth.auth().currentUser?.uid else {
        fatalError("uid is nil")
    }
    return currentUser
}
