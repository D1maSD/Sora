//
//  MainScreenView.swift
//  Sora
//
//  Created by Dima Melnik on 2/12/26.
//

import SwiftUI
import AVKit
import AVFoundation
import Photos

// Обёртка для показа изображения или видео в fullScreenCover(item:)
struct IdentifiableMedia: Identifiable {
    let id = UUID()
    let image: UIImage?
    let videoURL: URL?
    /// ID записи в EffectGenerationStore — для кнопки Delete в ImageViewer (удалить из истории эффектов).
    let effectRecordId: UUID?
    
    init(image: UIImage? = nil, videoURL: URL? = nil, effectRecordId: UUID? = nil) {
        self.image = image
        self.videoURL = videoURL
        self.effectRecordId = effectRecordId
    }
}

// Для системного шаринга (UIActivityViewController)
struct ShareableItem: Identifiable {
    let id = UUID()
    let image: UIImage?
    let videoURL: URL?
    var activityItems: [Any] {
        var items: [Any] = []
        if let image = image { items.append(image) }
        if let url = videoURL { items.append(url) }
        return items
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Модель чата для History
struct Chat: Identifiable {
    let id: UUID
    var messages: [Message]
    let createdAt: Date
    var customTitle: String?
    
    init(id: UUID = UUID(), messages: [Message], createdAt: Date = Date(), customTitle: String? = nil) {
        self.id = id
        self.messages = messages
        self.createdAt = createdAt
        self.customTitle = customTitle
    }
    
    /// Первое предложение первого сообщения или customTitle (для тайтла ячейки)
    var title: String {
        if let custom = customTitle, !custom.isEmpty { return custom }
        guard let first = messages.first(where: { !$0.text.isEmpty }) else { return "New chat" }
        let trimmed = first.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let end = trimmed.firstIndex(of: ".") ?? trimmed.firstIndex(of: "!") ?? trimmed.firstIndex(of: "?") {
            return String(trimmed[..<end]).trimmingCharacters(in: .whitespaces)
        }
        return trimmed.isEmpty ? "New chat" : String(trimmed.prefix(50))
    }
}

// Модель сообщения
struct Message: Identifiable, Equatable {
    let id: UUID
    let text: String
    let image: UIImage?
    let videoURL: URL?
    var isIncoming: Bool // true = входящее (от Sora), false = исходящее (от пользователя)
    
    init(id: UUID = UUID(), text: String, image: UIImage? = nil, videoURL: URL? = nil, isIncoming: Bool) {
        self.id = id
        self.text = text
        self.image = image
        self.videoURL = videoURL
        self.isIncoming = isIncoming
    }
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }
}

// Кнопка выбора разрешения видео (720/1080); через @Binding текст обновляется реактивно при смене значения в меню.
struct VideoResolutionButtonView: View {
    @Binding var resolutionPx: Int
    let onTap: () -> Void
    var body: some View {
        let _ = print("[VideoResolutionButtonView] body, resolutionPx = \(resolutionPx)")
        return Button(action: onTap) {
            Text("\(resolutionPx)px")
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(.white)
                .frame(minWidth: 75, minHeight: 44, maxHeight: 44)
                .padding(.horizontal, 8)
                .background(Color(hex: "#3B3D40"))
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// Компонент для отображения исходящего сообщения
struct MessageView: View {
    let message: Message
    let maxWidth: CGFloat
    let onCopy: () -> Void
    let onDelete: () -> Void
    let onMediaTap: (() -> Void)?
    
    private var hasMedia: Bool { message.image != nil || message.videoURL != nil }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Фото сверху (если есть)
            if let image = message.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .cornerRadius(20)
                    .padding(.top, 25)
                    .padding(.horizontal, 25)
                    .onTapGesture { onMediaTap?() }
            }
            // Превью видео (если есть)
            else if let videoURL = message.videoURL {
                VideoPreviewView(url: videoURL)
                    .padding(.top, 25)
                    .padding(.horizontal, 25)
                    .onTapGesture { onMediaTap?() }
            }
            
            // Текст ниже фото/видео
            if !message.text.isEmpty {
                Text(message.text)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.white)
                    .padding(.horizontal, hasMedia ? 25 : 16)
                    .padding(.vertical, hasMedia ? 12 : 16)
                    .frame(maxWidth: hasMedia ? .infinity : nil, alignment: .leading)
                    .fixedSize(horizontal: !hasMedia, vertical: false)
            }
            
            // HStack с кнопками внизу
            HStack(spacing: 5) {
                if !hasMedia {
                    Spacer(minLength: 0)
                } else {
                    Spacer()
                }
                
                // Кнопка copy
                Button(action: onCopy) {
                    Image("copy")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 29, height: 29)
                        .foregroundColor(.white)
                }
                
                // Кнопка trash
                Button(action: onDelete) {
                    Image("trash")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 29, height: 29)
                        .foregroundColor(.white)
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
            .padding(.top, (message.text.isEmpty && hasMedia) ? 12 : 0)
            .padding(.leading, !hasMedia ? 16 : 0)
        }
        .background(Color(hex: "#1F2023"))
        .cornerRadius(24)
        .frame(maxWidth: hasMedia ? maxWidth : nil)
        .fixedSize(horizontal: !hasMedia, vertical: false)
        .frame(maxWidth: maxWidth, alignment: .trailing)
    }
}

// Компонент для отображения входящего сообщения (от Sora)
struct IncomingMessageView: View {
    let message: Message
    let maxWidth: CGFloat
    let onTrash: () -> Void
    let onDownload: () -> Void
    let onShare: () -> Void
    let onRefresh: () -> Void
    let onMediaTap: (() -> Void)?
    
    private var hasMedia: Bool { message.image != nil || message.videoURL != nil }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Фото сверху (если есть)
            if let image = message.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .cornerRadius(20)
                    .padding(.top, 17)
                    .padding(.horizontal, 22) //padding image inside of message
                    .onTapGesture { onMediaTap?() }
            }
            // Превью видео (если есть)
            else if let videoURL = message.videoURL {
                VideoPreviewView(url: videoURL)
                    .padding(.top, 17)
                    .padding(.horizontal, 22)
                    .onTapGesture { onMediaTap?() }
            }
            
            // Текст ниже фото/видео
            if !message.text.isEmpty {
                Text(message.text)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.white)
                    .padding(.horizontal, hasMedia ? 25 : 16)
                    .padding(.vertical, hasMedia ? 12 : 16)
                    .frame(maxWidth: hasMedia ? .infinity : nil, alignment: .leading)
                    .fixedSize(horizontal: !hasMedia, vertical: false)
            }
            
            // HStack с кнопками внизу
            HStack(spacing: 5) {
                //                if !hasMedia {
                //                    Spacer(minLength: 0)
                //                } else {
                //                    Spacer()
                //                }
                HStack(spacing: 5) {
                // Кнопка trash
                Button(action: onTrash) {
                    Image("trash")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 29, height: 29)
                        .foregroundColor(.white)
                }
                
                // Кнопка download
                Button(action: onDownload) {
                    Image("download")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 29, height: 29)
                        .foregroundColor(.white)
                }
                
                // Кнопка share
                Button(action: onShare) {
                    Image("share")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 29, height: 29)
                        .foregroundColor(.white)
                }
            }
                .padding(.leading, 20)
                
                // Spacer между share и refresh
                Spacer()
                
                // Кнопка refresh
                Button(action: onRefresh) {
                    Image("refresh")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 29, height: 29)
                        .foregroundColor(.white)
                }
                .padding(.trailing, 10)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
            .padding(.top, (message.text.isEmpty && hasMedia) ? 12 : 0)
            .padding(.leading, !hasMedia ? 16 : 0)
        }
        .background(Color(hex: "#1F2023"))
        .cornerRadius(24)
        .frame(maxWidth: hasMedia ? maxWidth : nil)
        .fixedSize(horizontal: !hasMedia, vertical: false)
        .frame(maxWidth: maxWidth, alignment: .leading)
    }
}

