//
//  EffectGenerationStore.swift
//  Sora
//
//  Глобальное хранилище генераций эффектов. Polling выполняется в фоне и не привязан к lifecycle вью.
//  Успешные и ошибочные записи сохраняются на диск и подгружаются в HistoryView (режим effects).
//

import Foundation
import UIKit
import Combine

enum EffectGenerationStatus: Equatable {
    case processing
    case success(image: UIImage?)
    case error(String)
}

struct EffectGenerationRecord: Identifiable {
    let id: UUID
    let templateId: Int
    let isVideo: Bool
    var status: EffectGenerationStatus
    var generationId: String?
    let createdAt: Date
    /// Путь к сохранённому изображению на диске (для persistence).
    var imagePath: String?

    init(id: UUID = UUID(), templateId: Int, isVideo: Bool, status: EffectGenerationStatus, generationId: String? = nil, createdAt: Date = Date(), imagePath: String? = nil) {
        self.id = id
        self.templateId = templateId
        self.isVideo = isVideo
        self.status = status
        self.generationId = generationId
        self.createdAt = createdAt
        self.imagePath = imagePath
    }
}

// MARK: - Persistence (Codable, без UIImage)
private struct EffectGenerationRecordPersistence: Codable {
    let id: UUID
    let templateId: Int
    let isVideo: Bool
    let statusString: String // "processing", "success", "error"
    let imagePath: String?
    let errorMessage: String?
    let createdAt: TimeInterval
    let generationId: String?
}

@MainActor
final class EffectGenerationStore: ObservableObject {
    static let shared = EffectGenerationStore()

    @Published private(set) var records: [EffectGenerationRecord] = []
    private var pollingTasks: [UUID: Task<Void, Never>] = [:]

    private static let persistenceFileName = "effect_generations.json"
    private static let imagesSubdirectory = "EffectGenerations"

