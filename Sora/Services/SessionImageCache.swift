//
//  SessionImageCache.swift
//  Sora
//
//  Кэш изображений в рамках одной сессии приложения. После перезапуска приложения кэш пуст.
//

import Foundation
import SwiftUI
import UIKit

/// In-memory cache for remote images (effect previews, category cards). Cleared on app restart.
final class SessionImageCache {
    static let shared = SessionImageCache()
    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 200
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
    }

    func image(for urlString: String) -> UIImage? {
        cache.object(forKey: urlString as NSString)
    }

    func setImage(_ image: UIImage, for urlString: String) {
        let cost = image.jpegData(compressionQuality: 1)?.count ?? 0
        cache.setObject(image, forKey: urlString as NSString, cost: cost)
    }
}

// MARK: - View: загрузка с кэшем (в рамках сессии)

struct CachedAsyncImage: View {
    let urlString: String
    var placeholder: () -> AnyView = { AnyView(ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)) }
    var failure: () -> AnyView = { AnyView(Image(systemName: "photo").foregroundColor(.white.opacity(0.5))) }

    @State private var image: UIImage?
    @State private var loadFailed = false

    var body: some View {
        Group {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else if loadFailed {
                failure()
            } else {
                placeholder()
            }
        }
        .onAppear {
            if image != nil { return }
            if let cached = SessionImageCache.shared.image(for: urlString) {
                image = cached
                return
            }
            loadImage()
        }
        .onChange(of: urlString) { _, newURL in
            if let cached = SessionImageCache.shared.image(for: newURL) {
                image = cached
                loadFailed = false
            } else {
                image = nil
                loadFailed = false
                loadImage()
            }
        }
    }

    private func loadImage() {
        let key = urlString
        guard !key.isEmpty, let url = URL(string: key) else {
            loadFailed = true
            return
        }
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        SessionImageCache.shared.setImage(uiImage, for: key)
                        if urlString == key {
                            image = uiImage
                            loadFailed = false
                        }
                    }
                } else {
                    await MainActor.run { if urlString == key { loadFailed = true } }
                }
            } catch {
                await MainActor.run { if urlString == key { loadFailed = true } }
            }
        }
    }
}
