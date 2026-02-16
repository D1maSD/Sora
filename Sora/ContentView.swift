//
//  ContentView.swift
//  Sora
//

import SwiftUI

struct ContentView: View {
    @State private var chats: [Chat] = []
    @State private var currentChatId: UUID?
    @State private var currentChatMessages: [Message] = []
    @State private var showHistory = false
    @State private var showSettings = false
    
    var body: some View {
        Group {
            if showSettings {
                SettingsView(onBack: { showSettings = false })
            } else if showHistory {
                HistoryView(
                    chats: chats,
                    onBack: { showHistory = false },
                    onSelectChat: { chat in
                        currentChatId = chat.id
                        currentChatMessages = chat.messages
                        showHistory = false
                    },
                    onNewChat: {
                        currentChatId = nil
                        currentChatMessages = []
                        showHistory = false
                    },
                    onDeleteChat: { chat in
                        chats.removeAll { $0.id == chat.id }
                        if currentChatId == chat.id {
                            currentChatId = nil
                            currentChatMessages = []
                        }
                    },
                    onRenameChat: { chat, newName in
                        if let idx = chats.firstIndex(where: { $0.id == chat.id }) {
                            chats[idx].customTitle = newName
                        }
                    }
                )
            } else {
                MainScreenView(
                    messages: $currentChatMessages,
                    onOpenHistory: { showHistory = true },
                    onOpenSettings: { showSettings = true },
                    onFirstMessageSent: {
                        if currentChatId == nil {
                            let newChat = Chat(id: UUID(), messages: currentChatMessages, createdAt: Date())
                            chats.append(newChat)
                            currentChatId = newChat.id
                        }
                    },
                    onDeleteChat: {
                        if let id = currentChatId {
                            chats.removeAll { $0.id == id }
                            currentChatId = nil
                            currentChatMessages = []
                        }
                    }
                )
            }
        }
        .onChange(of: currentChatMessages) { newValue in
            if let id = currentChatId, let idx = chats.firstIndex(where: { $0.id == id }) {
                chats[idx].messages = newValue
            }
        }
    }
}

#Preview {
    ContentView()
}
