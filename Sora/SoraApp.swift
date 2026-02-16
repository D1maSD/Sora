//
//  SoraApp.swift
//  Sora
//
//  Created by Dima Melnik on 2/12/26.
//

import SwiftUI
import ApphudSDK

@main
struct SoraApp: App {
    @State private var isLoaded = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    init() {
        Apphud.start(apiKey: "app_TZDsHNqKL7UkoaScjN6oyShxkzRX97")
    }
    
    var body: some Scene {
        WindowGroup {
            if isLoaded {
                if hasCompletedOnboarding {
                    ContentView()
                } else {
                    OnboardingView()
                }
            } else {
                SplashView()
                    .onAppear {
                        Task { @MainActor in
                            async let auth = AuthService.shared.bootstrapUser()
                            try? await Task.sleep(nanoseconds: 2_000_000_000)
                            await auth
                            withAnimation {
                                isLoaded = true
                            }
                        }
                    }
            }
        }
    }
}
