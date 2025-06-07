//
//  ChatViewModel.swift
//  RealTimeChat
//
//  Created by Pinkesh Gajera on 06/06/25.
//
import Foundation
import Combine
import Network

class ChatViewModel: ObservableObject {
    @Published var conversations: [ChatConversation] = [ChatConversation(id: UUID(), roomID: "Chat Bot 1", senderID: WebSocketManager.shared.loginRole, messages: []),
                                                        ChatConversation(id: UUID(), roomID: "Chat Bot 2", senderID: WebSocketManager.shared.loginRole, messages: [])]
    @Published var isOnline: Bool = true
    
    let webSocketManager = WebSocketManager.shared
    private var cancellables = Set<AnyCancellable>()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    private var messageQueue: [ChatMessage] = []
    var hasHandledFirstPathCheck = false
    
    init() {
        setupNetworkMonitoring()
        bindWebSocket()
    }
    
    func updateLoginId(id: String) {
        conversations = [ChatConversation(id: UUID(), roomID: "Chat Bot 1", senderID: id, messages: []),
                         ChatConversation(id: UUID(), roomID: "Chat Bot 2", senderID: id, messages: [])]
    }
    
    func isMessagePendingToSync() -> Bool {
        for conversation in conversations {
            for message in conversation.messages {
                if !message.isPending {
                    continue
                }
                return true
            }
        }
        return false
    }
    
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                let newStatus = path.status == .satisfied
                let wasOffline = !self.isOnline
                if newStatus == false && wasOffline {
                    // Do not update state as it is same
                } else {
                    self.isOnline = newStatus
                }
                
                // Skip the first update (don't trigger anything on launch)
                if !self.hasHandledFirstPathCheck {
                    self.hasHandledFirstPathCheck = true
                    return
                }
                
                if self.isOnline {
                    self.webSocketManager.connect()
                    if wasOffline {
                        self.retryQueuedMessages()
                    }
                }
            }
        }
        monitor.start(queue: queue)
    }

    private func bindWebSocket() {
        webSocketManager.$receivedMessages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                if let message = message {
                    self?.updateConversations(with: message, isIncoming: true)
                }
            }
            .store(in: &cancellables)
    }
    
    func sendMessage(_ text: String, senderID: String, roomID: String) {
        let message = ChatMessage(
            id: UUID(),
            text: text,
            timestamp: Date(),
            isIncoming: false,
            isPending: !isOnline,
            senderID: senderID,
            roomID: roomID
        )
        
        updateConversations(with: message, isIncoming: false)
        
        if isOnline {
            webSocketManager.sendMessage(message)
        } else {
            messageQueue.append(message)
        }
    }
    
    private func retryQueuedMessages() {
        let messagesToSend = messageQueue
        messageQueue.removeAll()
        
        for message in messagesToSend {
            webSocketManager.sendMessage(message)
        }
    }
    
    private func updateConversations(with message: ChatMessage, isIncoming: Bool) {
        var message = message
        if message.senderID != WebSocketManager.shared.loginRole {
            if let index = conversations.firstIndex(where: { $0.roomID == message.roomID }) {
                conversations[index].hasUnreadMessages = false
                message.isIncoming = isIncoming
                conversations[index].messages.append(message)
                conversations[index].hasUnreadMessages = isIncoming
            }
        } else {
            if let index = conversations.firstIndex(where: { $0.roomID == message.roomID }) {
                if let messageIndex = conversations[index].messages.firstIndex(where: { $0.id == message.id }) {
                    conversations[index].messages[messageIndex].isPending = false
                }
            }
        }
    }
    
    func clearConversations() {
        messageQueue.removeAll()
    }
}
