//
//  EffectPreviewView.swift
//  Sora
//

import SwiftUI

struct IdentifiableImageResult: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct EffectPreviewView: View {
    let onBack: () -> Void
    var effectItems: [EffectPreviewItem]? = nil
    var selectedEffectIndex: Int = 0
    /// true когда карточки из категории видео (для истории в HistoryView)
    var isVideo: Bool = false
    
    @ObservedObject private var effectStore = EffectGenerationStore.shared
    @State private var showLottieOverlay: Bool = true
    @State private var showAddPhotoSheet = false
    @State private var selectedImageForEffect: UIImage? = nil
    @State private var selectedVideoURLForEffect: URL? = nil
    @State private var showProcessingView = false
    @State private var processingProgress: Int = 0
    @State private var showProcessingError = false
    @State private var resultImageForViewer: IdentifiableImageResult?
    @State private var scrollBannerId: Int?
    /// ID записи в store для текущей генерации (polling продолжается при закрытии оверлея)
    @State private var currentEffectRecordId: UUID?
    
    private let previewBannerData: [(imageName: String, title: String)] = [
        ("effectCard1", "Effect 1"),
        ("effectCard2", "Effect 2"),
        ("effectCard3", "Effect 3")
    ]
    
    private var templateId: Int? {
        guard let items = effectItems, items.indices.contains(selectedEffectIndex) else { return nil }
        return items[selectedEffectIndex].id
    }
    
    /// Ключ статуса текущей записи для onChange (реакция на success/error из store).
    private var currentEffectRecordStatusKey: String? {
        guard let id = currentEffectRecordId, let rec = effectStore.record(by: id) else { return nil }
        switch rec.status {
        case .processing: return "p"
        case .success: return "s"
        case .error: return "e"
        }
    }
    
