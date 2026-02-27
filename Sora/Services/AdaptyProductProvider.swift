//
//  AdaptyProductProvider.swift
//  Sora
//

import Foundation

#if canImport(Adapty)
import Adapty
#endif

enum AdaptyProductProviderError: Error {
    case sdkUnavailable
    case noPaywallsResolved
}

#if canImport(Adapty)
@MainActor
final class AdaptyCatalogCache {
    static let shared = AdaptyCatalogCache()
    private(set) var productsById: [String: AdaptyPaywallProduct] = [:]
    private(set) var pricesById: [String: String] = [:]

    private init() {}

    func set(products: [String: AdaptyPaywallProduct], prices: [String: String]) {
        productsById = products
        pricesById = prices
    }

    func product(for productId: String) -> AdaptyPaywallProduct? {
        productsById[productId.lowercased()]
    }

    func localizedPrice(for productId: String) -> String? {
        pricesById[productId.lowercased()]
    }
}
#endif

final class AdaptyProductProvider: ProductProvider {
    func fetchPaywalls() async throws -> [PaywallModel] {
        #if canImport(Adapty)
        // TODO(HYBRID-CATALOG): Adapty provides catalog (and optionally purchase) in hybrid mode.
        let placementIds = ["main", "tokens", "avatars", "mainRus"]
        var models: [PaywallModel] = []
        var productCache: [String: AdaptyPaywallProduct] = [:]
        var pricesCache: [String: String] = [:]

        for placementId in placementIds {
            do {
                let paywall = try await Adapty.getPaywall(placementId: placementId)
                let products = try await Adapty.getPaywallProducts(paywall: paywall)
                let productIds = products.map(\.vendorProductId)
                for product in products {
                    let key = product.vendorProductId.lowercased()
                    productCache[key] = product
                    pricesCache[key] = product.localizedPrice
                }
                models.append(PaywallModel(identifier: placementId, productIds: productIds))
            } catch {
                continue
            }
        }

        guard !models.isEmpty else {
            throw AdaptyProductProviderError.noPaywallsResolved
        }
        await AdaptyCatalogCache.shared.set(products: productCache, prices: pricesCache)
        return models
        #else
        throw AdaptyProductProviderError.sdkUnavailable
        #endif
    }
}

