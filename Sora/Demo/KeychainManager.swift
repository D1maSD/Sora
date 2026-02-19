import Foundation
import Security

final class KeychainManager {
    static let shared = KeychainManager()
    
    private let service: String
    
    private init() {
        self.service = Bundle.main.bundleIdentifier ?? "com.paywallsdemo"
    }
    
    
    func save(_ value: String, forKey key: String) async -> Bool {
        guard let data = value.data(using: .utf8) else {
            return false
        }
        return await save(data, forKey: key)
    }
    
    func save(_ value: Data, forKey key: String) async -> Bool {
        delete(forKey: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: value,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func save(_ value: Int, forKey key: String) async -> Bool {
        return await save(String(value), forKey: key)
    }
    
    func save(_ value: Bool, forKey key: String) async -> Bool {
        return await save(value ? "true" : "false", forKey: key)
    }
    
    
    func load(forKey key: String) -> String? {
        guard let data = loadData(forKey: key) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    func loadData(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        
        return data
    }
    
    func loadInt(forKey key: String) -> Int? {
        guard let string = load(forKey: key) else {
            return nil
        }
        return Int(string)
    }
    
    func loadBool(forKey key: String) -> Bool? {
        guard let string = load(forKey: key) else {
            return nil
        }
        return string == "true"
    }
    
    
    @discardableResult
    func delete(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    
    @discardableResult
    func clearAll() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    
    func exists(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
}
