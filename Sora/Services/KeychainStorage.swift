//
//  KeychainStorage.swift
//  Sora
//
//  Хранение user_id и access_token в Keychain (не UserDefaults).
//

import Foundation
import Security

final class KeychainStorage {
    static let shared = KeychainStorage()
    
    private let serviceName = "test.Sora"
    private let userIdKey = "sora_user_id"
    private let accessTokenKey = "sora_access_token"
    
    private init() {}
    
    // MARK: - User ID
    
    func saveUserId(_ value: String) {
        save(key: userIdKey, value: value)
    }
    
    func getUserId() -> String? {
        load(key: userIdKey)
    }
    
    // MARK: - Access Token
    
    func saveToken(_ value: String) {
        save(key: accessTokenKey, value: value)
    }
    
    func getToken() -> String? {
        load(key: accessTokenKey)
    }
    
    // MARK: - Clear
    
    func clear() {
        delete(key: userIdKey)
        delete(key: accessTokenKey)
    }
    
    // MARK: - Keychain Helpers
    
    private func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        delete(key: key)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else { return nil }
        return string
    }
    
    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
