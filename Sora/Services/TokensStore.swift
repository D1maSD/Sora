//
//  TokensStore.swift
//  Sora
//
//  Хранит баланс токенов пользователя из GET /api/users/me.
//

import Foundation
import SwiftUI

@MainActor
final class TokensStore: ObservableObject {
    @Published var tokens: Int = 0
    
    func load() async {
        do {
            let user = try await AuthService.shared.fetchCurrentUser()
            self.tokens = user.tokens
        } catch {
            print("Failed to load tokens:", error)
        }
    }
}
