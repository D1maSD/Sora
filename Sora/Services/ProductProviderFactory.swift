//
//  ProductProviderFactory.swift
//  Sora
//

import Foundation

enum ProductProviderFactory {
    static func make() -> ProductProvider {
        if AppFeatures.useAdaptyCatalog {
            return AdaptyProductProvider()
        } else {
            return ApphudProductProvider()
        }
    }
}

