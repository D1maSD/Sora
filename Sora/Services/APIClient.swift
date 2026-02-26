//
//  APIClient.swift
//  Sora
//
//  Базовый HTTP-клиент: base URL, Content-Type, автоматический Bearer токен.
//

import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case httpStatus(Int, Data?)
    case decoding(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid request URL."
        case .noData:
            return "No data received from server."
        case .httpStatus(let code, let data):
            let body = data.flatMap { String(data: $0, encoding: .utf8) }.flatMap { $0.isEmpty ? nil : $0 }
            if let body = body, !body.isEmpty {
                return "Server error (\(code)): \(body)"
            }
            return "Server error (\(code))."
        case .decoding(let error):
            return "Invalid server response: \(error.localizedDescription)"
        }
    }
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
    
    /// GET and return raw Data (e.g. for file download).
    func getData(_ path: String, useAuth: Bool = true) async throws -> Data {
        guard let url = URL(string: baseURL + path) else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if useAuth, let token = keychain.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await session.data(for: request)
        try checkStatus(data: data, response: response)
        return data
    }
    
    // MARK: - Txt2Video (fotobudka)
    
    /// Тело запроса для POST /api/generations/fotobudka/txt2video (совпадает с переданной спецификацией).
    struct Txt2VideoRequest: Encodable {
        let type: String
        let cfg_scale: Double
        let duration: String
        let aspect_ratio: String
        let prompt: String
        let mode: String
        let model_name: String
        let negative_prompt: String
    }
    
    /// Генерация видео по тексту (txt2video). Возвращает ответ генерации или ошибку.
    func createTxt2Video(
        prompt: String,
        aspectRatio: String = "16:9",
        duration: String = "5",
        cfgScale: Double = 0.5,
        mode: String = "std",
        modelName: String = "kling-v2-master",
        negativePrompt: String = ""
    ) async -> Result<GenerationResponse, Error> {
        let body = Txt2VideoRequest(
            type: "fotobudka_txt2video",
            cfg_scale: cfgScale,
            duration: duration,
            aspect_ratio: aspectRatio,
            prompt: prompt,
            mode: mode,
            model_name: modelName,
            negative_prompt: negativePrompt
        )
        print("[APIClient][createTxt2Video] Request – aspect_ratio: \(aspectRatio), prompt: \(prompt)")
        do {
            let response: GenerationResponse = try await post(
                "/api/generations/fotobudka/txt2video",
                body: body,
                useAuth: true
            )
            return .success(response)
        } catch {
            return .failure(error)
        }
    }
    
    /// POST multipart/form-data. Form fields + optional image (single image, key "images").
    func postMultipart<T: Decodable>(
        _ path: String,
        formFields: [String: String],
        image: (data: Data, filename: String, mimeType: String)? = nil,
        useAuth: Bool = true
    ) async throws -> T {
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        for (key, value) in formFields {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        if let img = image {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"images\"; filename=\"\(img.filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(img.mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(img.data)
            body.append("\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        guard let url = URL(string: baseURL + path) else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("\(body.count)", forHTTPHeaderField: "Content-Length")
        if useAuth, let token = keychain.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = body
        
        let (data, response) = try await session.data(for: request)
        try checkStatus(data: data, response: response)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
    
    /// POST multipart with file under name "photo" (for fotobudka/effect и fotobudka/video).
    func postMultipartPhoto<T: Decodable>(
        _ path: String,
        formFields: [String: String],
        photo: (data: Data, filename: String, mimeType: String),
        useAuth: Bool = true
    ) async throws -> T {
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        for (key, value) in formFields {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"\(photo.filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(photo.mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(photo.data)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        guard let url = URL(string: baseURL + path) else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("\(body.count)", forHTTPHeaderField: "Content-Length")
        if useAuth, let token = keychain.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = body
        
        let (data, response) = try await session.data(for: request)
        try checkStatus(data: data, response: response)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
    
    /// POST multipart with file under name "video" (for fal/video-enhance).
    func postMultipartVideo<T: Decodable>(
        _ path: String,
        formFields: [String: String],
        video: (data: Data, filename: String, mimeType: String),
        useAuth: Bool = true
    ) async throws -> T {
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        for (key, value) in formFields {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"video\"; filename=\"\(video.filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(video.mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(video.data)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        guard let url = URL(string: baseURL + path) else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("\(body.count)", forHTTPHeaderField: "Content-Length")
        if useAuth, let token = keychain.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = body
        
        let (data, response) = try await session.data(for: request)
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
