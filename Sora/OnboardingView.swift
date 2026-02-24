//
//  OnboardingView.swift
//  Sora
//
//  Created by Dima Melnik on 2/12/26.
//

import SwiftUI
import StoreKit

struct OnboardingView: View {
    @State private var currentPage = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    var onComplete: (() -> Void)? = nil
    
    let onboardingData: [(imageName: String, title: String)] = [
        ("firstScreen", "Create with chat"),
        ("secondScreen", "Use effects"),
        ("thirdScreen", "Choose your vibe"),
        ("fourScreen", "Rate our app in the\nAppStore"),
        ("fiveScreen", "Make your dreams come true")
    ]
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // TabView с картинками
                TabView(selection: $currentPage) {
                    ForEach(0..<onboardingData.count, id: \.self) { index in
                        OnboardingPageView(
                            imageName: onboardingData[index].imageName
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea(edges: .top)
                .onChange(of: currentPage) { newPage in
                    if newPage == 3 { // Индекс 3 = "Rate our app in the AppStore"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                                SKStoreReviewController.requestReview(in: windowScene)
                            }
                        }
                    }
                }
                
                // Нижняя часть с контентом
                VStack(spacing: 19) { //spase between tabController and button
                    // Тайтл
                    Text(onboardingData[currentPage].title)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    
                    // Индикаторы точек
                    HStack(spacing: 8) {
                        ForEach(0..<onboardingData.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Color.white : Color.white.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    // Кнопка Next
                    Button(action: {
                        if currentPage < onboardingData.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            // Завершение онбординга - переход на главный экран
                            hasCompletedOnboarding = true
                            onComplete?()
                        }
                    }) {
                        Text("Next")
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
                    .padding(.bottom, 44)
                }
                .background(Color.black)
            }
        }
    }
}

struct OnboardingPageView: View {
    let imageName: String
    
    var body: some View {
        GeometryReader { geometry in
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width)
                .clipped()
        }
        .ignoresSafeArea(edges: .top)
    }
}

#Preview {
    OnboardingView()
}
