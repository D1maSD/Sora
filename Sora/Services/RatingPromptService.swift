//
//  RatingPromptService.swift
//  Sora
//

import Foundation

/// Счётчики и флаги для показа экрана оценки приложения.
@MainActor
final class RatingPromptService: ObservableObject {
    static let shared = RatingPromptService()

    @Published private(set) var shouldShowRatingPrompt = false

    private let defaults = UserDefaults.standard
    private let appOpenCountKey = "ratingPrompt_appOpenCount"
    private let videoGenCountKey = "ratingPrompt_videoGenCount"
    private let hasRatedKey = "ratingPrompt_hasRated"
    private let hasShownForVideoKey = "ratingPrompt_hasShownForVideo"

    private init() {}

    /// Вызвать при каждом открытии приложения (когда показывается главный экран).
    func incrementAppOpen() {
        let count = defaults.integer(forKey: appOpenCountKey) + 1
        defaults.set(count, forKey: appOpenCountKey)
        updateShouldShow()
    }

    /// Вызвать при успешной генерации видео.
    func incrementVideoGeneration() {
        let count = defaults.integer(forKey: videoGenCountKey) + 1
        defaults.set(count, forKey: videoGenCountKey)
        updateShouldShow()
    }

    private func updateShouldShow() {
        shouldShowRatingPrompt = shouldShowPrompt()
    }

    func markRated() {
        defaults.set(true, forKey: hasRatedKey)
        shouldShowRatingPrompt = false
    }

    /// Закрытие без оценки: если показали по видео — больше не показывать по видео.
    func dismissPrompt() {
        if defaults.integer(forKey: videoGenCountKey) >= 3 {
            markVideoPromptShown()
        }
        shouldShowRatingPrompt = false
    }

    /// Показывать: каждое 3-е открытие (3, 6, 9...) или при 3-й генерации видео (один раз).
    /// ТЕСТ: показываем при каждом открытии (для отладки).
    func shouldShowPrompt() -> Bool {
        guard !defaults.bool(forKey: hasRatedKey) else { return false }
        // DEBUG: показывать каждое открытие
        let appOpens = defaults.integer(forKey: appOpenCountKey)
        if appOpens > 0 { return true }
        let videoGens = defaults.integer(forKey: videoGenCountKey)
        let hasShownForVideo = defaults.bool(forKey: hasShownForVideoKey)
        if videoGens >= 3 && !hasShownForVideo { return true }
        // if appOpens > 0 && appOpens % 3 == 0 { return true }
        return false
    }

    /// После показа по счётчику видео — больше не показывать по видео.
    func markVideoPromptShown() {
        defaults.set(true, forKey: hasShownForVideoKey)
    }
}
