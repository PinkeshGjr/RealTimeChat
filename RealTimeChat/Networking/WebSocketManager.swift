//
//  WebSocketManager.swift
//  RealTimeChat
//
//  Created by Pinkesh Gajera on 06/06/25.
//

import Foundation
import Starscream
import Combine

class WebSocketManager: ObservableObject {
    private var socket: WebSocket?
    @Published var isConnected: Bool = false
    @Published var receivedMessages: ChatMessage?

    static let shared = WebSocketManager()
    
    let availableUsers = ["User 1", "User 2"]
    var loginRole: String = ""
    
    private init() {
        loginRole = availableUsers.first ?? ""
        let url = URL(string: "wss://s14759.blr1.piesocket.com/v3/1?api_key=CbaGLlftVXNsyBpehCBkHV5Y7PcjuUJ9xhgcFJK9&notify_self=1")!
        //wss://s14759.blr1.piesocket.com/v3/1?api_key=CbaGLlftVXNsyBpehCBkHV5Y7PcjuUJ9xhgcFJK9&notify_self=1 P Test
        socket = WebSocket(request: URLRequest(url: url))
        socket?.delegate = self
        connect()
    }

    func connect() {
        socket?.connect()
    }

    func disconnect() {
        socket?.disconnect()
    }

    func sendMessage(_ message: ChatMessage) {
        guard isConnected else {
            print("Message queued in ViewModel, socket offline")
            return
        }

        if let jsonData = try? JSONEncoder().encode(message),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            socket?.write(string: jsonString)
        }
    }
}
extension WebSocketManager: WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
        case .connected:
            isConnected = true
            print("✅ WebSocket connected")

        case .disconnected(let reason, let code):
            isConnected = false
            print("❌ Disconnected: \(reason) (code: \(code))")

        case .text(let string):
            if let data = string.data(using: .utf8),
               var message = try? JSONDecoder().decode(ChatMessage.self, from: data) {
                message.isIncoming = true
                message.isPending = false
                DispatchQueue.main.async {
                    self.receivedMessages = message
                }
            }

        case .error(let error):
            print("⚠️ WebSocket error: \(error?.localizedDescription ?? "Unknown")")
            isConnected = false

        default:
            break
        }
    }
}
