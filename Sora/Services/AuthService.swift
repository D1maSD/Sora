//
//  AuthService.swift
//  Sora
//
//  Авторизация: bootstrap → register при необходимости → authorize.
//

import Foundation
import ApphudSDK

final class AuthService {
    static let shared = AuthService()
    
    private let keychain = KeychainStorage.shared
    private let api = APIClient.shared
    
    private init() {}
    
    /// Запускать на Splash до перехода на Onboarding/ContentView.
    /// Не блокирует UI — выполняется в Task.
    func bootstrapUser() async {
        if keychain.getToken() != nil {
            return
        }
        if let userId = keychain.getUserId() {
            await authorize(userId: userId)
            return
        }
        await register()
    }
    
    /// Регистрация: apphud_id → POST /api/users → сохраняем user_id → authorize
    private func register() async {
        let apphudId = await MainActor.run { Apphud.userID() }
        guard !apphudId.isEmpty else {
            print("[AuthService] Apphud.userID() is empty")
            return
        }
        do {
            let response: CreateUserResponse = try await api.post(
                "/api/users",
                body: CreateUserRequest(apphud_id: apphudId),
                useAuth: false
            )
            keychain.saveUserId(response.id)
            await authorize(userId: response.id)
        } catch APIError.httpStatus(422, let data) {
            // Пользователь уже зарегистрирован — пробуем только авторизовать по сохранённому user_id или по apphud
            if let userId = keychain.getUserId() {
                await authorize(userId: userId)
            } else {
                print("[AuthService] 422 and no user_id in Keychain. Body: \(data.flatMap { String(data: $0, encoding: .utf8) } ?? "")")
            }
        } catch {
            print("[AuthService] register error: \(error)")
        }
    }
    
    /// Авторизация: POST /api/users/authorize → сохраняем access_token
    private func authorize(userId: String) async {
        do {
            let response: AuthorizeResponse = try await api.post(
                "/api/users/authorize",
                body: AuthorizeRequest(user_id: userId),
                useAuth: false
            )
            keychain.saveToken(response.access_token)
        } catch {
            print("[AuthService] authorize error: \(error)")
        }
    }
    
    func getToken() -> String? {
        keychain.getToken()
    }
    
    var isAuthorized: Bool {
        keychain.getToken() != nil
    }
    
    /// GET /api/users/me — текущий пользователь (в т.ч. tokens). useAuth: true.
    func fetchCurrentUser() async throws -> UserMeResponse {
        try await api.get("/api/users/me")
    }
}
