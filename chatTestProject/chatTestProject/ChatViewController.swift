//
//  ViewController.swift
//  chatTestProject
//
//  Created by Артем Шульпин on 13.05.2018.
//  Copyright © 2018 Артем Шульпин. All rights reserved.
//

import UIKit
import MessageKit

class ChatViewController: MessagesViewController {
    
    var messagesList: [Message] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        messagesList.append(Message(text: "123", sender: Sender(id: "2", displayName: "pidor"), messageId: "1", sentDate: Date.init()))
        messagesList.append(Message(text: "321", sender: Sender(id: "1", displayName: "meow"), messageId: "2", sentDate: Date.init()))
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ChatViewController: MessagesDataSource {
    func currentSender() -> Sender {
        return Sender(id: "1", displayName: "meow")
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
