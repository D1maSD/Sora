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
    let chats: [Chat]
    let onBack: () -> Void
    let onSelectChat: (Chat) -> Void
    let onNewChat: () -> Void
    let onDeleteChat: (Chat) -> Void
    
    @State private var contextMenuChat: Chat?
    
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
                
                if chats.isEmpty {
                    emptyState
                } else {
                    listState
                }
            }
            .overlay {
                if let chat = contextMenuChat {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture { contextMenuChat = nil }
                }
            }
            .overlay(alignment: .topTrailing) {
                if let chat = contextMenuChat {
                    contextMenuView(chat: chat)
                }
            }
        }
    }
    
    private func contextMenuView(chat: Chat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                contextMenuChat = nil
                // TODO: Rename
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                    Text("Rename")
                        .font(.system(size: 17, weight: .regular))
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
                contextMenuChat = nil
                onDeleteChat(chat)
            }) {
                HStack(spacing: 12) {
                    Image("trash")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundColor(.red)
                    Text("Delete")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.red)
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
                LazyVStack(spacing: 0) {
                    ForEach(chats) { chat in
                        chatRow(chat)
                    }
                }
                .padding(.horizontal, 20)
            }
            .frame(maxHeight: .infinity)
            
            newChatButton
        }
    }
    
    private func chatRow(_ chat: Chat) -> some View {
        ZStack(alignment: .trailing) {
            Button(action: { onSelectChat(chat) }) {
                HStack(alignment: .center, spacing: 0) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(chat.title)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(cellDateFormatter.string(from: chat.createdAt))
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)
                    .padding(.trailing, 64)
                    .padding(.vertical, 15)
                }
                .background(Color(hex: "#1F2023"))
                .cornerRadius(20)
            }
            .buttonStyle(.plain)
            
            Button(action: {
                contextMenuChat = chat
            }) {
                Image("threeDots")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.white)
            }
            .padding(.trailing, 20)
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
        chats: [
            Chat(id: UUID(), messages: [
                Message(text: "First message here.", image: nil, videoURL: nil, isIncoming: false)
            ], createdAt: Date())
        ],
        onBack: {},
        onSelectChat: { _ in },
        onNewChat: {},
        onDeleteChat: { _ in }
    )
}