// Расширение для скругления только определенных углов
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct MainScreenView: View {
    @EnvironmentObject var tokensStore: TokensStore
    @Binding var messages: [Message]
    @Binding var isLoadingResponse: Bool
    @Binding var generationError: String?
    @Binding var showGenerationErrorAlert: Bool
    /// Показывать ProgressView только в той сессии, где запущена генерация.
    var showLoadingInThisChat: Bool = false
    /// Текущая сессия (nil = новый чат до создания).
    var currentChatId: UUID? = nil
    /// Bool = isEffectsMode (true когда выбран режим effects)
    var onOpenHistory: ((Bool) -> Void)? = nil
    var onOpenSettings: (() -> Void)? = nil
    /// Возвращает sessionId для нового чата (после создания сессии).
    var onFirstMessageSent: (() -> UUID?)? = nil
    var onGenerationStarted: ((UUID?) -> Void)? = nil
    var onGenerationCompleted: ((UUID?, Message) -> Void)? = nil
    var onGenerationFailed: ((UUID?) -> Void)? = nil
    var onDeleteChat: (() -> Void)? = nil
    var onPlusTapped: (() -> Void)? = nil
    
    @State private var chatEffectsSelection = 0 // 0 = chat, 1 = effects
    @State private var photoVideoSelection = 0 // 0 = photo, 1 = video
    @State private var videoResolutionPx: Int = 720
    @State private var showVideoResolutionMenu = false
    /// Открывал ли пользователь меню выбора разрешения (720/1080) — только тогда отправляем в fal/video-enhance.
    @State private var userDidOpenVideoResolutionMenu = false
    @State private var textFieldText = ""
    @State private var showAddPhotoSheet = false
    @State private var selectedImage: UIImage? = nil
    @State private var selectedVideoURL: URL? = nil
    @State private var imageFileName: String = ""
    @State private var isLoadingImage: Bool = false
    @State private var showStyleSheet = false
    @State private var selectedStyle: Int? = nil
    @State private var selectedStyleName: String? = nil // Сохраняем название выбранного стиля
    @State private var imageToView: IdentifiableMedia? = nil
    @State private var showDeleteChatAlert = false
    @State private var scrollBannerId: Int? = 0
    @State private var showEffectsList = false
    @State private var showTokensPaywall = false
    @State private var generationTask: Task<Void, Never>?
    @State private var shareItem: ShareableItem?
    @State private var showSaveError = false
    @State private var saveErrorText = ""
    @State private var regeneratingMessageId: UUID?
    @State private var effectsGroups: [EffectsGroupResponse] = []
    @State private var videoGroups: [VideoTemplatesGroupResponse] = []
    @State private var effectsLoading = false
    @State private var videoLoading = false
    @State private var effectCategoryForSeeAll: EffectCategoryPayload?
    @State private var effectPreviewPayload: EffectPreviewPayload?
    @State private var keyboardHeight: CGFloat = 0
    @State private var keyboardWillShowObserver: NSObjectProtocol?
    @State private var keyboardWillHideObserver: NSObjectProtocol?
    
    /// Высота зоны topSection в chat-режиме (firstRow + secondRow + spacing).
    private let chatTopSectionHeight: CGFloat = 170
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                // Фоновое изображение
                Image("phone")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                if chatEffectsSelection == 0 {
                    // Сообщения + input (без topSection в вертикальном layout)
                    VStack(spacing: 0) {
                        messagesSection
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        bottomSection
                            .offset(y: -keyboardHeight)
                    }
                    .frame(width: geo.size.width)
                    .padding(.top, chatTopSectionHeight)
                } else {
                    effectsContent
                        .frame(width: geo.size.width)
                        .padding(.top, chatTopSectionHeight)
                }
                
                // Единый абсолютно позиционированный header для chat/effects.
                topSection
                    .frame(width: geo.size.width + 30)
                    .offset(y: 50)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .ignoresSafeArea(.keyboard)
        }
        .ignoresSafeArea()
        .onAppear {
            keyboardWillShowObserver = NotificationCenter.default.addObserver(
                forName: UIResponder.keyboardWillShowNotification,
                object: nil,
                queue: .main
            ) { notification in
                if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    withAnimation(.easeOut(duration: 0.25)) {
                        keyboardHeight = frame.height - 30
                    }
                }
            }
            
            keyboardWillHideObserver = NotificationCenter.default.addObserver(
                forName: UIResponder.keyboardWillHideNotification,
                object: nil,
                queue: .main
            ) { _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = 0
                }
            }
        }
        .onDisappear {
            if let observer = keyboardWillShowObserver {
                NotificationCenter.default.removeObserver(observer)
                keyboardWillShowObserver = nil
            }
            if let observer = keyboardWillHideObserver {
                NotificationCenter.default.removeObserver(observer)
                keyboardWillHideObserver = nil
            }
        }
        .overlay {
            if showDeleteChatAlert {
                DeleteChatAlertView(
                    onCancel: { showDeleteChatAlert = false },
                    onDelete: {
                        showDeleteChatAlert = false
                        if let onDelete = onDeleteChat {
                            onDelete()
                        } else {
                            messages.removeAll()
                        }
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $showEffectsList) {
            EffectsListView(onBack: { showEffectsList = false })
        }
        .fullScreenCover(isPresented: $showTokensPaywall) {
            PaywallTokensView(onDismiss: { showTokensPaywall = false })
                .environmentObject(tokensStore)
                .environmentObject(PurchaseManager.shared)
        }
        .fullScreenCover(item: $effectCategoryForSeeAll) { payload in
            EffectCategoryFullView(
                title: payload.title,
                effects: payload.effects,
                videos: payload.videos,
                onBack: { effectCategoryForSeeAll = nil }
            )
        }
        .fullScreenCover(item: $effectPreviewPayload) { payload in
            EffectPreviewView(
                onBack: { effectPreviewPayload = nil },
                effectItems: payload.items,
                selectedEffectIndex: payload.selectedIndex,
                isVideo: payload.isVideo
            )
        }
        .alert("Save failed", isPresented: $showSaveError) {
            Button("OK", role: .cancel) { saveErrorText = "" }
        } message: {
            Text(saveErrorText)
        }
        .sheet(item: $shareItem) { item in
            if !item.activityItems.isEmpty {
                ShareSheet(activityItems: item.activityItems)
            }
        }
    }
    
    /// Меню выбора разрешения видео (720px / 1080px). Обновляет state через замыкание onSelect, чтобы значение гарантированно менялось в MainScreenView.
    private func videoResolutionMenuView(onSelect: @escaping (Int) -> Void, isPresented: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                isPresented.wrappedValue = false
                onSelect(720)
            }) {
                Text("720px")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 17)
            }
            .buttonStyle(.plain)
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            Button(action: {
                isPresented.wrappedValue = false
                onSelect(1080)
            }) {
                Text("1080px")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 17)
            }
            .buttonStyle(.plain)
        }
        .frame(width: 90)
        .background(Color(hex: "#3C3D40"))
        .cornerRadius(12)
    }
    
    // Верхняя часть с свитчерами и кнопками
    private var topSection: some View {
        VStack(spacing: 8) {
            firstRow
            secondRow
        }
    }
    
    private var effectsContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                effectsBannerSection
                    .padding(.top, 0)
                effectsDynamicSection
                    .padding(.bottom, 24)
            }
        }
        .task(id: "effects-\(photoVideoSelection)") {
            guard chatEffectsSelection == 1 else { return }
            if photoVideoSelection == 0 {
                await loadEffects()
            } else {
                await loadVideoTemplates()
            }
        }
    }
    
    private let effectsBannerData: [(imageName: String, title: String)] = [
        ("BannerOne", "Anime"),
        ("BannerTwo", "Baby Face"),
        ("BannerThree", "Cube World")
    ]
    
    // Горизонтальная коллекция баннеров при выборе effects (snap-to-center по ячейкам, spacing 20)
    private var effectsBannerSection: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let cellWidth = screenWidth * 0.8
            let sidePadding = (screenWidth - cellWidth) / 2
            let spacingBetweenCells: CGFloat = 20
            let cellHeight: CGFloat = cellWidth * 0.56
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: spacingBetweenCells) {
                    ForEach(Array(effectsBannerData.enumerated()), id: \.offset) { offset, item in
                        Button(action: {
                            let items = effectsBannerData.enumerated().map { idx, b in
                                EffectPreviewItem(id: idx, previewURL: "", title: b.title, imageName: b.imageName)
                            }
                            effectPreviewPayload = EffectPreviewPayload(
                                items: items,
                                selectedIndex: offset,
                                isVideo: photoVideoSelection == 1
                            )
                        }) {
                            ZStack(alignment: .bottomLeading) {
                                Image(item.imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: cellWidth, height: cellHeight)
                                Text(item.title)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.leading, 10)
                                    .padding(.bottom, 10)
                            }
                        }
                        .buttonStyle(.plain)
                        .frame(width: cellWidth, height: cellHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .id(offset)
                    }
                }
                .padding(.horizontal, sidePadding)
            }
            .scrollPosition(id: $scrollBannerId)
            .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
        }
        .frame(height: 220)
    }
    
    /// Динамический контент: Photo — группы эффектов, Video — группы видео-шаблонов
    private var effectsDynamicSection: some View {
        Group {
            if photoVideoSelection == 0 {
                if effectsLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding()
                        Spacer()
                    }
                    .frame(minHeight: 120)
                } else {
                    effectsGroupsContent
                }
            } else {
                if videoLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding()
                        Spacer()
                    }
                    .frame(minHeight: 120)
                } else {
                    videoGroupsContent
                }
            }
        }
    }
    
    private var effectsGroupsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(effectsGroups.enumerated()), id: \.element.id) { _, group in
                if let title = group.title, !title.isEmpty {
                    effectsSectionHeader(title: title) {
                        effectCategoryForSeeAll = EffectCategoryPayload(title: title, effects: group.effects, videos: nil)
                    }
                    effectCardsRow(effects: group.effects)
                }
            }
        }
        .padding(.top, 12)
    }
    
    private func effectsSectionHeader(title: String, onSeeAll: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 19, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            Button(action: onSeeAll) {
                HStack(spacing: 4) {
                    Text("See all")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.white)
                    Image("chevronRight")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(hex: "#2B2D30"))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 30)
    }
    
    private func effectCardsRow(effects: [EffectItemResponse]) -> some View {
        GeometryReader { geometry in
            let cellWidth = geometry.size.width * 0.3
            let cellHeight = cellWidth * 1.4 * 1.25
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(effects.enumerated()), id: \.element.id) { index, effect in
                        Button(action: {
                            let items = effects.map { EffectPreviewItem(id: $0.id, previewURL: $0.preview, title: $0.title) }
                            effectPreviewPayload = EffectPreviewPayload(items: items, selectedIndex: index, isVideo: false)
                        }) {
                            ZStack(alignment: .bottomLeading) {
                                CachedAsyncImage(
                                    urlString: effect.preview,
                                    failure: { AnyView(Rectangle().fill(Color(hex: "#2B2D30")).overlay(Image(systemName: "photo").foregroundColor(.white.opacity(0.5)))) }
                                )
                                .frame(width: cellWidth, height: cellHeight)
                                .clipped()
                                .cornerRadius(12)
                                if let t = effect.title, !t.isEmpty {
                                    Text(t)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                        .padding(.leading, 10)
                                        .padding(.bottom, 10)
                                }
                            }
                            .frame(width: cellWidth, height: cellHeight)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .frame(height: 245)
    }
    
    private var videoGroupsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(videoGroups.enumerated()), id: \.element.id) { _, group in
                if let title = group.title, !title.isEmpty {
                    effectsSectionHeader(title: title) {
                        effectCategoryForSeeAll = EffectCategoryPayload(title: title, effects: nil, videos: group.videos)
                    }
                    videoCardsRow(videos: group.videos)
                }
            }
        }
        .padding(.top, 12)
    }
    
    private func videoCardsRow(videos: [VideoTemplateItemResponse]) -> some View {
        GeometryReader { geometry in
            let cellWidth = geometry.size.width * 0.3
            let cellHeight = cellWidth * 1.4 * 1.25
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(videos.enumerated()), id: \.element.id) { index, video in
                        Button(action: {
                            let items = videos.map { EffectPreviewItem(id: $0.id, previewURL: $0.photo_preview, title: $0.title) }
                            effectPreviewPayload = EffectPreviewPayload(items: items, selectedIndex: index, isVideo: true)
                        }) {
                            ZStack(alignment: .bottomLeading) {
                                CachedAsyncImage(
                                    urlString: video.photo_preview,
                                    failure: { AnyView(Rectangle().fill(Color(hex: "#2B2D30")).overlay(Image(systemName: "video").foregroundColor(.white.opacity(0.5)))) }
                                )
                                .frame(width: cellWidth, height: cellHeight)
                                .clipped()
                                .cornerRadius(12)
                                VStack(alignment: .leading, spacing: 4) {
                                    if video.is_new == true {
                                        Text("NEW")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.white)
                                            .cornerRadius(4)
                                    }
                                    Text(video.title)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                }
                                .padding(.leading, 10)
                                .padding(.bottom, 10)
                            }
                            .frame(width: cellWidth, height: cellHeight)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .frame(height: 245)
    }
    
    private func loadEffects() async {
        effectsLoading = true
        effectsGroups = []
        videoGroups = [] // Не смешивать: при загрузке photo очищаем video
        defer { effectsLoading = false }
        do {
            effectsGroups = try await EffectsAPI.fetchEffects()
        } catch {
            print("[Effects] load effects error: \(error)")
        }
    }
    
    private func loadVideoTemplates() async {
        videoLoading = true
        videoGroups = []
        effectsGroups = [] // Не смешивать: при загрузке video очищаем photo
        defer { videoLoading = false }
        do {
            videoGroups = try await EffectsAPI.fetchVideoTemplates()
        } catch {
            print("[Effects] load video templates error: \(error)")
        }
    }
    
    // Первый ряд: chat/effects свитчер, кнопка +, градиентная кнопка 1000
    private var firstRow: some View {
        GeometryReader { geometry in
            let switchWidth: CGFloat = 175
            let switchPadding: CGFloat = 8
            let totalSwitchWidth = switchWidth + (switchPadding * 2)
            let sidePadding: CGFloat = 40
            let spacingBetweenElements: CGFloat = 4
            
            // Вычисляем ширину градиентной кнопки 1000
            let gradientButtonContentWidth: CGFloat = 50 + 8 + 32 // текст "1000" (~50) + spacing (8) + иконка (32)
            let gradientButtonPadding: CGFloat = 16 * 2 // padding horizontal
            let gradientButtonWidth = gradientButtonContentWidth + gradientButtonPadding
            
            // Вычисляем ширину кнопки +
            let totalSpacing = spacingBetweenElements * 2 // 2 отступа между 3 элементами
            let availableWidth = geometry.size.width - (sidePadding * 2) - totalSwitchWidth - gradientButtonWidth - totalSpacing
            let plusButtonWidth = availableWidth
            
            HStack(alignment: .center, spacing: 2) {
                // Свитчер chat/effects в контейнере
                CustomSwitch(
                    options: ["chat", "effects"],
                    selection: $chatEffectsSelection
                )
                .frame(width: switchWidth)
                .padding(switchPadding)
                .background(Color(hex: "#1F2023"))
                .cornerRadius(12)
                
                // Кнопка +
                Button(action: {if let onOpenSettings = onOpenSettings {
                    onOpenSettings()
                }}) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }
                .frame(width: plusButtonWidth + 25, height: 51)
                .background(Color(hex: "#1F2023"))
                .cornerRadius(12)
                .padding(.leading, 2)
                
                // Градиентная кнопка — баланс токенов (тап открывает paywall покупки токенов)
                Button(action: { showTokensPaywall = true }) {
                    HStack(spacing: 6) {
                        Text("\(tokensStore.tokens)")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.3)
                        
                        Image("sparkles")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
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
                    .cornerRadius(12)
                }
                .frame(width: gradientButtonWidth - 17, height: 42)
            }
            .padding(.leading, sidePadding)
            .padding(.trailing, sidePadding)
            
        }
        .frame(height: 71)
        .padding(.top, 20)
    }
    
    // Второй ряд: photo/video свитчер слева, кнопки справа
    private var secondRow: some View {
        GeometryReader { geometry in
            let baseSwitchWidth: CGFloat = 155
            let switchPadding: CGFloat = 8
            let sidePadding: CGFloat = 40
            let spacingBetweenButtons: CGFloat = 4
            let totalSpacing = spacingBetweenButtons * 3 // 3 отступа между 4 элементами
            let totalSwitchWidthBase = baseSwitchWidth + (switchPadding * 2)
            let availableWidth = geometry.size.width - (sidePadding * 2) - totalSwitchWidthBase - totalSpacing
            let buttonWidth = availableWidth / 3
            // При effects расширяем свитчер photo/video на ширину trash + plus + 2×spacing
            let extraWidthForEffects = 2 * buttonWidth + 2 * spacingBetweenButtons
            let switchWidth: CGFloat = chatEffectsSelection == 1 ? baseSwitchWidth + extraWidthForEffects : baseSwitchWidth
            let totalSwitchWidth = switchWidth + (switchPadding * 2)
            
            HStack(alignment: .center, spacing: spacingBetweenButtons) {
                // Свитчер photo/video
                CustomSwitch(
                    options: ["photo", "video"],
                    selection: $photoVideoSelection
                )
                .frame(width: switchWidth)
                .padding(switchPadding)
                .background(Color(hex: "#1F2023"))
                .cornerRadius(12)
                
                // Кнопки: plus, clockArrow, trash (trash и plus скрыты при effects)
                
                if chatEffectsSelection == 0 {
                    Button(action: {
                        showDeleteChatAlert = true
                    }) {
                        Image("trash")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .foregroundColor(.white)
                    }
                    .frame(width: buttonWidth, height: 51)
                    .background(Color(hex: "#1F2023"))
                    .cornerRadius(12)
                }
                Button(action: {
                    onOpenHistory?(chatEffectsSelection == 1)
                }) {
                    Image("clockArrow")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.white)
                }
                .frame(width: buttonWidth, height: 51)
                .background(Color(hex: "#1F2023"))
                .cornerRadius(12)
                
                if chatEffectsSelection == 0 {
                    Button(action: { onPlusTapped?() }) {
                        Image("plus")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .foregroundColor(.white)
                    }
                    .frame(width: buttonWidth, height: 51)
                    .background(Color(hex: "#1F2023"))
                    .cornerRadius(12)
                }
            }
            .padding(.leading, sidePadding)
            .padding(.trailing, sidePadding)
        }
        .frame(height: 71)
    }
    
    
    /// template_id для POST /api/generations/fotobudka/video (можно заменить на выбор пользователя).
    private let defaultVideoTemplateId = 1

    private func sendMessageTapped() {
        guard !isLoadingResponse else { return }
        let messageText = textFieldText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageText.isEmpty else { return }
        // Фото из AddPhotoBottomSheet: если пользователь добавил — передаём в генерацию; иначе nil.
        let messageImage = selectedImage
        let messageVideoURL = selectedVideoURL

        if photoVideoSelection == 1 {
            // Режим video: если в textFieldContainer добавлено видео — передаём в fal/video-enhance ТОЛЬКО после выбора разрешения в меню.
            if messageVideoURL != nil && !userDidOpenVideoResolutionMenu {
                generationError = "Please select video resolution (720 or 1080) before sending"
                showGenerationErrorAlert = true
                return
            }
            let usedResolutionMenu = userDidOpenVideoResolutionMenu
            let newMessage = Message(text: messageText, image: messageImage, videoURL: messageVideoURL, isIncoming: false)
            let wasEmpty = messages.isEmpty
            messages = messages + [newMessage]
            textFieldText = ""
            selectedImage = nil
            selectedVideoURL = nil
            userDidOpenVideoResolutionMenu = false
            imageFileName = ""
            let newSessionId = wasEmpty ? onFirstMessageSent?() : nil
            let chatId = newSessionId ?? currentChatId
            onGenerationStarted?(chatId)
            isLoadingResponse = true
            generationTask = Task.detached(priority: .userInitiated) { [$generationError, $showGenerationErrorAlert, videoResolutionPx, defaultVideoTemplateId, onGenerationCompleted, onGenerationFailed] in
                do {
                    let videoURL: URL
                    // Видео из textFieldContainer (AddPhotoBottomSheet): если добавлено — обязательно передаём в запрос (enhance).
                    if let videoURLToEnhance = messageVideoURL {
                        let multiplier: Double = usedResolutionMenu && videoResolutionPx == 1080 ? 1.5 : 1.0
                        videoURL = try await GenerationService.shared.runFalVideoEnhance(videoURL: videoURLToEnhance, upscaleMultiplier: multiplier)
                    } else if let photo = messageImage {
                        videoURL = try await GenerationService.shared.runVideoGeneration(photo: photo, templateId: defaultVideoTemplateId)
                    } else {
                        videoURL = try await GenerationService.shared.runFotobudkaTxt2Video(prompt: messageText)
                    }
                    let incoming = Message(text: messageText, image: nil, videoURL: videoURL, isIncoming: true)
                    await MainActor.run {
                        onGenerationCompleted?(chatId, incoming)
                    }
                    await tokensStore.load()
                } catch is CancellationError {
                    await MainActor.run {
                        onGenerationFailed?(chatId)
                    }
                } catch {
                    let errMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    print("[Generation] Video error: \(error)")
                    await MainActor.run {
                        $generationError.wrappedValue = errMessage
                        $showGenerationErrorAlert.wrappedValue = true
                        onGenerationFailed?(chatId)
                    }
                }
            }
            return
        }

        // Режим photo: nanobanana
        let promptForGeneration = selectedStyleName.map { "\(messageText) style: \($0)" } ?? messageText
        let newMessage = Message(text: messageText, image: messageImage, videoURL: nil, isIncoming: false)
        let wasEmpty = messages.isEmpty
        messages = messages + [newMessage]
        let newSessionId = wasEmpty ? onFirstMessageSent?() : nil
        let chatId = newSessionId ?? currentChatId
        onGenerationStarted?(chatId)
        textFieldText = ""
        selectedImage = nil
        imageFileName = ""
        isLoadingResponse = true
        generationTask = Task.detached(priority: .userInitiated) { [$generationError, $showGenerationErrorAlert, onGenerationCompleted, onGenerationFailed] in
            do {
                // messageImage != nil — нейросеть может изменить фото или создать новое на его основе; nil — только по промпту.
                let (resultImage, resultText) = try await GenerationService.shared.runNanobananaAndLoadImage(prompt: promptForGeneration, image: messageImage)
                let incoming = Message(text: resultText ?? "", image: resultImage, videoURL: nil, isIncoming: true)
                await MainActor.run {
                    onGenerationCompleted?(chatId, incoming)
                }
                await tokensStore.load()
            } catch is CancellationError {
                await MainActor.run {
                    onGenerationFailed?(chatId)
                }
            } catch {
                let errMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                print("[Generation] Error: \(error)")
                await MainActor.run {
                    $generationError.wrappedValue = errMessage
                    $showGenerationErrorAlert.wrappedValue = true
                    onGenerationFailed?(chatId)
                }
            }
        }
    }
    
    private func saveMessageToGallery(_ message: Message) {
        if let image = message.image {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                guard status == .authorized || status == .limited else {
                    DispatchQueue.main.async {
                        saveErrorText = "Photo library access denied."
                        showSaveError = true
                    }
                    return
                }
                PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                } completionHandler: { success, error in
                    DispatchQueue.main.async {
                        if !success {
                            saveErrorText = error?.localizedDescription ?? "Failed to save image."
                            showSaveError = true
                        }
                    }
                }
            }
        } else if let videoURL = message.videoURL {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                guard status == .authorized || status == .limited else {
                    DispatchQueue.main.async {
                        saveErrorText = "Photo library access denied."
                        showSaveError = true
                    }
                    return
                }
                PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
                } completionHandler: { success, error in
                    DispatchQueue.main.async {
                        if !success {
                            saveErrorText = error?.localizedDescription ?? "Failed to save video."
                            showSaveError = true
                        }
                    }
                }
            }
        } else {
            saveErrorText = "No image or video to save."
            showSaveError = true
        }
    }
    
    private func shareMessage(_ message: Message) {
        guard message.image != nil || message.videoURL != nil else { return }
        shareItem = ShareableItem(image: message.image, videoURL: message.videoURL)
    }
    
    private func regenerateIncomingMessage(_ message: Message) {
        guard !isLoadingResponse, regeneratingMessageId == nil else { return }
        guard let idx = messages.firstIndex(where: { $0.id == message.id }), idx > 0 else {
            generationError = "Cannot find prompt for this message."
            showGenerationErrorAlert = true
            return
        }
        let previous = messages[idx - 1]
        guard !previous.isIncoming else {
            generationError = "Previous message is not a prompt."
            showGenerationErrorAlert = true
            return
        }
        let prompt = previous.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else {
            generationError = "Prompt is empty."
            showGenerationErrorAlert = true
            return
        }
        let promptForRegeneration = selectedStyleName.map { "\(prompt) style: \($0)" } ?? prompt
        let promptImage = previous.image
        regeneratingMessageId = message.id
        generationTask = Task.detached(priority: .userInitiated) { [$messages, $generationError, $showGenerationErrorAlert] in
            do {
                let (resultImage, resultText) = try await GenerationService.shared.runNanobananaAndLoadImage(prompt: promptForRegeneration, image: promptImage)
                await MainActor.run {
                    let newIncoming = Message(text: resultText ?? "", image: resultImage, videoURL: nil, isIncoming: true)
                    let current = $messages.wrappedValue
                    $messages.wrappedValue = current.prefix(idx) + [newIncoming] + current.suffix(from: idx + 1)
                    regeneratingMessageId = nil
                }
            } catch is CancellationError {
                await MainActor.run {
                    regeneratingMessageId = nil
                }
            } catch {
                let errMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                await MainActor.run {
                    $generationError.wrappedValue = errMessage
                    $showGenerationErrorAlert.wrappedValue = true
                    regeneratingMessageId = nil
                }
            }
        }
    }
    
    // Область для отображения сообщений
    private var messagesSection: some View {
        GeometryReader { geometry in
            MessagesListView(
                messages: messages,
                isLoadingResponse: showLoadingInThisChat,
                regeneratingMessageId: regeneratingMessageId,
                imageToView: $imageToView,
                onDeleteMessage: { id in
                    messages = messages.filter { $0.id != id }
                },
                onDownload: saveMessageToGallery,
                onShare: shareMessage,
                onRefresh: regenerateIncomingMessage,
                geometry: geometry
            )
        }
    }
    // Нижняя часть с TextField и кнопками; меню 720/1080 — рядом с контейнером, не внутри
    private var bottomSection: some View {
        ZStack(alignment: .bottomLeading) {
            VStack(spacing: 2) {
                textFieldContainer
            }
            .padding(.horizontal, 35)
            .padding(.bottom, 34)
            
        }
        .sheet(isPresented: $showAddPhotoSheet) {
            AddPhotoBottomSheet(
                selectedImage: $selectedImage,
                selectedVideoURL: $selectedVideoURL,
                mode: photoVideoSelection == 1 ? .video : .photo
            )
                .presentationDetents([.fraction(0.8)])
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled(false)
        }
        .sheet(isPresented: $showStyleSheet) {
            StyleBottomSheet(
                selectedStyle: $selectedStyle,
                selectedStyleName: $selectedStyleName
            )
            .presentationDetents([.fraction(0.65)])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(item: $imageToView) { item in
            ImageViewer(media: item) {
                imageToView = nil
            }
        }
        .onChange(of: selectedImage) { newImage in
            if newImage != nil {
                isLoadingImage = true
                imageFileName = "photo_\(Int(Date().timeIntervalSince1970)).jpg"
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isLoadingImage = false
                }
            } else {
                imageFileName = ""
                isLoadingImage = false
            }
        }
    }
    
    // Контейнер для TextField
    private var textFieldContainer: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 4) {
                            // TextField
                            TextField("", text: $textFieldText, prompt: Text("Type here").foregroundColor(Color.white.opacity(0.5)))
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(.white)
                                .padding(.trailing, 70)
                                .padding(.vertical, 12)
                                .background(Color.clear)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.clear, lineWidth: 0)
                                )
                            
                            // Превью изображения под TextField
                            if selectedImage != nil || isLoadingImage {
                                HStack(spacing: 12) {
                                    if let image = selectedImage {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 40, height: 40)
                                            .clipped()
                                            .cornerRadius(8)
                                    }
                                    
                                    if !imageFileName.isEmpty {
                                        Text(imageFileName)
                                            .font(.system(size: 15, weight: .regular))
                                            .foregroundColor(.white)
                                    }
                                    
                                    if isLoadingImage {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .frame(width: 25, height: 25)
                                    }
                                    
                                    Spacer(minLength: 0)
                                    
                                    Button(action: {
                                        selectedImage = nil
                                        imageFileName = ""
                                        isLoadingImage = false
                                    }) {
                                        Image("xmark")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 22, height: 22)
                                            .foregroundColor(.white)
                                            .padding(.trailing, 10)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
//                                .padding(.horizontal, 16)
                                .padding(.top, 2)
                                .padding(.bottom, 8)
                            }
                            
                            // Превью видео под TextField (режим video) — по той же логике, что и превью изображения
                            if photoVideoSelection == 1, let videoURL = selectedVideoURL {
                                HStack(spacing: 12) {
                                    SmallVideoThumbnailView(url: videoURL)
                                    Text(videoURL.lastPathComponent)
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 2)
                                .padding(.bottom, 8)
                            }
                            
                            // Кнопки внизу - прикреплены к левому краю
                            HStack(spacing: 4) {
                                // Кнопка с плюсом слева
                                Button(action: {
                                    showAddPhotoSheet = true
                                }) {
                                    Image("plus")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(.white)
                                        .frame(width: 46, height: 44)
                                        .background(Color(hex: "#3B3D40"))
                                        .cornerRadius(12)
                                }
                                
                                // Кнопка Style/720px справа
                                if photoVideoSelection == 0 {
                                    // photo выбран - показываем Style или выбранный стиль
                                    Button(action: {
                                        if selectedStyleName != nil {
                                            // Сброс состояния при нажатии на xmark
                                            selectedStyle = nil
                                            selectedStyleName = nil
                                        } else {
                                            // Открытие BottomSheet
                                            showStyleSheet = true
                                        }
                                    }) {
                                        HStack(spacing: 8) {
                                            Text(selectedStyleName ?? "Style")
                                                .font(.system(size: 17, weight: .regular))
                                                .foregroundColor(selectedStyleName != nil ? Color(hex: "#2F76BC") : .white)
                                            
                                            if selectedStyleName != nil {
                                                Image("xmark")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 24, height: 24)
                                                    .foregroundColor(Color.white)
                                            } else {
                                                Image("plus")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 24, height: 24)
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        .frame(height: 44)
                                        .padding(.horizontal, 12)
                                        .background(Color(hex: "#3B3D40"))
                                        .cornerRadius(12)
                                    }
                                } else {
                                    // video выбран - выбор 720px / 1080px (отдельный View, чтобы подпись обновлялась при смене значения)
                                    VideoResolutionButtonView(resolutionPx: $videoResolutionPx, onTap: {
                                        showVideoResolutionMenu = true
                                        userDidOpenVideoResolutionMenu = true
                                    })
                                    .popover(isPresented: $showVideoResolutionMenu, attachmentAnchor: .rect(.bounds)) {
                                        videoResolutionMenuView(
                                            onSelect: { newValue in
                                                videoResolutionPx = newValue
                                                print("[MainScreenView] videoResolutionPx = \(newValue)")
                                            },
                                            isPresented: $showVideoResolutionMenu
                                        )
                                        .presentationCompactAdaptation(.popover)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Текст "Cost of generation: 10 tokens"
                            HStack {
                                Text("Cost of generation: ")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Text("10 tokens")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.blue)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(13)
                        .background(Color(hex: "#1F2023"))
                        .cornerRadius(16)
                        
                        // Кнопка top_arrow - появляется когда есть текст
                        if !textFieldText.isEmpty {
                            Button(action: sendMessageTapped) {
                                Image("top_arrow")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 32, height: 32)
                                    .foregroundColor(.black)
                                    .frame(width: 48, height: 48)
                                    .background(Color.white)
                                    .cornerRadius(12)
                            }
                            .padding(.top, 20)
                            .padding(.trailing, 20)
            }
        }
    }
    
}


