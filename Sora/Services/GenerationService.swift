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
    
    // MARK: - Fotobudka Effect (photo + template_id)
    
    /// Запуск генерации эффекта: POST /api/generations/fotobudka/effect (photo + template_id).
    func startEffectGeneration(photo: UIImage, templateId: Int) async throws -> String {
        guard let jpeg = photo.jpegData(compressionQuality: 0.85) else { throw GenerationError.downloadFailed }
        let fields: [String: String] = ["template_id": "\(templateId)"]
        print("[Generation] POST /api/generations/fotobudka/effect template_id=\(templateId)")
        let response: GenerationResponse = try await api.postMultipartPhoto(
            "/api/generations/fotobudka/effect",
            formFields: fields,
            photo: (jpeg, "photo.jpg", "image/jpeg"),
            useAuth: true
        )
        print("[Generation] Effect started, id: \(response.id), status: \(response.status)")
        return response.id
    }
    
    /// Полный цикл: эффект по фото + template_id → polling → скачивание. Возвращает UIImage или throws.
    func runEffectAndLoadImage(photo: UIImage, templateId: Int) async throws -> UIImage {
        let id = try await startEffectGeneration(photo: photo, templateId: templateId)
        let resultOrUrl = try await pollUntilFinished(generationId: id)
        let data = try await downloadGenerationFile(resultOrUrl: resultOrUrl)
        guard let img = UIImage(data: data) else { throw GenerationError.downloadFailed }
        return img
    }

    // MARK: - Fotobudka Video (photo + template_id → video)

    /// Запуск генерации видео: POST /api/generations/fotobudka/video (photo + template_id).
    func startVideoGeneration(photo: UIImage, templateId: Int) async throws -> String {
        guard let jpeg = photo.jpegData(compressionQuality: 0.85) else { throw GenerationError.downloadFailed }
        let fields: [String: String] = ["template_id": "\(templateId)"]
        print("[Generation] POST /api/generations/fotobudka/video template_id=\(templateId)")
        let response: GenerationResponse = try await api.postMultipartPhoto(
            "/api/generations/fotobudka/video",
            formFields: fields,
            photo: (jpeg, "photo.jpg", "image/jpeg"),
            useAuth: true
        )
        print("[Generation] Video started, id: \(response.id), status: \(response.status)")
        return response.id
    }

    /// Полный цикл: видео по фото + template_id → polling → скачивание. Возвращает URL файла видео или throws.
    func runVideoGeneration(photo: UIImage, templateId: Int) async throws -> URL {
        let id = try await startVideoGeneration(photo: photo, templateId: templateId)
        return try await pollDownloadVideo(generationId: id)
    }

    // MARK: - FAL Video Enhance (video + upscale_factor + type/prompt)

    /// POST /api/generations/fal/video-enhance: видео + upscale_factor (720/1080) + type (промпт).
    func startFalVideoEnhance(videoURL: URL, upscaleFactor: Int, typePrompt: String, appBundle: String? = nil, targetFps: Int? = nil, h264Output: Bool = true) async throws -> String {
        let videoData = try Data(contentsOf: videoURL)
        let filename = videoURL.lastPathComponent.isEmpty ? "video.mp4" : videoURL.lastPathComponent
        var fields: [String: String] = [
            "type": typePrompt,
            "upscale_factor": "\(upscaleFactor)",
            "H264_output": h264Output ? "true" : "false"
        ]
        if let app = appBundle { fields["app_bundle"] = app }
        if let fps = targetFps { fields["target_fps"] = "\(fps)" }
        print("[Generation] POST /api/generations/fal/video-enhance upscale_factor=\(upscaleFactor)")
        let response: GenerationResponse = try await api.postMultipartVideo(
            "/api/generations/fal/video-enhance",
            formFields: fields,
            video: (videoData, filename, "video/mp4"),
            useAuth: true
        )
        print("[Generation] FAL video-enhance started, id: \(response.id)")
        return response.id
    }

    /// Полный цикл: fal/video-enhance → poll → скачать видео, вернуть URL.
    func runFalVideoEnhance(videoURL: URL, upscaleFactor: Int, typePrompt: String) async throws -> URL {
        let id = try await startFalVideoEnhance(videoURL: videoURL, upscaleFactor: upscaleFactor, typePrompt: typePrompt)
        return try await pollDownloadVideo(generationId: id)
    }

    // MARK: - Fotobudka txt2video (только текст, без фото/видео)

    /// POST /api/generations/fotobudka/txt2video через APIClient.createTxt2Video (точная спецификация: duration "5", cfg_scale 0.5, model kling-v2-master).
    func startFotobudkaTxt2Video(
        prompt: String,
        aspectRatio: String = "16:9",
        duration: String = "5",
        cfgScale: Double = 0.5,
        mode: String = "std",
        modelName: String = "kling-v2-master",
        negativePrompt: String = ""
    ) async throws -> String {
        let result = await api.createTxt2Video(
            prompt: prompt,
            aspectRatio: aspectRatio,
            duration: duration,
            cfgScale: cfgScale,
            mode: mode,
            modelName: modelName,
            negativePrompt: negativePrompt
        )
        switch result {
        case .success(let response):
            print("[Generation] txt2video started, id: \(response.id)")
            return response.id
        case .failure(let error):
            throw error
        }
    }

    /// Полный цикл: txt2video → poll → скачать видео, вернуть URL.
    func runFotobudkaTxt2Video(prompt: String) async throws -> URL {
        let id = try await startFotobudkaTxt2Video(prompt: prompt)
        return try await pollDownloadVideo(generationId: id)
    }

    /// Общая часть: polling + скачивание результата как видео в temp file.
    private func pollDownloadVideo(generationId: String) async throws -> URL {
        let resultOrUrl = try await pollUntilFinished(generationId: generationId)
        let data = try await downloadGenerationFile(resultOrUrl: resultOrUrl)
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "video_\(generationId)_\(UUID().uuidString).mp4"
        let fileURL = tempDir.appendingPathComponent(filename)
        try data.write(to: fileURL)
        print("[Generation] Video saved to \(fileURL.path)")
        return fileURL
    }
}
