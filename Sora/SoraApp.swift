//
//  SoraApp.swift
//  Sora
//
//  Created by Dima Melnik on 2/12/26.
//

import SwiftUI

@main
struct SoraApp: App {
    @State private var isLoaded = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
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
                        // Симулируем загрузку приложения
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                isLoaded = true
                            }
                        }
                    }
            }
        }
    }
}
