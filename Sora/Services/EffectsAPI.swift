//
//  EffectsAPI.swift
//  Sora
//
//  GET /api/generations/fotobudka/effects и video-templates для вкладки Effects.
//

import Foundation

// MARK: - Photo effects

struct EffectsGroupResponse: Decodable {
    let id: Int
    let title: String?
    let preview: String?
    let effects: [EffectItemResponse]
}

struct EffectItemResponse: Decodable {
    let id: Int
    let preview: String
    let title: String?
}

// MARK: - Video templates

struct VideoTemplatesGroupResponse: Decodable {
    let id: Int
    let title: String?
    let videos: [VideoTemplateItemResponse]
}

struct VideoTemplateItemResponse: Decodable {
    let id: Int
    let photo_preview: String
    let video_preview: String?
    let video_preview_short: String?
    let title: String
    let is_new: Bool?
}

// MARK: - Fetch

enum EffectsAPI {
    private static let api = APIClient.shared
    private static let lang = "en"
    
    static func fetchEffects() async throws -> [EffectsGroupResponse] {
        let path = "/api/generations/fotobudka/effects?lang=\(lang)"
        return try await api.get(path)
    }
    
    static func fetchVideoTemplates() async throws -> [VideoTemplatesGroupResponse] {
        let path = "/api/generations/fotobudka/video-templates?lang=\(lang)"
        return try await api.get(path)
    }
}