// Отдельный View для списка сообщений
struct MessagesListView: View {
    let messages: [Message]
    let isLoadingResponse: Bool
    let regeneratingMessageId: UUID?
    @Binding var imageToView: IdentifiableMedia?
    let onDeleteMessage: (UUID) -> Void
    let onDownload: (Message) -> Void
    let onShare: (Message) -> Void
    let onRefresh: (Message) -> Void
    let geometry: GeometryProxy
    
    private var loadingPlaceholder: some View {
        HStack {
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color(hex: "#1F2023"))
                    .frame(width: 72, height: 72)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(width: 32, height: 32)
            }
            Spacer()
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(messages, id: \.id) { (message: Message) in
                    if message.isIncoming == true {
                                    // Входящее сообщение (слева) или ProgressView при refresh
                                    HStack {
                                        if message.id == regeneratingMessageId {
                                            loadingPlaceholder
                                        } else {
                                            IncomingMessageView(
                                                message: message,
                                                maxWidth: geometry.size.width * 0.6,
                                                onTrash: { onDeleteMessage(message.id) },
                                                onDownload: { onDownload(message) },
                                                onShare: { onShare(message) },
                                                onRefresh: { onRefresh(message) },
                                                onMediaTap: {
                                                    if let image = message.image {
                                                        imageToView = IdentifiableMedia(image: image)
                                                    } else if let url = message.videoURL {
                                                        imageToView = IdentifiableMedia(videoURL: url)
                                                    }
                                                }
                                            )
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 40)
                                } else {
                                    // Исходящее сообщение (справа)
                                    HStack {
                                        Spacer()
                                        MessageView(
                                            message: message,
                                            maxWidth: geometry.size.width * 0.6,
                                            onCopy: {
                                                // Копирование текста в буфер обмена
                                                UIPasteboard.general.string = message.text
                                            },
                                            onDelete: {
                                                // Удаление сообщения
                                                onDeleteMessage(message.id)
                                            },
                                            onMediaTap: {
                                                if let image = message.image {
                                                    imageToView = IdentifiableMedia(image: image)
                                                } else if let url = message.videoURL {
                                                    imageToView = IdentifiableMedia(videoURL: url)
                                                }
                                            }
                                        )
                                    }
                                    .padding(.horizontal, 40)
                                }
                            }
                            
                            // Loading view
                            if isLoadingResponse {
                                HStack {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 25)
                                            .fill(Color(hex: "#1F2023"))
                                            .frame(width: 72, height: 72)
                                        
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .frame(width: 32, height: 32)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 40)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                    }
                }
    
    
   
    
}