    var body: some View {
        ZStack {
            Color(hex: "#0D0D0F")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                navbar
                previewBannerSection
                createButton
            }
            .overlay {
                if showLottieOverlay {
                    lottieOverlay
                }
            }
            .overlay {
                if showProcessingView {
                    processingOverlay
                }
            }
        }
        .sheet(isPresented: $showAddPhotoSheet) {
            AddPhotoBottomSheet(
                selectedImage: $selectedImageForEffect,
                selectedVideoURL: $selectedVideoURLForEffect,
                mode: isVideo ? .video : .photo
            )
                .presentationDetents([.fraction(0.8)])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: selectedImageForEffect) { _, newImage in
            if newImage != nil {
                processingProgress = 0
                showProcessingError = false
                showProcessingView = true
                submitImageForProcessing(newImage!)
            }
        }
        .onChange(of: currentEffectRecordStatusKey) { _, newKey in
            guard let id = currentEffectRecordId, let rec = effectStore.record(by: id) else { return }
            switch rec.status {
            case .success(let img):
                if let image = img {
                    resultImageForViewer = IdentifiableImageResult(image: image)
                    showProcessingView = false
                    selectedImageForEffect = nil
                    showProcessingError = false
                }
            case .error:
                showProcessingError = true
            case .processing:
                break
            }
        }
        .fullScreenCover(item: $resultImageForViewer) { item in
            ImageViewer(media: IdentifiableMedia(image: item.image), onDismiss: { resultImageForViewer = nil })
        }
        .onAppear {
            if effectItems != nil {
                scrollBannerId = selectedEffectIndex
            } else {
                scrollBannerId = nil
            }
        }
    }
    
    private func submitImageForProcessing(_ image: UIImage) {
        guard let tid = templateId else {
            startProgressTimer()
            return
        }
        // Store запускает polling в фоне; закрытие processingProgressContent его не прерывает.
        let recordId = effectStore.startEffect(photo: image, templateId: tid, isVideo: isVideo)
        currentEffectRecordId = recordId
    }
    
    private func startProgressTimer() {
        Task { @MainActor in
            for i in 1...100 {
                try? await Task.sleep(nanoseconds: 3_000_000_000 / 100)
                processingProgress = i
            }
            showProcessingError = true
        }
    }
    
    /// Закрытие оверлея не отменяет polling — он продолжается в EffectGenerationStore.
    private func dismissProcessingAndReset() {
        showProcessingView = false
        showProcessingError = false
        processingProgress = 0
        selectedImageForEffect = nil
        // currentEffectRecordId не сбрасываем: запись остаётся в store, HistoryView покажет результат
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
                
                Button(action: {}) {
                    HStack(spacing: 6) {
                        Text("1000")
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
                    .background(Color(hex: "#1F2022"))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            
            Text("Effect")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
        }
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    private let createButtonHeight: CGFloat = 56
    
    // Баннер: динамические effectItems (из категории) или статичные previewBannerData
    private var previewBannerSection: some View {
        GeometryReader { geometry in
            let availableHeight = geometry.size.height
            let topBottomPadding: CGFloat = 20
            let cellHeight = availableHeight - topBottomPadding * 2 + 60
            let screenWidth = geometry.size.width
            let cellWidth = screenWidth * 0.8
            let sidePadding = (screenWidth - cellWidth) / 2
            let spacingBetweenCells: CGFloat = 15
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: spacingBetweenCells) {
                    if let items = effectItems {
                        ForEach(Array(items.enumerated()), id: \.element.id) { offset, item in
                            ZStack(alignment: .bottomLeading) {
                                CachedAsyncImage(
                                    urlString: item.previewURL,
                                    failure: { AnyView(Rectangle().fill(Color(hex: "#2B2D30")).overlay(Image(systemName: "photo").foregroundColor(.white.opacity(0.5)))) }
                                )
                                .frame(width: cellWidth, height: cellHeight)
                                .clipped()
                                if let t = item.title, !t.isEmpty {
                                    Text(t)
                                        .font(.system(size: 27, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.leading, 20)
                                        .padding(.bottom, 10)
                                }
                            }
                            .frame(width: cellWidth, height: cellHeight)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .id(offset)
                        }
                    } else {
                        ForEach(Array(previewBannerData.enumerated()), id: \.offset) { _, item in
                            ZStack(alignment: .bottomLeading) {
                                Image(item.imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: cellWidth, height: cellHeight)
                                Text(item.title)
                                    .font(.system(size: 27, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.leading, 20)
                                    .padding(.bottom, 10)
                            }
                            .frame(width: cellWidth, height: cellHeight)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.horizontal, sidePadding)
            }
            .scrollPosition(id: $scrollBannerId)
            .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
        }
        .padding(.top, 20)
        .padding(.bottom, 20)
    }
    
    private var createButton: some View {
        Button(action: { showAddPhotoSheet = true }) {
            HStack(spacing: 4) {
                Text("Create ")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.white)
                Text("(120 tokens)")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: createButtonHeight)
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
        .padding(.top, 40)
        .padding(.bottom, 34)
    }
    
    private var lottieOverlay: some View {
        ZStack {
            Color.black.opacity(0.01)
                .ignoresSafeArea()
                .onTapGesture { showLottieOverlay = false }
            
            LottieOverlayView()
                .allowsHitTesting(false)
        }
        .onTapGesture { showLottieOverlay = false }
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { _ in showLottieOverlay = false }
        )
    }
    
    private var processingOverlay: some View {
        ZStack(alignment: .topTrailing) {
            Color.black
                .ignoresSafeArea()
            
            Group {
                if showProcessingError {
                    processingErrorContent
                } else {
                    processingProgressContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Button(action: dismissProcessingAndReset) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
            }
            .frame(width: 48, height: 48)
            .background(Color(hex: "#2B2D30"))
            .cornerRadius(12)
            .padding(.top, 20)
            .padding(.trailing, 20)
        }
        .onAppear {
            if templateId == nil, !showProcessingError, processingProgress == 0 {
                startProgressTimer()
            }
        }
    }
    
    private var processingProgressContent: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(2.2)
                .frame(width: 44, height: 44)
            
            if templateId == nil {
                Text("\(processingProgress)%")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.white)
            }
            
            Text("We create...")
                .font(.system(size: 27, weight: .regular))
                .foregroundColor(.white)
            
            Text("Just a little bit left")
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(Color(hex: "#5D5D5F"))
        }
    }
    
    private var processingErrorContent: some View {
        VStack(spacing: 16) {
            Image("checkmarkRedWide")
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
            
            Text("Something went wrong")
                .font(.system(size: 27, weight: .regular))
                .foregroundColor(.white)
            
            Button(action: dismissProcessingAndReset) {
                Text("Return to effects")
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
            .padding(.top, 8)
        }
    }
}

// Lottie-оверлей: при добавлении пакета lottie-ios и JSON анимации показывается анимация.
// 1) Xcode → File → Add Package Dependencies → https://github.com/airbnb/lottie-ios
// 2) Скачать анимацию в формате Lottie JSON (.json): https://app.lottiefiles.com/animation/856575d8-6351-4686-ab7a-1f4436c4bdb6
// 3) Добавить JSON в проект и указать имя файла (без .json) в .named("имя_файла") ниже.
struct LottieOverlayView: View {
    var body: some View {
        Group {
            #if canImport(Lottie)
            LottieSwiftUIView(animationName: "SwipeGestureLeft")
            #else
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            #endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if canImport(Lottie)
import Lottie

private struct LottieSwiftUIView: View {
    let animationName: String
    var body: some View {
        LottieView(animation: .named(animationName))
            .looping()
    }
}
#endif

#Preview {
    EffectPreviewView(onBack: {})
}
