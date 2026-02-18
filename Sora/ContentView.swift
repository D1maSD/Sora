//
//  ContentView.swift
//  Sora
//

import SwiftUI

struct ContentView: View {
    private let store = ChatStore.shared
    
    @State private var currentChatId: UUID?
    @State private var currentChatMessages: [Message] = []
    @State private var showHistory = false
    @State private var historyIsEffectsMode = false
    @State private var showSettings = false
    @State private var sessionItems: [ChatSessionItem] = []
    
    var body: some View {
        Group {
            if showSettings {
                SettingsView(onBack: { showSettings = false })
            } else if showHistory {
                HistoryView(
                    sessions: sessionItems,
                    isEffectsMode: historyIsEffectsMode,
                    onBack: { showHistory = false },
                    onSelectChat: { item in
                        currentChatId = item.id
                        currentChatMessages = store.fetchMessages(sessionId: item.id)
                        showHistory = false
                    },
                    onNewChat: {
                        currentChatId = nil
                        currentChatMessages = []
                        showHistory = false
                    },
                    onDeleteChat: { item in
                        store.deleteSession(sessionId: item.id)
                        sessionItems = store.fetchAllSessions()
                        if currentChatId == item.id {
                            currentChatId = nil
                            currentChatMessages = []
                        }
                    },
                    onRenameChat: { item, newName in
                        store.renameSession(sessionId: item.id, customTitle: newName)
                        sessionItems = store.fetchAllSessions()
                    }
                )
                .onAppear {
                    sessionItems = store.fetchAllSessions()
                }
            } else {
                MainScreenView(
                    messages: $currentChatMessages,
                    onOpenHistory: { isEffectsMode in
                        historyIsEffectsMode = isEffectsMode
                        showHistory = true
                    },
                    onOpenSettings: { showSettings = true },
                    onFirstMessageSent: {
                        if currentChatId == nil, let firstUserText = currentChatMessages.first(where: { !$0.isIncoming })?.text {
                            let sessionId = store.createSession(firstMessageText: firstUserText)
                            store.saveMessages(sessionId: sessionId, messages: currentChatMessages)
                            currentChatId = sessionId
                        }
                    },
                    onDeleteChat: {
                        if let id = currentChatId {
                            store.deleteSession(sessionId: id)
                        }
                        currentChatId = nil
                        currentChatMessages = []
                    },
                    onPlusTapped: {
                        currentChatId = nil
                        currentChatMessages = []
                    }
                )
            }
        }
        .onChange(of: currentChatMessages) { _, newValue in
            if let id = currentChatId {
                store.saveMessages(sessionId: id, messages: newValue)
            }
        }
    }
}

#Preview {
    ContentView()
}