struct CustomSwitch: View {
    let options: [String]
    @Binding var selection: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Фон свитчера (невидимый, так как контейнер уже есть снаружи)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.clear)
                    .frame(height: 35)
                
                // Белая область для активного элемента с увеличенным скруглением
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .frame(width: geometry.size.width / CGFloat(options.count), height: 38)
                    .offset(x: CGFloat(selection) * (geometry.size.width / CGFloat(options.count)), y: -2)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selection)
            }
            .overlay(
                HStack(spacing: 0) {
                    ForEach(0..<options.count, id: \.self) { index in
                        Button(action: {
                            withAnimation {
                                selection = index
                            }
                        }) {
                            Text(options[index])
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(selection == index ? .black : .white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 35)
                                .offset(y: -2)
                        }
                    }
                }
            )
        }
        .frame(height: 35)
    }
}

// BottomSheet для выбора стиля
struct StyleBottomSheet: View {
    @Binding var selectedStyle: Int?
    @Binding var selectedStyleName: String?
    @Environment(\.dismiss) var dismiss
    
    let styles = [
        ("Style01", "Anime"),
        ("Style02", "Cyberpunk"),
        ("Style03", "Pixel Art"),
        ("Style04", "Fantasy"),
        ("Style05", "Disney"),
        ("Style06", "Cartoon"),
        ("Style07", "Pokémon"),
        ("Style08", "Lego"),
        ("Style09", "Avatar 3D")
    ]
    
