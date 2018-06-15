//
//  Chat.swift
//  chatTestProject
//
//  Created by Артем Шульпин on 24.05.2018.
//  Copyright © 2018 Артем Шульпин. All rights reserved.
//

import UIKit

class Chat {
    
    //MARK: Properties
    var id: String
    var name: String
    //amount of messages current user didn't read
    var unreadMessagesCountForCurrentUser: Int = 0
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}
