//
//  ApphudProductProvider.swift
//  Sora
//

import Foundation
import ApphudSDK

final class ApphudProductProvider: ProductProvider {
    func fetchRawPaywalls() async -> [ApphudPaywall] {
        await Apphud.fetchPaywallsWithFallback()
    }

    func fetchPaywalls() async throws -> [PaywallModel] {
        let paywalls = await fetchRawPaywalls()
        return paywalls.map {
            PaywallModel(identifier: $0.identifier, productIds: $0.products.map(\.productId))
        }
    }
}

