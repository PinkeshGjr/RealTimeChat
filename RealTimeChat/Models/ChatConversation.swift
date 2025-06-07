//
//  ChatConversation.swift
//  RealTimeChat
//
//  Created by Pinkesh Gajera on 06/06/25.
//

import Foundation
struct ChatConversation: Identifiable, Equatable {
    let id: UUID
    let roomID: String
    let senderID: String
    var messages: [ChatMessage]
    
    var latestMessage: ChatMessage? {
        messages.last
    }

    var hasUnreadMessages: Bool = false
}
