//
//  Message.swift
//  chatTestProject
//
//  Created by Артем Шульпин on 15.05.2018.
//  Copyright © 2018 Артем Шульпин. All rights reserved.
//

import Foundation
import MessageKit

class Message: MessageType {
    
    var sender: Sender
    
    var messageId: String
    
    var sentDate: Date
    
    var data: MessageData
    
    private init(sender: Sender, messageId: String, sentDate: Date, data: MessageData) {
        self.sender = sender
        self.messageId = messageId
        self.sentDate = sentDate
        self.data = data
    }
    
    convenience init(text: String, sender: Sender, messageId: String, sentDate: Date) {
        self.init(sender: sender, messageId: messageId, sentDate: sentDate, data: .text(text))
    }
    
    convenience init(emoji: String, sender: Sender, messageId: String, sentDate: Date) {
        self.init(sender: sender, messageId: messageId, sentDate: sentDate, data: .emoji(emoji))
    }
}
