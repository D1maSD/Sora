//
//  ContentView.swift
//  Sora
//

import SwiftUI

private let lastOpenedChatSessionIdKey = "lastOpenedChatSessionId"

struct ContentView: View {
    private let store = ChatStore.shared
    @ObservedObject private var ratingPrompt = RatingPromptService.shared
    @EnvironmentObject private var tokensStore: TokensStore
    @AppStorage(lastOpenedChatSessionIdKey) private var lastOpenedChatSessionIdRaw: String = ""

    @State private var currentChatId: UUID?
    @State private var currentChatMessages: [Message] = []
    @State private var showHistory = false
    @State private var isLoadingResponse = false
    @State private var generationChatId: UUID? = nil
    @State private var generationError: String?
    @State private var showGenerationErrorAlert = false
    @State private var historyIsEffectsMode = false
    @State private var showSettings = false
    @State private var sessionItems: [ChatSessionItem] = []
    @State private var showRatingPrompt = false
    @State private var hasRestoredLastSession = false
    @State private var showTokensPaywall = false

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
                        lastOpenedChatSessionIdRaw = item.id.uuidString
                        showHistory = false
                    },
                    onNewChat: {
                        currentChatId = nil
                        currentChatMessages = []
                        lastOpenedChatSessionIdRaw = ""
                        showHistory = false
                    },
                    onDeleteChat: { item in
                        store.deleteSession(sessionId: item.id)
                        sessionItems = store.fetchAllSessions()
                        if currentChatId == item.id {
                            currentChatId = nil
                            currentChatMessages = []
                        }
                        if lastOpenedChatSessionIdRaw == item.id.uuidString {
                            lastOpenedChatSessionIdRaw = ""
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
                    isLoadingResponse: $isLoadingResponse,
                    generationError: $generationError,
                    showGenerationErrorAlert: $showGenerationErrorAlert,
                    showLoadingInThisChat: isLoadingResponse && (currentChatId == generationChatId),
                    currentChatId: currentChatId,
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
                            generationChatId = sessionId
                            return sessionId
                        }
                        return nil
                    },
                    onGenerationStarted: { chatId in
                        generationChatId = chatId
                    },
                    onGenerationCompleted: { chatId, message in
                        if let cid = chatId {
                            let list = store.fetchMessages(sessionId: cid)
                            store.saveMessages(sessionId: cid, messages: list + [message])
                            if currentChatId == cid {
                                currentChatMessages = store.fetchMessages(sessionId: cid)
                            }
                        }
                        if message.videoURL != nil {
                            Task { @MainActor in
                                RatingPromptService.shared.incrementVideoGeneration()
                            }
                        }
                        isLoadingResponse = false
                        generationChatId = nil
                    },
                    onGenerationFailed: { _ in
                        isLoadingResponse = false
                        generationChatId = nil
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
        .onReceive(NotificationCenter.default.publisher(for: .chatCacheDidClear)) { _ in
            currentChatId = nil
            currentChatMessages = []
            lastOpenedChatSessionIdRaw = ""
            sessionItems = store.fetchAllSessions()
        }
        .onAppear {
            guard !hasRestoredLastSession else { return }
            hasRestoredLastSession = true
            if let id = UUID(uuidString: lastOpenedChatSessionIdRaw), !lastOpenedChatSessionIdRaw.isEmpty {
                let sessions = store.fetchAllSessions()
                if sessions.contains(where: { $0.id == id }) {
                    currentChatId = id
                    currentChatMessages = store.fetchMessages(sessionId: id)
                }
            }
        }
        .onChange(of: ratingPrompt.shouldShowRatingPrompt) { _, new in
            showRatingPrompt = new
        }
        .fullScreenCover(isPresented: $showRatingPrompt) {
            RatingPromptView(onDismiss: {
                RatingPromptService.shared.dismissPrompt()
                showRatingPrompt = false
            })
        }
        .fullScreenCover(isPresented: $showTokensPaywall) {
            PaywallTokensView(onDismiss: { showTokensPaywall = false })
                .environmentObject(tokensStore)
                .environmentObject(PurchaseManager.shared)
        }
        .alert("Generation failed", isPresented: $showGenerationErrorAlert) {
            Button("OK", role: .cancel) {
                if let err = generationError,
                   err.lowercased().contains("insufficient tokens amount") {
                    showTokensPaywall = true
                }
                generationError = nil
            }
        } message: {
            if let err = generationError {
                Text(err)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(TokensStore())
        .environmentObject(PurchaseManager.shared)
}
