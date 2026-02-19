//
//  EffectsListView.swift
//  Sora
//

import SwiftUI

struct EffectsListView: View {
    @EnvironmentObject var tokensStore: TokensStore
    let onBack: () -> Void
    
    private let filterTitles = ["Hot", "Category 1", "Category 2", "Category 3", "Category 4", "Category 5"]
    @State private var selectedFilterIndex: Int = 0
    @State private var showEffectPreview = false
    @State private var showTokensPaywall = false
    
    private let gradientColors = [
        Color(hex: "#6CABE9"),
        Color(hex: "#2F76BC")
    ]
    
    var body: some View {
        ZStack {
            Color(hex: "#0D0D0F")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Nav bar: chevronLeft, заголовок по центру, кнопка 1000 + sparkles
                navbar
                
                // Вертикальные кнопки: Hot и 5 Category
                filterButtons
                
                // Двухколоночная вертикальная коллекция effectCard
                effectsGrid
            }
        }
        .fullScreenCover(isPresented: $showEffectPreview) {
            EffectPreviewView(onBack: { showEffectPreview = false })
        }
        .fullScreenCover(isPresented: $showTokensPaywall) {
            PaywallView(mode: .buyTokens, onDismiss: { showTokensPaywall = false })
                .environmentObject(tokensStore)
        }
    }
    
    private var navbar: some View {
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
                .background(Color(hex: "#2B2D30"))
                .cornerRadius(12)
                
                Spacer()
                
                Button(action: { showTokensPaywall = true }) {
                    HStack(spacing: 6) {
                        Text("\(tokensStore.tokens)")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.3)
                        Image("sparkles")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(hex: "#1F2022"))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            
            Text("Effects")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
        }
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    private var filterButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(filterTitles.enumerated()), id: \.offset) { index, title in
                    Button(action: { selectedFilterIndex = index }) {
                        Text(title)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    .background(
                        selectedFilterIndex == index
                            ? LinearGradient(
                                gradient: Gradient(colors: gradientColors),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "#2B2D30"), Color(hex: "#2B2D30")]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    )
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 16)
    }
    
    private var effectsGrid: some View {
        GeometryReader { geometry in
            let horizontalPadding: CGFloat = 20
            let spacing: CGFloat = 12
            let contentWidth = geometry.size.width - horizontalPadding * 2
            let cellWidth = (contentWidth - spacing) / 2
            let cellHeight = cellWidth * 1.4
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: [
                    GridItem(.fixed(cellWidth), spacing: spacing),
                    GridItem(.fixed(cellWidth), spacing: spacing)
                ], spacing: spacing) {
                    ForEach(0..<12, id: \.self) { _ in
                        Button(action: { showEffectPreview = true }) {
                            ZStack(alignment: .bottomLeading) {
                                Image("effectCard")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: cellWidth, height: cellHeight)
                                Text("Name")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.leading, 20)
                                    .padding(.bottom, 10)
                            }
                            .frame(width: cellWidth, height: cellHeight)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(width: contentWidth)
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, 40)
            }
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Элемент для горизонтального слайдера в EffectPreviewView (id = template_id для API)

struct EffectPreviewItem: Identifiable {
    let id: Int
    let previewURL: String
    let title: String?
}

// MARK: - See All: экран категории с вертикальной сеткой картинок из раздела

struct EffectCategoryPayload: Identifiable {
    let id = UUID()
    let title: String
    let effects: [EffectItemResponse]?
    let videos: [VideoTemplateItemResponse]?
}

/// Payload для открытия EffectPreviewView с карточками категории
struct EffectPreviewPayload: Identifiable {
    let id = UUID()
    let items: [EffectPreviewItem]
    let selectedIndex: Int
    /// true для категории видео (история в HistoryView и тип записи в store)
    var isVideo: Bool = false
}

struct EffectCategoryFullView: View {
    @EnvironmentObject var tokensStore: TokensStore
    let title: String
    let effects: [EffectItemResponse]?
    let videos: [VideoTemplateItemResponse]?
    let onBack: () -> Void
    
    @State private var effectPreviewPayload: EffectPreviewPayload?
    @State private var showTokensPaywall = false
    
    var body: some View {
        ZStack {
            Color(hex: "#0D0D0F")
                .ignoresSafeArea()
            VStack(spacing: 0) {
                categoryNavbar
                categoryGrid
            }
        }
        .fullScreenCover(item: $effectPreviewPayload) { payload in
            EffectPreviewView(
                onBack: { effectPreviewPayload = nil },
                effectItems: payload.items,
                selectedEffectIndex: payload.selectedIndex,
                isVideo: payload.isVideo
            )
        }
        .fullScreenCover(isPresented: $showTokensPaywall) {
            PaywallView(mode: .buyTokens, onDismiss: { showTokensPaywall = false })
                .environmentObject(tokensStore)
        }
    }
    
    private var categoryNavbar: some View {
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
                .background(Color(hex: "#2B2D30"))
                .cornerRadius(12)
                Spacer()
                Button(action: { showTokensPaywall = true }) {
                    HStack(spacing: 6) {
                        Text("\(tokensStore.tokens)")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.3)
                        Image("sparkles")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(hex: "#1F2022"))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
        }
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    private var categoryGrid: some View {
        GeometryReader { geometry in
            let horizontalPadding: CGFloat = 20
            let spacing: CGFloat = 12
            let contentWidth = geometry.size.width - horizontalPadding * 2
            let cellWidth = (contentWidth - spacing) / 2
            let cellHeight = cellWidth * 1.4
            
            ScrollView(.vertical, showsIndicators: false) {
                Group {
                    if let effects = effects {
                        LazyVGrid(columns: [
                            GridItem(.fixed(cellWidth), spacing: spacing),
                            GridItem(.fixed(cellWidth), spacing: spacing)
                        ], spacing: spacing) {
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
                    } else if let videos = videos {
                        LazyVGrid(columns: [
                            GridItem(.fixed(cellWidth), spacing: spacing),
                            GridItem(.fixed(cellWidth), spacing: spacing)
                        ], spacing: spacing) {
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
                    }
                }
                .frame(width: contentWidth)
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, 40)
            }
        }
        .frame(maxHeight: .infinity)
    }
}

#Preview {
    EffectsListView(onBack: {})
        .environmentObject(TokensStore())
}
