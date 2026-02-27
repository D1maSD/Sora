import SwiftUI
import Combine
import ApphudSDK
import AdServices
import OSLog
#if canImport(Adapty)
import Adapty
#endif

@MainActor
final class PurchaseManager: ObservableObject {
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "demo", category: "PurchaseManager")
    
    enum PurchaseState: Equatable {
        case idle
        case loading
        case ready
        case purchasing
        case error(String)
        
        static func == (lhs: PurchaseState, rhs: PurchaseState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.loading, .loading), (.ready, .ready), (.purchasing, .purchasing):
                return true
            case (.error(let lhsMsg), .error(let rhsMsg)):
                return lhsMsg == rhsMsg
            default:
                return false
            }
        }
    }
    
    @Published private(set) var paywall: ApphudPaywall?
    @Published private(set) var paywallTokens: ApphudPaywall?
    @Published private(set) var paywallAvatars: ApphudPaywall?
    
    @Published private(set) var products: [ApphudProduct] = []
    @Published private(set) var tokenProducts: [ApphudProduct] = []
    @Published private(set) var avatarsProducts: [ApphudProduct] = []
    @Published private(set) var adaptyTokenProductIds: [String] = []
    
    @Published private(set) var isSubscribed: Bool = false
    @Published private(set) var purchaseState: PurchaseState = .idle
    @Published var purchaseError: String? = nil
    @Published var isLoad: Bool = false
    @Published var failRestoreText: String? = nil
    
    @AppStorage("OnBoardEnd") var isOnboardingFinished: Bool = false
    @Published var isShowedPaywall: Bool = false
    
    @Published var tokens: Int = 0
    @Published var avatars: Int = 0
    
    public var userId: String {
        if AppFeatures.useAdaptyCatalog {
            return ""
        }
        return Apphud.userID()
    }
    
    var isReady: Bool {
        purchaseState == .ready && !products.isEmpty && paywall != nil
    }
    
    var isLoading: Bool {
        purchaseState == .loading || purchaseState == .purchasing
    }

    static let shared = PurchaseManager()
    
    // TODO(HYBRID-CATALOG): Known production product IDs used for catalog matching.
    // Purchases still execute via Apphud, these IDs are used only to safely filter catalog source.
    private let knownTokenProductIds: Set<String> = [
        "100_Tokens_9.99",
        "250_Tokens_19.99",
        "500_Tokens_34.99",
        "1000_Tokens_59.99",
        "2000_Tokens_99.99"
    ].map { $0.lowercased() }.reduce(into: Set<String>()) { $0.insert($1) }
    
    private let knownSubscriptionProductIds: Set<String> = [
        "week_6.99_nottrial",
        "yearly_49.99_nottrial",
        "yearly_39.99_nottrial"
    ].map { $0.lowercased() }.reduce(into: Set<String>()) { $0.insert($1) }
    
    private init() {
        logger.info("PurchaseManager: Initializing")
        if !AppFeatures.useAdaptyCatalog {
            Apphud.setPaywallsCacheTimeout(3600)
            // Apphud.start вызывается один раз в SoraApp с ключом ApphudConfig.currentKey
        }
        
        if let storedTokens = KeychainManager.shared.loadInt(forKey: "tokens") {
            self.tokens = storedTokens
            logger.info("PurchaseManager: Loaded tokens from Keychain: \(storedTokens)")
        } else {
            logger.info("PurchaseManager: No tokens value in Keychain, starting from 0")
        }
        
        if let storedAvatars = KeychainManager.shared.loadInt(forKey: "avatars") {
            self.avatars = storedAvatars
            logger.info("PurchaseManager: Loaded avatars from Keychain: \(storedAvatars)")
        } else {
            logger.info("PurchaseManager: No avatars value in Keychain, starting from 0")
        }
        
        purchaseState = .loading
        
        Task {
            await loadPaywalls()
        }
        
#if DEBUG
//        self.isSubscribed = false
//        self.isSubscribed = Apphud.hasPremiumAccess()
        self.isSubscribed = false
#else
        self.isSubscribed = AppFeatures.useAdaptyCatalog ? false : Apphud.hasPremiumAccess()
#endif
        isShowedPaywall = !isSubscribed && isOnboardingFinished
    }
    
    private func loadPaywalls() async {
        logger.info("PurchaseManager: Starting paywall fetch")
        // TODO(HYBRID-CATALOG): Catalog source can be Apphud or Adapty.
        // Purchase execution remains Apphud-based.
        let provider = ProductProviderFactory.make()
        do {
            let catalogPaywalls = try await provider.fetchPaywalls()
            logger.info("PurchaseManager: Catalog paywalls fetched: \(catalogPaywalls.count)")
            if AppFeatures.useAdaptyCatalog {
                self.configureForAdaptyCatalog(catalogPaywalls)
            } else {
                let apphudProvider = ApphudProductProvider()
                let apphudPaywalls = await apphudProvider.fetchRawPaywalls()
                self.configure(with: catalogPaywalls, apphudPaywalls: apphudPaywalls)
            }
        } catch {
            if AppFeatures.useAdaptyCatalog {
                logger.error("PurchaseManager: Catalog provider failed in Adapty mode - \(error.localizedDescription)")
                await MainActor.run {
                    self.purchaseState = .error("Unable to load products")
                }
                return
            }
            logger.error("PurchaseManager: Catalog provider failed, fallback to Apphud catalog - \(error.localizedDescription)")
            let apphudProvider = ApphudProductProvider()
            let apphudPaywalls = await apphudProvider.fetchRawPaywalls()
            let fallbackCatalog = apphudPaywalls.map { PaywallModel(identifier: $0.identifier, productIds: $0.products.map(\.productId)) }
            self.configure(with: fallbackCatalog, apphudPaywalls: apphudPaywalls)
        }
    }

    private func configureForAdaptyCatalog(_ catalogPaywalls: [PaywallModel]) {
        let catalogByIdentifier = Dictionary(uniqueKeysWithValues: catalogPaywalls.map { ($0.identifier, $0) })
        let globalCatalogIds = Set(catalogPaywalls.flatMap(\.productIds).map { $0.lowercased() })

        let mainIds = (catalogByIdentifier["main"]?.productIds ?? []).map { $0.lowercased() }
        let selectedMainIds = mainIds.isEmpty
            ? Array(globalCatalogIds.intersection(knownSubscriptionProductIds))
            : mainIds
        self.products = []
        self.paywall = nil

        let tokenIds = (catalogByIdentifier["tokens"]?.productIds ?? []).map { $0.lowercased() }
        let selectedTokenIds = tokenIds.isEmpty
            ? Array(globalCatalogIds.intersection(knownTokenProductIds))
            : tokenIds
        self.tokenProducts = []
        self.adaptyTokenProductIds = selectedTokenIds
        self.paywallTokens = nil

        self.avatarsProducts = []
        self.paywallAvatars = nil

        if !selectedMainIds.isEmpty || !selectedTokenIds.isEmpty {
            purchaseState = .ready
            purchaseError = nil
            logger.info("PurchaseManager: Adapty catalog configured. subs=\(selectedMainIds.count), tokens=\(selectedTokenIds.count)")
        } else {
            purchaseState = .error("Catalog options are not available. Please try again.")
            purchaseError = "Catalog options are not available. Please try again."
            logger.error("PurchaseManager: Adapty catalog configuration failed - no products")
        }
    }

    private func configure(with catalogPaywalls: [PaywallModel], apphudPaywalls: [ApphudPaywall]) {
        logger.info("PurchaseManager: Configuring paywalls, catalog count \(catalogPaywalls.count), apphud count \(apphudPaywalls.count)")
        logger.info("PurchaseManager: Catalog identifiers: \(catalogPaywalls.map { $0.identifier }.joined(separator: ", "))")
        let catalogByIdentifier = Dictionary(uniqueKeysWithValues: catalogPaywalls.map { ($0.identifier, $0) })
        let globalCatalogIds = Set(catalogPaywalls.flatMap(\.productIds).map { $0.lowercased() })
        
        if let main = apphudPaywalls.first(where: { $0.identifier == "main" }) ?? apphudPaywalls.first {
            let identifierScopedIds = Set((catalogByIdentifier[main.identifier]?.productIds ?? []).map { $0.lowercased() })
            let fallbackIds = globalCatalogIds.intersection(knownSubscriptionProductIds)
            let selectedProducts = filterProducts(main.products, preferredIds: identifierScopedIds, fallbackIds: fallbackIds)
            self.paywall = main
            self.products = selectedProducts
            logger.info("PurchaseManager: Configured main paywall '\(main.identifier)' with \(selectedProducts.count) products")
            
            if selectedProducts.isEmpty {
                logger.warning("PurchaseManager: Main paywall has no products!")
            } else {
                let productIds = selectedProducts.map { $0.productId }.joined(separator: ", ")
                logger.info("PurchaseManager: Main paywall products: \(productIds)")
            }
        } else {
            logger.error("PurchaseManager: No main paywall found")
            self.paywall = nil
            self.products = []
        }
        
        if let tokens = apphudPaywalls.first(where: { $0.identifier == "tokens" }) {
            let identifierScopedIds = Set((catalogByIdentifier[tokens.identifier]?.productIds ?? []).map { $0.lowercased() })
            let fallbackIds = globalCatalogIds.intersection(knownTokenProductIds)
            let selectedProducts = filterProducts(tokens.products, preferredIds: identifierScopedIds, fallbackIds: fallbackIds)
            self.paywallTokens = tokens
            self.tokenProducts = selectedProducts
            logger.info("PurchaseManager: Configured tokens paywall '\(tokens.identifier)' with \(selectedProducts.count) products")
            
            if !selectedProducts.isEmpty {
                let productIds = selectedProducts.map { $0.productId }.joined(separator: ", ")
                logger.info("PurchaseManager: Tokens paywall products: \(productIds)")
            }
        } else {
            logger.warning("PurchaseManager: Tokens paywall not found")
            self.paywallTokens = nil
            self.tokenProducts = []
        }
        
        if let avatars = apphudPaywalls.first(where: { $0.identifier == "avatars" }) {
            let identifierScopedIds = Set((catalogByIdentifier[avatars.identifier]?.productIds ?? []).map { $0.lowercased() })
            let selectedProducts = filterProducts(avatars.products, preferredIds: identifierScopedIds, fallbackIds: [])
            self.paywallAvatars = avatars
            self.avatarsProducts = selectedProducts
            logger.info("PurchaseManager: Configured avatars paywall '\(avatars.identifier)' with \(selectedProducts.count) products")
            
            if !selectedProducts.isEmpty {
                let productIds = selectedProducts.map { $0.productId }.joined(separator: ", ")
                logger.info("PurchaseManager: Avatars paywall products: \(productIds)")
            }
        } else {
            logger.warning("PurchaseManager: Avatars paywall not found")
            self.paywallAvatars = nil
            self.avatarsProducts = []
        }
        
        if self.paywall != nil && !self.products.isEmpty {
            purchaseState = .ready
            purchaseError = nil
            logger.info("PurchaseManager: Configuration completed successfully, state set to ready")
        } else {
            purchaseState = .error("Subscription options not available. Please check your connection and try again.")
            purchaseError = "Subscription options not available. Please check your connection and try again."
            logger.error("PurchaseManager: Configuration failed - no main paywall or products available")
        }
        
        #if DEBUG
        print("[Paywalls] main=\(paywall?.identifier ?? "nil") products=\(products.count)")
        print("[Paywalls] tokens=\(paywallTokens?.identifier ?? "nil") tokenProducts=\(tokenProducts.count)")
        print("[Paywalls] avatars=\(paywallAvatars?.identifier ?? "nil") avatarsProducts=\(avatarsProducts.count)")
        #endif
    }
    
    private func filterProducts(
        _ products: [ApphudProduct],
        preferredIds: Set<String>,
        fallbackIds: Set<String>
    ) -> [ApphudProduct] {
        if !preferredIds.isEmpty {
            let filtered = products.filter { preferredIds.contains($0.productId.lowercased()) }
            if !filtered.isEmpty { return filtered }
        }
        if !fallbackIds.isEmpty {
            let filtered = products.filter { fallbackIds.contains($0.productId.lowercased()) }
            if !filtered.isEmpty { return filtered }
        }
        return products
    }

    var hasTokenProductsForCurrentProvider: Bool {
        if AppFeatures.useAdaptyCatalog {
            return !adaptyTokenProductIds.isEmpty
        }
        return !tokenProducts.isEmpty
    }

    func displayPrice(for product: ApphudProduct) -> String {
        #if canImport(Adapty)
        if AppFeatures.useAdaptyCatalog,
           let adaptyPrice = AdaptyCatalogCache.shared.localizedPrice(for: product.productId),
           !adaptyPrice.isEmpty {
            return adaptyPrice
        }
        #endif
        return product.localizedPrice
    }

    func displayPriceValue(for productId: String) -> String? {
        #if canImport(Adapty)
        if AppFeatures.useAdaptyCatalog,
           let adaptyPrice = AdaptyCatalogCache.shared.localizedPrice(for: productId),
           !adaptyPrice.isEmpty {
            return numericPart(from: adaptyPrice)
        }
        #endif
        return nil
    }

    func makePurchase(productId: String, completion: @escaping(Bool, String?) -> Void) {
        guard purchaseState != .purchasing else {
            completion(false, "Purchase already in progress")
            return
        }
        purchaseState = .purchasing
        purchaseError = nil
        Task { @MainActor in
            let success: Bool
            if AppFeatures.useAdaptyCatalog {
                success = await makeAdaptyPurchase(productId: productId)
            } else {
                guard let product = (products + tokenProducts + avatarsProducts).first(where: { $0.productId == productId }) else {
                    let msg = "Selected product is not available"
                    purchaseError = msg
                    purchaseState = .ready
                    completion(false, msg)
                    return
                }
                success = await Apphud.fallbackPurchase(product: product)
            }

            if success {
                let isTokenProduct = knownTokenProductIds.contains(productId.lowercased())
                let isAvatarProduct = productId.lowercased().contains("avatar")
                if isTokenProduct {
                    let tokensToAdd = extractTokensCount(from: productId)
                    if tokensToAdd > 0 {
                        self.tokens += tokensToAdd
                        Task.detached { [tokens = self.tokens] in
                            _ = await KeychainManager.shared.save(tokens, forKey: "tokens")
                        }
                    }
                }
                if isAvatarProduct {
                    let avatarsToAdd = extractTokensCount(from: productId)
                    if avatarsToAdd > 0 {
                        self.avatars += avatarsToAdd
                        Task.detached { [avatars = self.avatars] in
                            _ = await KeychainManager.shared.save(avatars, forKey: "avatars")
                        }
                    }
                }
                if !AppFeatures.useAdaptyCatalog {
                    self.isSubscribed = Apphud.hasPremiumAccess()
                }
                purchaseState = .ready
                purchaseError = nil
                completion(true, nil)
            } else {
                let msg = purchaseError ?? "Purchase was not completed. Please try again."
                purchaseState = .ready
                purchaseError = msg
                completion(false, msg)
            }
        }
    }

    private func numericPart(from localizedPrice: String) -> String {
        let allowed = CharacterSet(charactersIn: "0123456789.,")
        let filtered = localizedPrice.unicodeScalars.filter { allowed.contains($0) }
        let result = String(String.UnicodeScalarView(filtered))
        return result.isEmpty ? localizedPrice : result
    }

    func makePurchase(product: ApphudProduct, completion: @escaping(Bool, String?) -> Void) {
        guard purchaseState != .purchasing else {
            logger.warning("PurchaseManager: Purchase already in progress, ignoring duplicate request")
            completion(false, "Purchase already in progress")
            return
        }
        
        let allProducts = products + tokenProducts + avatarsProducts
        guard !allProducts.isEmpty else {
            logger.error("PurchaseManager: Cannot purchase - no products loaded from any paywall")
            let errorMsg = "Products are not loaded. Please try again."
            purchaseError = errorMsg
            completion(false, errorMsg)
            return
        }
        
        guard allProducts.contains(where: { $0.productId == product.productId }) else {
            logger.error("PurchaseManager: Product \(product.productId) not found in available products (subs/tokens/avatars)")
            let errorMsg = "Selected product is not available"
            purchaseError = errorMsg
            completion(false, errorMsg)
            return
        }
        
        let isTokenProduct = tokenProducts.contains(where: { $0.productId == product.productId })
        let isAvatarProduct = avatarsProducts.contains(where: { $0.productId == product.productId })
        
        logger.info("PurchaseManager: Starting purchase for product \(product.productId), isTokenProduct: \(isTokenProduct), isAvatarProduct: \(isAvatarProduct)")
        purchaseState = .purchasing
        purchaseError = nil
        
        Task { @MainActor in
            let result: Bool
            if AppFeatures.useAdaptyCatalog {
                result = await makeAdaptyPurchase(productId: product.productId)
            } else {
                result = await Apphud.fallbackPurchase(product: product)
            }
            
            if result {
                logger.info("PurchaseManager: Purchase successful for product \(product.productId)")
                
                if isTokenProduct {
                    let tokensToAdd = extractTokensCount(from: product.productId)
                    if tokensToAdd > 0 {
                        self.tokens += tokensToAdd
                        logger.info("PurchaseManager: Added \(tokensToAdd) tokens. Total tokens: \(self.tokens)")
                        
                        Task.detached { [tokens = self.tokens] in
                            _ = await KeychainManager.shared.save(tokens, forKey: "tokens")
                        }
                    } else {
                        logger.warning("PurchaseManager: Could not extract tokens count from productId: \(product.productId)")
                    }
                }
                
                if isAvatarProduct {
                    let avatarsToAdd = extractTokensCount(from: product.productId)
                    if avatarsToAdd > 0 {
                        self.avatars += avatarsToAdd
                        logger.info("PurchaseManager: Added \(avatarsToAdd) avatars. Total avatars: \(self.avatars)")
                        
                        Task.detached { [avatars = self.avatars] in
                            _ = await KeychainManager.shared.save(avatars, forKey: "avatars")
                        }
                    } else {
                        logger.warning("PurchaseManager: Could not extract avatars count from productId: \(product.productId)")
                    }
                }
                
                if !AppFeatures.useAdaptyCatalog {
                    self.isSubscribed = Apphud.hasPremiumAccess()
                }
                self.purchaseState = .ready
                self.purchaseError = nil
                completion(true, nil)
            } else {
                logger.error("PurchaseManager: Purchase failed for product \(product.productId)")
                let errorMsg = "Purchase was not completed. Please try again."
                self.purchaseState = .ready
                self.purchaseError = errorMsg
                completion(false, errorMsg)
            }
        }
    }

    private func makeAdaptyPurchase(productId: String) async -> Bool {
        #if canImport(Adapty)
        guard let adaptyProduct = AdaptyCatalogCache.shared.product(for: productId) else {
            let errorMsg = "Adapty product is not available."
            purchaseError = errorMsg
            logger.error("PurchaseManager: \(errorMsg) id=\(productId)")
            return false
        }
        do {
            let purchaseResult = try await Adapty.makePurchase(product: adaptyProduct)
            let raw = String(describing: purchaseResult).lowercased()
            if raw.contains("cancel") {
                purchaseError = "Purchase was cancelled."
                logger.info("PurchaseManager: Adapty purchase cancelled for \(productId)")
                return false
            }
            if raw.contains("pending") {
                purchaseError = "Purchase is pending."
                logger.info("PurchaseManager: Adapty purchase pending for \(productId)")
                return false
            }
            return true
        } catch {
            let errorMsg = "Adapty purchase failed: \(error.localizedDescription)"
            purchaseError = errorMsg
            logger.error("PurchaseManager: \(errorMsg)")
            return false
        }
        #else
        let errorMsg = "Adapty SDK is not integrated."
        purchaseError = errorMsg
        logger.error("PurchaseManager: \(errorMsg)")
        return false
        #endif
    }
    
    private func extractTokensCount(from productId: String) -> Int {
        let components = productId.components(separatedBy: "_")
        if let firstComponent = components.first, let count = Int(firstComponent) {
            return count
        }
        
        let regex = try? NSRegularExpression(pattern: "^([0-9]+)", options: [])
        let range = NSRange(location: 0, length: productId.utf16.count)
        if let match = regex?.firstMatch(in: productId, options: [], range: range),
           let matchRange = Range(match.range, in: productId),
           let count = Int(String(productId[matchRange])) {
            return count
        }
        
        return 0
    }

    func restorePurchase(completion: @escaping(Bool) -> Void) {
        logger.info("PurchaseManager: Starting restore purchases")
        if AppFeatures.useAdaptyCatalog {
            logger.info("PurchaseManager: Restore is disabled in Adapty mode")
            failRestoreText = "Restore is unavailable in this mode"
            completion(false)
            return
        }
        Apphud.restorePurchases { [weak self] subscriptions, purchases, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    self.logger.error("PurchaseManager: Restore failed - \(error.localizedDescription)")
                    self.failRestoreText = "Restore purchases failed: \(error.localizedDescription)"
                    completion(false)
                    return
                }

                if let subscriptions = subscriptions, subscriptions.contains(where: { $0.isActive() }) {
                    self.logger.info("PurchaseManager: Restore successful - active subscription found")
                    self.isSubscribed = Apphud.hasPremiumAccess()
                    self.failRestoreText = nil
                    completion(true)
                    return
                }

                if let purchases = purchases, purchases.contains(where: { $0.isActive() }) {
                    self.logger.info("PurchaseManager: Restore successful - active purchase found")
                    self.isSubscribed = Apphud.hasPremiumAccess()
                    self.failRestoreText = nil
                    completion(true)
                    return
                }

                self.logger.warning("PurchaseManager: Nothing to restore")
                self.failRestoreText = "Nothing to restore"
                completion(false)
            }
        }
    }
}

