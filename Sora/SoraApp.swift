//
//  SoraApp.swift
//  Sora
//
//  Created by Dima Melnik on 2/12/26.
//

import SwiftUI
import ApphudSDK

/// Ссылки для политик (открываются во внешнем браузере).
enum PolicyURL {
    static let privacy = "https://www.ya.ru/"
    static let usageTerms = "https://www.google.com/"
}

/// Единый источник ключа Apphud. Сейчас используется ключ из Demo (tokens paywall).
/// Чтобы вернуть старый ключ — замените `currentKey` на `legacyKey`.
enum ApphudConfig {
    /// Ключ из Demo / PurchaseManager (paywall "tokens", подписки)
    static let demoKey = "app_MJp2QdcqMLP5XCgB8pAjZAhzAs2nva"
    /// Старый ключ (ранее в SoraApp)
    static let legacyKey = "app_TZDsHNqKL7UkoaScjN6oyShxkzRX97"
    /// Текущий ключ приложения — поменяйте на legacyKey при необходимости
    static let currentKey = demoKey
}

@main
struct SoraApp: App {
    @StateObject private var tokensStore = TokensStore()
    @ObservedObject private var purchaseManager = PurchaseManager.shared
    @State private var isLoaded = false
    @State private var hasIncrementedAppOpen = false
    @State private var hasJustCompletedOnboarding = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    init() {
        Apphud.start(apiKey: ApphudConfig.currentKey)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isLoaded {
                    if !hasCompletedOnboarding {
                        OnboardingView(onComplete: { hasJustCompletedOnboarding = true })
                    } else if hasJustCompletedOnboarding && !purchaseManager.isSubscribed {
                        PaywallView(onDismiss: {
                            hasJustCompletedOnboarding = false
                        })
                    } else {
                        ContentView()
                            .onAppear {
                                guard !hasIncrementedAppOpen else { return }
                                hasIncrementedAppOpen = true
                                Task { @MainActor in
                                    RatingPromptService.shared.incrementAppOpen()
                                }
                            }
                    }
                } else {
                    SplashView()
                        .onAppear {
                            Task { @MainActor in
                                async let auth = AuthService.shared.bootstrapUser()
                                try? await Task.sleep(nanoseconds: 2_000_000_000)
                                await auth
                                await tokensStore.load()
                                if let userId = KeychainStorage.shared.getUserId() {
                                    print("User ID:", userId)
                                }
                                withAnimation {
                                    isLoaded = true
                                }
                            }
                        }
                }
            }
            .environmentObject(tokensStore)
            .environmentObject(PurchaseManager.shared)
            .onChange(of: purchaseManager.isSubscribed) { _, isSubscribed in
                if isSubscribed {
                    hasJustCompletedOnboarding = false
                }
            }
        }
    }
}
