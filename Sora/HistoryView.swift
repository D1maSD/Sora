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
    /// true = открыт из режима effects: сверху CustomSwitch(photo/video), сетка эффектов
    let isEffectsMode: Bool
    let onBack: () -> Void
    let onSelectChat: (ChatSessionItem) -> Void
    let onNewChat: () -> Void
    let onDeleteChat: (ChatSessionItem) -> Void
    let onRenameChat: (ChatSessionItem, String) -> Void
    
    @State private var contextMenuSession: ChatSessionItem?
    @State private var sessionToDelete: ChatSessionItem?
    @State private var sessionToRename: ChatSessionItem?
    @State private var renameText: String = ""
    @State private var effectHistoryPhotoVideo: Int = 0 // 0 = photo, 1 = video
    @State private var selectedEffectMedia: IdentifiableMedia?
    @ObservedObject private var effectStore = EffectGenerationStore.shared
    
    var body: some View {
        ZStack {
            Color(hex: "#0D0D0F")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                historyNavBar
                if isEffectsMode {
                    effectsModeContent
                } else {
                    if sessions.isEmpty {
                        emptyState
                    } else {
                        listState
                    }
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
        .fullScreenCover(item: $selectedEffectMedia) { media in
            ImageViewer(media: media, onDismiss: { selectedEffectMedia = nil })
        }
    }
    
    // MARK: - Nav bar (общий для chat и effects)
    private var historyNavBar: some View {
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
    }
    
    // MARK: - Режим effects: CustomSwitch(photo/video) + вертикальная сетка как у dolls
    private var effectsModeContent: some View {
        VStack(spacing: 0) {
            CustomSwitch(options: ["photo", "video"], selection: $effectHistoryPhotoVideo)
//                .frame(width: 200)
                .padding(12)
                .background(Color(hex: "#1F2023"))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            
            let list = effectHistoryPhotoVideo == 0 ? effectStore.photoRecords : effectStore.videoRecords
            if list.isEmpty {
                VStack {
                    Spacer()
                    Text("Oops, there's nothing here yet.")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundColor(.white)
                    Text("Create effects to see them here.")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                }
            } else {
                effectHistoryGrid(records: list)
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    private func effectHistoryGrid(records: [EffectGenerationRecord]) -> some View {
        GeometryReader { geometry in
            let horizontalPadding: CGFloat = 20
            let spacing: CGFloat = 12
            let contentWidth = geometry.size.width - horizontalPadding * 2
            let cellWidth = (contentWidth - spacing) / 2
            let cellHeight = cellWidth * 1.58
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: [
                    GridItem(.fixed(cellWidth), spacing: spacing),
                    GridItem(.fixed(cellWidth), spacing: spacing)
                ], spacing: spacing) {
                    ForEach(records) { record in
                        EffectHistoryCardView(
                            record: record,
                            cellWidth: cellWidth,
                            cellHeight: cellHeight,
                            onTapSuccess: {
                                if case .success(let img) = record.status, let image = img {
                                    selectedEffectMedia = IdentifiableMedia(image: image, effectRecordId: record.id)
                                }
                            }
                        )
                    }
                }
                .frame(width: contentWidth)
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, 40)
            }
        }
        .frame(maxHeight: .infinity)
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

// MARK: - Карточка одной генерации в HistoryView (режим effects)
struct EffectHistoryCardView: View {
    let record: EffectGenerationRecord
    let cellWidth: CGFloat
    let cellHeight: CGFloat
    let onTapSuccess: () -> Void
    
    var body: some View {
        Group {
            switch record.status {
            case .processing:
                processingCard
            case .success(let image):
                if let img = image {
                    successCard(image: img)
                } else {
                    placeholderCard
                }
            case .error:
                errorCard
            }
        }
        .frame(width: cellWidth, height: cellHeight)
    }
    
    private var processingCard: some View {
        ZStack {
            Image("HistoryCard")
                .resizable()
                .scaledToFill()
                .frame(width: cellWidth, height: cellHeight)
                .clipped()
                .cornerRadius(12)
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                .frame(width: 32, height: 32)
            VStack {
                Spacer()
                HStack {
                    Text("Creating...")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.leading, 12)
                .padding(.bottom, 10)
            }
        }
    }
    
    private func successCard(image: UIImage) -> some View {
        Button(action: onTapSuccess) {
            ZStack(alignment: .bottomLeading) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: cellWidth, height: cellHeight)
                    .clipped()
                    .cornerRadius(12)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var placeholderCard: some View {
        ZStack {
            Image("HistoryCard")
                .resizable()
                .scaledToFill()
                .frame(width: cellWidth, height: cellHeight)
                .clipped()
                .cornerRadius(12)
        }
    }
    
    private var errorCard: some View {
        ZStack {
            Image("HistoryCard")
                .resizable()
                .scaledToFill()
                .frame(width: cellWidth, height: cellHeight)
                .clipped()
                .cornerRadius(12)
            VStack(spacing: 12) {
                Image("checkmarkRedWide")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                Text("Something went wrong")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

#Preview {
    HistoryView(
        sessions: [
            ChatSessionItem(id: UUID(), title: "First message here.", createdAt: Date())
        ],
        isEffectsMode: false,
        onBack: {},
        onSelectChat: { _ in },
        onNewChat: {},
        onDeleteChat: { _ in },
        onRenameChat: { _, _ in }
    )
}