    private var persistenceURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(Self.persistenceFileName)
    }

    private var imagesDirectoryURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(Self.imagesSubdirectory, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private init() {
        loadPersistedRecords()
    }

    /// Запускает генерацию эффекта. Polling выполняется в фоне; закрытие экрана его не прерывает.
    /// - Returns: id записи для подписки на результат в UI.
    func startEffect(photo: UIImage, templateId: Int, isVideo: Bool) -> UUID {
        let id = UUID()
        let record = EffectGenerationRecord(
            id: id,
            templateId: templateId,
            isVideo: isVideo,
            status: .processing,
            generationId: nil,
            createdAt: Date()
        )
        records.insert(record, at: 0)

        let task: Task<Void, Never> = Task { [weak self] in
            guard let self else { return }
            await self.runEffectAndPoll(recordId: id, photo: photo, templateId: templateId, isVideo: isVideo)
        }
        pollingTasks[id] = task
        return id
    }

    private func runEffectAndPoll(recordId: UUID, photo: UIImage, templateId: Int, isVideo: Bool) async {
        do {
            let generationId = try await GenerationService.shared.startEffectGeneration(photo: photo, templateId: templateId)
            await MainActor.run { [weak self] in
                guard let self = self, let idx = self.records.firstIndex(where: { $0.id == recordId }) else { return }
                var next = self.records[idx]
                next.generationId = generationId
                next.status = .processing
                self.records[idx] = next
            }

            let resultOrUrl = try await GenerationService.shared.pollUntilFinished(generationId: generationId)
            let data = try await GenerationService.shared.downloadGenerationFile(resultOrUrl: resultOrUrl)

            if isVideo {
                let img = UIImage(data: data)
                await MainActor.run { [weak self] in
                    guard let self = self, let idx = self.records.firstIndex(where: { $0.id == recordId }) else { return }
                    let r = self.records[idx]
                    let imagePath = img.flatMap { self.saveImageToDisk($0, recordId: recordId) }
                    self.records[idx] = EffectGenerationRecord(
                        id: recordId,
                        templateId: templateId,
                        isVideo: true,
                        status: .success(image: img),
                        generationId: generationId,
                        createdAt: r.createdAt,
                        imagePath: imagePath
                    )
                    self.persistRecords()
                }
            } else {
                guard let image = UIImage(data: data) else {
                    await setRecordError(recordId, message: "Failed to load image.")
                    return
                }
                await MainActor.run { [weak self] in
                    guard let self = self, let idx = self.records.firstIndex(where: { $0.id == recordId }) else { return }
                    let r = self.records[idx]
                    let imagePath = self.saveImageToDisk(image, recordId: recordId)
                    self.records[idx] = EffectGenerationRecord(
                        id: recordId,
                        templateId: templateId,
                        isVideo: false,
                        status: .success(image: image),
                        generationId: generationId,
                        createdAt: r.createdAt,
                        imagePath: imagePath
                    )
                    self.persistRecords()
                }
            }
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            await setRecordError(recordId, message: message)
        }

        await MainActor.run { [weak self] in
            self?.pollingTasks[recordId] = nil
        }
    }

    private func setRecordError(_ id: UUID, message: String) async {
        await MainActor.run { [weak self] in
            guard let self = self, let idx = self.records.firstIndex(where: { $0.id == id }) else { return }
            let r = self.records[idx]
            self.records[idx] = EffectGenerationRecord(
                id: r.id,
                templateId: r.templateId,
                isVideo: r.isVideo,
                status: .error(message),
                generationId: r.generationId,
                createdAt: r.createdAt,
                imagePath: nil
            )
            self.persistRecords()
        }
    }

    // MARK: - Persistence

    /// Сохраняет изображение в Documents/EffectGenerations/{id}.jpg. Возвращает относительный путь (от Documents), чтобы после перезапуска приложения путь оставался валидным.
    private func saveImageToDisk(_ image: UIImage, recordId: UUID) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return nil }
        let fileURL = imagesDirectoryURL.appendingPathComponent("\(recordId.uuidString).jpg")
        do {
            try data.write(to: fileURL)
            return "\(Self.imagesSubdirectory)/\(recordId.uuidString).jpg"
        } catch {
            return nil
        }
    }

    /// Разрешает путь к файлу: если относительный — от Documents, иначе как есть (для обратной совместимости со старыми абсолютными путями).
    private func resolveImageURL(path: String) -> URL {
        if path.hasPrefix("/") {
            return URL(fileURLWithPath: path)
        }
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent(path)
    }

    private func loadPersistedRecords() {
        guard FileManager.default.fileExists(atPath: persistenceURL.path),
              let data = try? Data(contentsOf: persistenceURL),
              let decoded = try? JSONDecoder().decode([EffectGenerationRecordPersistence].self, from: data) else {
            return
        }
        let loaded: [EffectGenerationRecord] = decoded.compactMap { p in
            let createdAt = Date(timeIntervalSince1970: p.createdAt)
            switch p.statusString {
            case "success":
                let image: UIImage? = p.imagePath.flatMap { path in
                    let url = resolveImageURL(path: path)
                    guard FileManager.default.fileExists(atPath: url.path),
                          let data = try? Data(contentsOf: url) else { return nil }
                    return UIImage(data: data)
                }
                return EffectGenerationRecord(
                    id: p.id,
                    templateId: p.templateId,
                    isVideo: p.isVideo,
                    status: .success(image: image),
                    generationId: p.generationId,
                    createdAt: createdAt,
                    imagePath: p.imagePath
                )
            case "error":
                return EffectGenerationRecord(
                    id: p.id,
                    templateId: p.templateId,
                    isVideo: p.isVideo,
                    status: .error(p.errorMessage ?? "Unknown error"),
                    generationId: p.generationId,
                    createdAt: createdAt,
                    imagePath: nil
                )
            default:
                return nil
            }
        }
        records = loaded
    }

    private func persistRecords() {
        let toSave: [EffectGenerationRecordPersistence] = records.compactMap { r in
            switch r.status {
            case .success:
                return EffectGenerationRecordPersistence(
                    id: r.id,
                    templateId: r.templateId,
                    isVideo: r.isVideo,
                    statusString: "success",
                    imagePath: r.imagePath,
                    errorMessage: nil,
                    createdAt: r.createdAt.timeIntervalSince1970,
                    generationId: r.generationId
                )
            case .error(let msg):
                return EffectGenerationRecordPersistence(
                    id: r.id,
                    templateId: r.templateId,
                    isVideo: r.isVideo,
                    statusString: "error",
                    imagePath: nil,
                    errorMessage: msg,
                    createdAt: r.createdAt.timeIntervalSince1970,
                    generationId: r.generationId
                )
            case .processing:
                return nil
            }
        }
        guard let data = try? JSONEncoder().encode(toSave) else { return }
        try? data.write(to: persistenceURL)
    }

    func record(by id: UUID) -> EffectGenerationRecord? {
        records.first { $0.id == id }
    }

    /// Удаляет запись из истории (и файл изображения на диске, если есть). Вызывается из ImageViewer по кнопке Delete.
    func removeRecord(id: UUID) {
        if let idx = records.firstIndex(where: { $0.id == id }) {
            let r = records[idx]
            if let path = r.imagePath {
                let url = resolveImageURL(path: path)
                if FileManager.default.fileExists(atPath: url.path) {
                    try? FileManager.default.removeItem(at: url)
                }
            }
            records.remove(at: idx)
            persistRecords()
        }
    }

    /// Только фото (isVideo == false), новые сверху.
    var photoRecords: [EffectGenerationRecord] {
        records.filter { !$0.isVideo }
    }

    /// Только видео (isVideo == true), новые сверху.
    var videoRecords: [EffectGenerationRecord] {
        records.filter { $0.isVideo }
    }
}
