//
//  HistoryView.swift
//  Sora
//

import SwiftUI

private let cellDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "dd.MM.yy"
    return f
}()

struct HistoryView: View {
    let sessions: [ChatSessionItem]
    let onBack: () -> Void
    let onSelectChat: (ChatSessionItem) -> Void
    let onNewChat: () -> Void
    let onDeleteChat: (ChatSessionItem) -> Void
    let onRenameChat: (ChatSessionItem, String) -> Void
    
    @State private var contextMenuSession: ChatSessionItem?
    @State private var sessionToDelete: ChatSessionItem?
    @State private var sessionToRename: ChatSessionItem?
    @State private var renameText: String = ""
    
    var body: some View {
        ZStack {
            Color(hex: "#0D0D0F")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Nav bar: chevronLeft, History по центру экрана, PRO
                ZStack {
                    HStack {
                        Button(action: onBack) {
                            Image("chevronLeft")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                .foregroundColor(.white)
                                .frame(width: 48, height: 48)
                        }
                        
                        .background(Color(hex: "#1F2023"))
                        .cornerRadius(12)
                        Spacer()
                        Button(action: {}) {
                            HStack(spacing: 6) {
                                Text("PRO")
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundColor(.white)
                                Image("sparkles")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color(hex: "#1F2023"))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Text("History")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                if sessions.isEmpty {
                    emptyState
                } else {
                    listState
                }
            }
            .overlay {
                if contextMenuSession != nil {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture { contextMenuSession = nil }
                }
            }
            .overlay(alignment: .topTrailing) {
                if let session = contextMenuSession {
                    contextMenuView(session: session)
                }
            }
            .overlay {
                if let session = sessionToDelete {
                    DeleteChatAlertView(
                        onCancel: { sessionToDelete = nil },
                        onDelete: {
                            onDeleteChat(session)
                            sessionToDelete = nil
                        }
                    )
                }
            }
            .overlay {
                if let session = sessionToRename {
                    RenameChatAlertView(
                        title: session.title,
                        text: $renameText,
                        onCancel: {
                            sessionToRename = nil
                            renameText = ""
                        },
                        onOK: { newName in
                            let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty {
                                onRenameChat(session, trimmed)
                            }
                            sessionToRename = nil
                            renameText = ""
                        }
                    )
                }
            }
        }
    }
    
    private func contextMenuView(session: ChatSessionItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                contextMenuSession = nil
                renameText = session.title
                sessionToRename = session
            }) {
                HStack(spacing: 12) {
                    Text("Rename")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "pencil")
                        .font(.system(size: 17.6))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            Button(action: {
                contextMenuSession = nil
                sessionToDelete = session
            }) {
                HStack(spacing: 12) {
                    Text("Delete")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.red)
                    Spacer()
                    Image("redTrash")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(Color(hex: "#0C4CD6"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
        }
        .frame(width: 200)
        .background(Color(hex: "#29292A"))
        .cornerRadius(12)
        .padding(.top, 120)
        .padding(.trailing, 20)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("Oops, there's nothing here yet.")
                .font(.system(size: 22, weight: .regular))
                .foregroundColor(.white)
            Text("It's time to create something new!")
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            newChatButton
        }
    }
    
    private var listState: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(sessions) { session in
                        chatRow(session)
                    }
                }
                .padding(.horizontal, 20)
            }
            .frame(maxHeight: .infinity)
            
            newChatButton
        }
    }
    
    private func chatRow(_ session: ChatSessionItem) -> some View {
        ZStack(alignment: .trailing) {
            Button(action: { onSelectChat(session) }) {
                HStack(alignment: .center, spacing: 0) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(session.title)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(cellDateFormatter.string(from: session.createdAt))
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)
                    .padding(.trailing, 64)
                    .padding(.vertical, 15)
                }
                .background(Color(hex: "#1F2023"))
                .cornerRadius(13)
            }
            .buttonStyle(.plain)
            
            Button(action: {
                contextMenuSession = session
            }) {
                Image("threeDots")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 29, height: 29)
                    .foregroundColor(.white)
            }
            .padding(.trailing, 15)
        }
    }
    
    private var newChatButton: some View {
        Button(action: onNewChat) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .medium))
                Text("New chat")
                    .font(.system(size: 17, weight: .regular))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "#6CABE9"),
                        Color(hex: "#2F76BC")
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(28)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 80)
    }
}

#Preview {
    HistoryView(
        sessions: [
            ChatSessionItem(id: UUID(), title: "First message here.", createdAt: Date())
        ],
        onBack: {},
        onSelectChat: { _ in },
        onNewChat: {},
        onDeleteChat: { _ in },
        onRenameChat: { _, _ in }
    )
}
