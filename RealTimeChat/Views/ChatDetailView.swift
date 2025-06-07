//
//  ChatDetailView.swift
//  RealTimeChat
//
//  Created by Pinkesh Gajera on 06/06/25.
//

import SwiftUI

struct ChatDetailView: View {
    @ObservedObject var viewModel: ChatViewModel
    let conversationID: UUID
    @State private var newMessage = ""
    
    // Computed conversation from ViewModel by ID
    var conversation: ChatConversation? {
        viewModel.conversations.first(where: { $0.id == conversationID })
    }
    var body: some View {
        VStack {
            if let conversation = conversation {
                if conversation.messages.isEmpty {
                    Spacer()
                    Text("No messages yet")
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    ScrollViewReader { proxy in
                        List {
                            ForEach(conversation.messages) { message in
                                HStack {
                                    if message.senderID != WebSocketManager.shared.loginRole {
                                        messageBubble(message, color: .gray.opacity(0.2), alignment: .leading)
                                        Spacer()
                                    } else {
                                        Spacer()
                                        messageBubble(message, color: .blue.opacity(0.7), alignment: .trailing)
                                    }
                                }
                                .id(message.id)
                            }
                        }
                        .onChange(of: conversation.messages.count) {
                            if let lastId = conversation.messages.last?.id {
                                withAnimation {
                                    proxy.scrollTo(lastId, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
            } else {
                Spacer()
                Text("Conversation not found")
                    .foregroundColor(.red)
                Spacer()
            }
            
            HStack {
                TextField("Type a message...", text: $newMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Send") {
                    sendMessage()
                }
                .disabled(newMessage.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
        .navigationTitle(conversation?.roomID ?? "Conversation")
        .onAppear {
            if let index = viewModel.conversations.firstIndex(where: { $0.id == conversationID }) {
                viewModel.conversations[index].hasUnreadMessages = false
            }
        }
    }
    
    @ViewBuilder
    private func messageBubble(_ message: ChatMessage, color: Color, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment) {
            Text(message.text)
                .padding()
                .background(color)
                .cornerRadius(12)
                .foregroundColor(.black)
            HStack {
                Text(message.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.gray)
                if message.isPending {
                    Text("Pending...")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
    }
    
    private func sendMessage() {
        let text = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        // Create the message (initially marked pending)
        let message = ChatMessage(
            id: UUID(),
            text: text,
            timestamp: Date(),
            isIncoming: false,
            isPending: !viewModel.isOnline,
            senderID: conversation?.senderID ?? "",
            roomID: conversation?.roomID ?? ""
        )
        
        // Append to local conversation
        if let index = viewModel.conversations.firstIndex(where: { $0.id == conversationID }) {
            viewModel.conversations[index].messages.append(message)
        }
        
        // Attempt to send via WebSocketManager
        viewModel.webSocketManager.sendMessage(message)
        
        // Clear text field
        newMessage = ""
    }
    
}