    var body: some View {
        ZStack {
            Color(hex: "#0D0D0F")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Сетка карточек 3x3
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(0..<styles.count, id: \.self) { index in
                            StyleCard(
                                imageName: styles[index].0,
                                title: styles[index].1,
                                isSelected: selectedStyle == index,
                                onTap: {
                                    selectedStyle = index
                                    selectedStyleName = styles[index].1
                                    dismiss()
                                }
                            )
                        }
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                }
                
                // Кнопка Done
                Button(action: {
                    dismiss()
                }) {
                    Text("Done")
                        .font(.system(size: 17, weight: .regular))
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
                .padding(.top, 20)
                .padding(.bottom, 50)
            }
        }
    }
}

// Карточка стиля
struct StyleCard: View {
    let imageName: String
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        // Изображение с тайтлом внутри и внутренней обводкой
        ZStack(alignment: .bottomLeading) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: .infinity, height: 100)
                .clipped()
                .cornerRadius(12)
            
            // Внутренняя обводка
            if isSelected {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color(hex: "#2F76BC"), lineWidth: 6)
                    .frame(width: .infinity, height: 100)
            }
            
            // Тайтл внутри изображения, прижат к нижнему краю, выровнен по центру
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(title)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                    Spacer()
                }
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.black.opacity(0.8)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
        }
        .frame(height: 100)
        .onTapGesture {
            onTap()
        }
    }
}

