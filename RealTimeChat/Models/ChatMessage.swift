//
//  Models.swift
//  RealTimeChat
//
//  Created by Pinkesh Gajera on 06/06/25.
//

import Foundation

/// Represents a single chat message.
struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let timestamp: Date
    var isIncoming: Bool         // Determines message alignment (left = incoming, right = outgoing)
    var isPending: Bool          // True if message is queued due to no network
    var senderID: String
    var roomID: String
    
    init(
        id: UUID = UUID(),
        text: String,
        timestamp: Date = Date(),
        isIncoming: Bool = true,
        isPending: Bool = false,
        senderID: String,
        roomID: String
    ) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.isIncoming = isIncoming
        self.isPending = isPending
        self.senderID = senderID
        self.roomID = roomID
    }
}

