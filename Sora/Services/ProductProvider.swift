//
//  ProductProvider.swift
//  Sora
//

import Foundation

struct PaywallModel: Equatable {
    let identifier: String
    let productIds: [String]
}

protocol ProductProvider {
    func fetchPaywalls() async throws -> [PaywallModel]
}

