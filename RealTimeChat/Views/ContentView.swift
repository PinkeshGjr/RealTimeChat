//
//  ContentView.swift
//  RealTimeChat
//
//  Created by Pinkesh Gajera on 06/06/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var newMessage = ""
    @State private var showNetworkError = false
    @State private var selectedConversationID: UUID?
    @State private var hasLostConnection = false
    @State private var isBackOnline = false
    
    @State private var selectedUser = "User 1"
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Select user to login")
                Picker("Sender", selection: $selectedUser) {
                    ForEach(WebSocketManager.shared.availableUsers, id: \.self) { user in
                        Text(user).tag(user)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: selectedUser) {
                    WebSocketManager.shared.loginRole = selectedUser
                    viewModel.updateLoginId(id: selectedUser)
                }
                
                if viewModel.conversations.isEmpty {
                    Spacer()
                    Text("No chats available")
                        .foregroundColor(.gray)
                        .padding()
                    Spacer()
                } else {
                    List(viewModel.conversations) { conversation in
                        NavigationLink(value: conversation.id) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(conversation.roomID)
                                    .font(.body)
                                    .lineLimit(1)
                                Text(conversation.latestMessage?.text ?? "No messages")
                                    .font(.body)
                                    .lineLimit(1)
                                HStack {
                                    Text(conversation.latestMessage?.timestamp.formatted(date: .abbreviated, time: .shortened) ?? "")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    if conversation.hasUnreadMessages {
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 8, height: 8)
                                    }
                                }
                            }
                        }
                    }
                }
                
                if !viewModel.isOnline &&  viewModel.hasHandledFirstPathCheck {
                    Text("No internet connection")
                        .foregroundColor(.red)
                        .padding(.top, 4)
                }
            }
            .navigationTitle("Chats")
            .navigationDestination(for: UUID.self) { id in
                ChatDetailView(viewModel: viewModel, conversationID: id)
            }
            .onReceive(viewModel.$isOnline) { isOnline in
                if viewModel.hasHandledFirstPathCheck {
                    showNetworkError = true
                }
            }
            .alert(isPresented: $showNetworkError) {
                   return Alert(
                       title: Text(viewModel.isOnline ? "Network is back" : "Network Error"),
                       message: Text(viewModel.isOnline ? "Your messages will be sync." :
                                        "Unable to connect to the server. Messages will be queued and sent when online."),
                       dismissButton: .default(Text("OK"))
                   )
            }
            .onChange(of: selectedConversationID) {
                if let id = selectedConversationID {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        selectedConversationID = id // trigger navigation
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