// Маленькое превью видео (40x40) для отображения под TextField в режиме video. При fillFrame: true — заполняет родительский frame (для HistoryView effects).
struct SmallVideoThumbnailView: View {
    let url: URL
    /// nil = 40x40 (для TextField). Иначе — заполняет указанный размер (для HistoryView).
    var size: (width: CGFloat, height: CGFloat)? = nil
    
    @State private var thumbnail: UIImage?
    
    private var displayWidth: CGFloat { size?.width ?? 40 }
    private var displayHeight: CGFloat { size?.height ?? 40 }
    private var cornerRadius: CGFloat { size != nil ? 12 : 8 }
    private var playIconSize: CGFloat { size != nil ? 48 : 20 }
    
    var body: some View {
        ZStack {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: displayWidth, height: displayHeight)
                    .clipped()
                    .cornerRadius(cornerRadius)
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(hex: "#2A2A2A"))
                    .frame(width: displayWidth, height: displayHeight)
            }
            Image(systemName: "play.circle.fill")
                .font(.system(size: playIconSize))
                .foregroundColor(.white.opacity(0.9))
        }
        .onAppear { loadThumbnail() }
    }
    
    private func loadThumbnail() {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: .zero)]) { _, cgImage, _, _, _ in
            if let cgImage = cgImage {
                DispatchQueue.main.async { thumbnail = UIImage(cgImage: cgImage) }
            }
        }
    }
}

