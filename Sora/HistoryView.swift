//
//  HistoryView.swift
//  Sora
//

import SwiftUI

struct HistoryView: View {
    let chats: [Chat]
    let onSelectChat: (Chat) -> Void
    let onNewChat: () -> Void
    
    var body: some View {
        ZStack {
            Image("phone")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Верхняя панель: тайтл и кнопка PRO
                HStack {
                    Text("History")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
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
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                if chats.isEmpty {
                    emptyState
                } else {
                    listState
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("No chats yet")
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
                        Button(action: { onSelectChat(chat) }) {
                            HStack {
                                Text(chat.title)
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color(hex: "#1F2023"))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
            .frame(maxHeight: .infinity)
            
            newChatButton
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
            .background(Color(hex: "#1F2023"))
            .cornerRadius(28)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 34)
    }
}

#Preview {
    HistoryView(
        chats: [
            Chat(id: UUID(), messages: [
                Message(text: "First message here.", image: nil, videoURL: nil, isIncoming: false)
            ])
        ],
        onSelectChat: { _ in },
        onNewChat: {}
    )
}
