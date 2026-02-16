//
//  APIClient.swift
//  Sora
//
//  Базовый HTTP-клиент: base URL, Content-Type, автоматический Bearer токен.
//

import Foundation

enum APIError: Error {
    case invalidURL
    case noData
    case httpStatus(Int, Data?)
    case decoding(Error)
}

final class APIClient {
    static let shared = APIClient()
    
    private let baseURL = "https://aiphotoappfull.webberapp.shop"
    private let session: URLSession
    private let keychain = KeychainStorage.shared
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Request building
    
    private func makeRequest(
        path: String,
        method: String,
        body: Encodable? = nil,
        useAuth: Bool = true
    ) throws -> URLRequest {
        guard let url = URL(string: baseURL + path) else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if useAuth, let token = keychain.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(AnyEncodable(body))
        }
        
        return request
    }
    
    // MARK: - Public API
    
    func post<T: Decodable, B: Encodable>(
        _ path: String,
        body: B,
        useAuth: Bool = false
    ) async throws -> T {
        let request = try makeRequest(path: path, method: "POST", body: body, useAuth: useAuth)
        let (data, response) = try await session.data(for: request)
        try checkStatus(data: data, response: response)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
    
    func post<B: Encodable>(
        _ path: String,
        body: B,
        useAuth: Bool = false
    ) async throws {
        let request = try makeRequest(path: path, method: "POST", body: body, useAuth: useAuth)
        let (data, response) = try await session.data(for: request)
        try checkStatus(data: data, response: response)
    }
    
    func get<T: Decodable>(_ path: String, useAuth: Bool = true) async throws -> T {
        var req = try makeRequest(path: path, method: "GET", useAuth: useAuth)
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: req)
        try checkStatus(data: data, response: response)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
    
    private func checkStatus(data: Data, response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        if http.statusCode == 401 {
            print("[APIClient] 401 Unauthorized")
        }
        if http.statusCode == 422 {
            let body = String(data: data, encoding: .utf8) ?? ""
            print("[APIClient] 422 Validation error: \(body)")
        }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.httpStatus(http.statusCode, data)
        }
    }
}

// Helper to encode arbitrary Encodable in generic method
private struct AnyEncodable: Encodable {
    let value: Encodable
    init(_ value: Encodable) { self.value = value }
    func encode(to encoder: Encoder) throws { try value.encode(to: encoder) }
}