// Превью видео в сообщении (первый кадр + иконка play)
struct VideoPreviewView: View {
    let url: URL
    @State private var thumbnail: UIImage?
    
    var body: some View {
        ZStack {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 120)
                    .clipped()
                    .cornerRadius(20)
            } else {
                Rectangle()
                    .fill(Color(hex: "#2A2A2A"))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 120)
                    .cornerRadius(20)
            }
            Image(systemName: "play.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.9))
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: .zero)]) { _, cgImage, _, _, _ in
            if let cgImage = cgImage {
                DispatchQueue.main.async {
                    thumbnail = UIImage(cgImage: cgImage)
                }
            }
        }
    }
}

// Экран просмотра фото или видео
struct ImageViewer: View {
    let media: IdentifiableMedia
    var onDismiss: (() -> Void)? = nil
    @Environment(\.dismiss) var dismiss
    @State private var showShareSheet = false
    @State private var showContextMenu = false
    @State private var saveErrorText = ""
    @State private var showSaveError = false
    
    var body: some View {
        ZStack {
            Image("phone")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Навбар
                HStack {
                    Button(action: {
                        onDismiss?()
                        dismiss()
                    }) {
                        Image("chevronLeft")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                    }
                    .background(Color(hex: "#1F2023"))
                    .cornerRadius(20)
                    Spacer()
                    Text("Result")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { showContextMenu = true }) {
                        Image("threeDots")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                    }
                    .background(Color(hex: "#1F2023"))
                    .cornerRadius(20)
                }
                .padding(.horizontal, 40)
                .padding(.top, 8)
                
                // Контент: картинка или видеоплеер
                VStack(spacing: 0) {
                    if let image = media.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 30))
                            .padding(.top, 40)
                            .padding(.horizontal, 30)
                    } else if let videoURL = media.videoURL {
                        VideoPlayer(player: AVPlayer(url: videoURL))
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 30))
                            .padding(.top, 40)
                            .padding(.horizontal, 30)
                    }
                    
                    Button(action: {
                        
                        saveMediaToGallery()
                        showContextMenu = false
                    }) {
                        Text("Save")
                            .font(.system(size: 17, weight: .regular))
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
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                    
                    Spacer()
                }
            }
        }
        .overlay {
            if showContextMenu {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture { showContextMenu = false }
            }
        }
        .overlay(alignment: .topTrailing) {
            if showContextMenu {
                imageViewerContextMenu
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: shareItems)
        }
        .alert("Save failed", isPresented: $showSaveError) {
            Button("OK", role: .cancel) { saveErrorText = "" }
        } message: {
            Text(saveErrorText)
        }
    }
    
    private var imageViewerContextMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                showShareSheet = true
                
            }) {
                HStack(spacing: 12) {
                    Text("Share")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.white)
                    Spacer()
                    Image("share")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
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
                if let id = media.effectRecordId {
                    EffectGenerationStore.shared.removeRecord(id: id)
                }
                showContextMenu = false
                onDismiss?()
                dismiss()
            }) {
                HStack(spacing: 12) {
                    Text("Delete")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.red)
                    Spacer()
                    Image("redTrash")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
        }
        .frame(width: 240)
        .background(Color(hex: "#29292A"))
        .cornerRadius(12)
        .padding(.top, 70)
        .padding(.trailing, 40)
    }
    
    private func saveMediaToGallery() {
        if let image = media.image {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                guard status == .authorized || status == .limited else {
                    DispatchQueue.main.async {
                        saveErrorText = "Photo library access denied."
                        showSaveError = true
                    }
                    return
                }
                PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                } completionHandler: { success, error in
                    DispatchQueue.main.async {
                        if !success {
                            saveErrorText = error?.localizedDescription ?? "Failed to save image."
                            showSaveError = true
                        }
                    }
                }
            }
        } else if let videoURL = media.videoURL {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                guard status == .authorized || status == .limited else {
                    DispatchQueue.main.async {
                        saveErrorText = "Photo library access denied."
                        showSaveError = true
                    }
                    return
                }
                PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
                } completionHandler: { success, error in
                    DispatchQueue.main.async {
                        if !success {
                            saveErrorText = error?.localizedDescription ?? "Failed to save video."
                            showSaveError = true
                        }
                    }
                }
            }
        } else {
            saveErrorText = "No image or video to save."
            showSaveError = true
        }
    }
    
    private var shareItems: [Any] {
        if let image = media.image {
            return [image]
        }
        if let url = media.videoURL {
            return [url]
        }
        return []
    }
}

