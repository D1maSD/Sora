//
//  EffectPreviewView.swift
//  Sora
//

import SwiftUI

struct EffectPreviewView: View {
    let onBack: () -> Void
    
    @State private var showLottieOverlay: Bool = true
    @State private var showAddPhotoSheet = false
    @State private var selectedImageForEffect: UIImage? = nil
    @State private var showProcessingView = false
    @State private var processingProgress: Int = 0
    @State private var showProcessingError = false
    
    private let previewBannerData: [(imageName: String, title: String)] = [
        ("effectCard1", "Effect 1"),
        ("effectCard2", "Effect 2"),
        ("effectCard3", "Effect 3")
    ]
    
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
            AddPhotoBottomSheet(selectedImage: $selectedImageForEffect)
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
    }
    
    /// Задел на будущее: отправка изображения в нейросеть Sora для обработки.
    private func submitImageForProcessing(_ image: UIImage) {
        // TODO: вызов API Sora для генерации видео/эффекта по изображению
        // Пока только показываем экран обработки; по завершении вызвать showProcessingView = false
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
    
    private func dismissProcessingAndReset() {
        showProcessingView = false
        showProcessingError = false
        processingProgress = 0
        selectedImageForEffect = nil
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
    
    // Высота ячейки = высота области под navbar (минус кнопка внизу) − 20 сверху − 20 снизу
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
                .padding(.horizontal, sidePadding)
            }
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
            if !showProcessingError && processingProgress == 0 {
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
            
            Text("\(processingProgress)%")
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(.white)
            
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
