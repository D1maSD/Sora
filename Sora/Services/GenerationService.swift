//
//  GenerationService.swift
//  Sora
//
//  Nanobanana: POST generation → poll by id → download file.
//

import Foundation
import UIKit

// Ответ POST /api/generations/fotobudka/nanobanana и GET /api/generations/{id}
struct GenerationResponse: Decodable {
    let id: String
    let type: String?
    let status: String  // queued, processing, completed, failed
    let tokens_cost: Int?
    let external_id: String?
    let result: String?  // при completed — имя файла или ссылка
    let error: String?
}

enum GenerationError: Error, LocalizedError {
    case noToken
    case failed(String)
    case downloadFailed
    
    var errorDescription: String? {
        switch self {
        case .noToken: return "Not authorized. Please try again later."
        case .failed(let s): return s
        case .downloadFailed: return "Failed to load the generated image."
        }
    }
}

final class GenerationService {
    static let shared = GenerationService()
    private let api = APIClient.shared
    private let pollInterval: TimeInterval = 2.5
    
    private init() {}
    
    /// Запуск генерации Nanobanana. Возвращает generation id для polling.
    func startNanobananaGeneration(prompt: String, image: UIImage?) async throws -> String {
        var fields: [String: String] = ["prompt": prompt]
        var imagePayload: (data: Data, filename: String, mimeType: String)?
        if let img = image, let jpeg = img.jpegData(compressionQuality: 0.85) {
            imagePayload = (jpeg, "image.jpg", "image/jpeg")
        }
        print("[Generation] POST /api/generations/fotobudka/nanobanana ...")
        let response: GenerationResponse = try await api.postMultipart(
            "/api/generations/fotobudka/nanobanana",
            formFields: fields,
            image: imagePayload,
            useAuth: true
        )
        print("[Generation] Started, id: \(response.id), status: \(response.status), result: \(response.result ?? "nil"), error: \(response.error ?? "nil")")
        return response.id
    }
    
    /// Получить текущий статус генерации.
    func getGeneration(id: String) async throws -> GenerationResponse {
        let path = "/api/generations/\(id)"
        return try await api.get(path)
    }
    
    /// Polling до completed или failed. Возвращает result (filename) при успехе или throws при ошибке.
    func pollUntilFinished(generationId: String) async throws -> String {
        var pollCount = 0
        while true {
            try Task.checkCancellation()
            try await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
            pollCount += 1
            do {
                let gen = try await getGeneration(id: generationId)
                print("[Generation] Poll #\(pollCount) GET /api/generations/\(generationId) → status: \(gen.status), result: \(gen.result ?? "nil"), error: \(gen.error ?? "nil")")
                switch gen.status {
                case "completed", "error", "finished":
                    // Бэкенд возвращает "finished" или "error" с URL в result, "completed" — альтернативный вариант
                    if let result = gen.result, !result.isEmpty {
                        print("[Generation] Done (status: \(gen.status)), result: \(result)")
                        return result
                    }
                    if gen.status == "error" {
                        let errMsg = gen.error ?? "Generation error"
                        print("[Generation] Error status with no result: \(errMsg)")
                        throw GenerationError.failed(errMsg)
                    }
                    print("[Generation] Completed but result empty")
                    throw GenerationError.downloadFailed
                case "failed":
                    let errMsg = gen.error ?? "Generation failed"
                    print("[Generation] Failed: \(errMsg)")
                    throw GenerationError.failed(errMsg)
                default:
                    continue
                }
            } catch {
                print("[Generation] Poll #\(pollCount) error: \(error)")
                throw error
            }
        }
    }
    
    /// Скачать изображение: по полному URL (GET без auth) или по имени файла через API.
    func downloadGenerationFile(resultOrUrl: String) async throws -> Data {
        if resultOrUrl.hasPrefix("http://") || resultOrUrl.hasPrefix("https://") {
            guard let url = URL(string: resultOrUrl) else { throw GenerationError.downloadFailed }
            print("[Generation] GET (URL) \(resultOrUrl)")
            let (data, _) = try await URLSession.shared.data(from: url)
            print("[Generation] Downloaded \(data.count) bytes from URL")
            return data
        }
        let path = "/api/generations/file/\(resultOrUrl)"
        print("[Generation] GET \(path) ...")
        let data = try await api.getData(path)
        print("[Generation] Downloaded \(data.count) bytes")
        return data
    }
    
    /// Полный цикл: запуск → polling → скачивание. Возвращает изображение или throws.
    func runNanobananaAndLoadImage(prompt: String, image: UIImage?) async throws -> (image: UIImage, resultText: String?) {
        print("[Generation] runNanobananaAndLoadImage started")
        do {
            let id = try await startNanobananaGeneration(prompt: prompt, image: image)
            print("[Generation] Polling for id: \(id)")
            let resultOrUrl = try await pollUntilFinished(generationId: id)
            let data = try await downloadGenerationFile(resultOrUrl: resultOrUrl)
            guard let img = UIImage(data: data) else {
                print("[Generation] UIImage(data) failed")
                throw GenerationError.downloadFailed
            }
            print("[Generation] Success, image loaded")
            return (img, nil)
        } catch {
            print("[Generation] runNanobananaAndLoadImage error: \(error)")
            throw error
        }
    }
}