// Цвет разделителей алертов (на 20% тоньше: 1pt → 0.8)
private let alertDividerHeight: CGFloat = 0.8
private let alertDividerColor = Color(hex: "#333334")

// Кастомный алерт удаления чата (фон #232323)
struct DeleteChatAlertView: View {
    let onCancel: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture(perform: onCancel)
            
            VStack(spacing: 0) {
                Text("Delete chat?")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
                    .padding(.bottom, 8)
                
                Text("This history will be permanently")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                Text("removed.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                
                Rectangle()
                    .fill(alertDividerColor)
                    .frame(height: alertDividerHeight)
                
                HStack(spacing: 0) {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(Color(hex: "#0C4CD6"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .buttonStyle(.plain)
                    
                    Rectangle()
                        .fill(alertDividerColor)
                        .frame(width: alertDividerHeight, height: 44)
                    
                    Button(action: onDelete) {
                        Text("Delete")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(hex: "#FF453A"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: 280)
            .background(Color(hex: "#232323"))
            .cornerRadius(14)
        }
    }
}

// Алерт переименования чата
struct RenameChatAlertView: View {
    let title: String
    @Binding var text: String
    let onCancel: () -> Void
    let onOK: (String) -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture(perform: onCancel)
            
            VStack(spacing: 0) {
                Text("Rename Chat")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 22)
                    .padding(.bottom, 8)
                
                Text("Enter a new name to make it easier to")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 15)
                Text("find this chat in your history.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                
                TextField("", text: $text, prompt: Text("New chat name").foregroundColor(Color(hex: "#4A4A4C")))
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .frame(height: 31)
                    .background(Color(hex: "#2C2C2E"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: "#333334"), lineWidth: 2)
                    )
                    .cornerRadius(7)
                    .padding(.horizontal, 15)
                    .padding(.bottom, 20)
                
                Rectangle()
                    .fill(alertDividerColor)
                    .frame(height: alertDividerHeight)
                
                HStack(spacing: 0) {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(Color(hex: "#0C4CD6"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .buttonStyle(.plain)
                    
                    Rectangle()
                        .fill(alertDividerColor)
                        .frame(width: alertDividerHeight, height: 44)
                    
                    Button(action: {
                        onOK(text.trimmingCharacters(in: .whitespacesAndNewlines))
                    }) {
                        Text("OK")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(hex: "#0C4CD6"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: 280)
            .background(Color(hex: "#232323"))
            .cornerRadius(14)
        }
    }
}

#Preview {
    MainScreenView(
        messages: .constant([]),
        isLoadingResponse: .constant(false),
        generationError: .constant(nil),
        showGenerationErrorAlert: .constant(false),
        showLoadingInThisChat: false,
        currentChatId: nil
    )
    .environmentObject(TokensStore())
}
