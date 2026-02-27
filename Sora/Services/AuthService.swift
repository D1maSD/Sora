//
//  AuthService.swift
//  Sora
//
//  Авторизация: bootstrap → register при необходимости → authorize.
//

import Foundation
import ApphudSDK
#if canImport(Adapty)
import Adapty
#endif

final class AuthService {
    static let shared = AuthService()
    
    private let keychain = KeychainStorage.shared
    private let api = APIClient.shared
    
    private init() {}

    private enum AuthSource: String {
        case adapty = "Adapty"
        case apphud = "Apphud"
        case none = "None"
    }
    
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
        let (externalId, authSource) = await resolveExternalAuthId()
        print("[AuthService] Auth source: \(authSource.rawValue)")
        guard !externalId.isEmpty else {
            print("[AuthService] External auth id is empty")
            return
        }
        do {
            let response: CreateUserResponse = try await api.post(
                "/api/users",
                // Backend field name is currently apphud_id.
                // In Adapty mode we pass Adapty profile/customer id into the same field.
                body: CreateUserRequest(apphud_id: externalId),
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

    private func resolveExternalAuthId() async -> (String, AuthSource) {
        if AppFeatures.useAdaptyCatalog {
            #if canImport(Adapty)
            do {
                let profile = try await Adapty.getProfile()
                let mirror = Mirror(reflecting: profile)
                for key in ["profileId", "profileID", "customerUserId", "id"] {
                    if let value = mirror.children.first(where: { $0.label == key })?.value as? String,
                       !value.isEmpty {
                        return (value, .adapty)
                    }
                }
                print("[AuthService] Adapty profile fetched, but id field is empty")
            } catch {
                print("[AuthService] Failed to resolve Adapty auth id: \(error)")
            }
            #else
            print("[AuthService] Adapty mode enabled, but Adapty SDK is unavailable")
            #endif
            return ("", .none)
        }
        let apphudId = await MainActor.run { Apphud.userID() }
        return (apphudId, apphudId.isEmpty ? .none : .apphud)
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
