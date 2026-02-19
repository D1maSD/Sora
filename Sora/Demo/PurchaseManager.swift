import SwiftUI
import Combine
import ApphudSDK
import AdServices
import OSLog

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
#if DEBUG
        Apphud.userID()
#else
        Apphud.userID()
#endif
    }
    
    var isReady: Bool {
        purchaseState == .ready && !products.isEmpty && paywall != nil
    }
    
    var isLoading: Bool {
        purchaseState == .loading || purchaseState == .purchasing
    }

    static let shared = PurchaseManager()
    
    private init() {
        logger.info("PurchaseManager: Initializing Apphud SDK")
        Apphud.setPaywallsCacheTimeout(3600)
        Apphud.start(apiKey: "app_MJp2QdcqMLP5XCgB8pAjZAhzAs2nva")
        logger.info("PurchaseManager: Apphud.start() called")
        
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
        self.isSubscribed = true
#else
        self.isSubscribed = Apphud.hasPremiumAccess()
#endif
        isShowedPaywall = !isSubscribed && isOnboardingFinished
    }
    
    private func loadPaywalls() async {
        logger.info("PurchaseManager: Starting paywall fetch")
        let paywalls = await Apphud.fetchPaywallsWithFallback()
        logger.info("PurchaseManager: Fetched \(paywalls.count) paywalls")
        self.configure(with: paywalls)
    }

    private func configure(with paywalls: [ApphudPaywall]) {
        logger.info("PurchaseManager: Configuring paywalls, received \(paywalls.count) paywalls")
        logger.info("PurchaseManager: Available paywall identifiers: \(paywalls.map { $0.identifier }.joined(separator: ", "))")
        
        if let main = paywalls.first(where: { $0.identifier == "main" }) ?? paywalls.first {
            self.paywall = main
            self.products = main.products
            logger.info("PurchaseManager: Configured main paywall '\(main.identifier)' with \(main.products.count) products")
            
            if main.products.isEmpty {
                logger.warning("PurchaseManager: Main paywall has no products!")
            } else {
                let productIds = main.products.map { $0.productId }.joined(separator: ", ")
                logger.info("PurchaseManager: Main paywall products: \(productIds)")
            }
        } else {
            logger.error("PurchaseManager: No main paywall found")
            self.paywall = nil
            self.products = []
        }
        
        if let tokens = paywalls.first(where: { $0.identifier == "tokens" }) {
            self.paywallTokens = tokens
            self.tokenProducts = tokens.products
            logger.info("PurchaseManager: Configured tokens paywall '\(tokens.identifier)' with \(tokens.products.count) products")
            
            if !tokens.products.isEmpty {
                let productIds = tokens.products.map { $0.productId }.joined(separator: ", ")
                logger.info("PurchaseManager: Tokens paywall products: \(productIds)")
            }
        } else {
            logger.warning("PurchaseManager: Tokens paywall not found")
            self.paywallTokens = nil
            self.tokenProducts = []
        }
        
        if let avatars = paywalls.first(where: { $0.identifier == "avatars" }) {
            self.paywallAvatars = avatars
            self.avatarsProducts = avatars.products
            logger.info("PurchaseManager: Configured avatars paywall '\(avatars.identifier)' with \(avatars.products.count) products")
            
            if !avatars.products.isEmpty {
                let productIds = avatars.products.map { $0.productId }.joined(separator: ", ")
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
            let result = await Apphud.fallbackPurchase(product: product)
            
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
                
                self.isSubscribed = Apphud.hasPremiumAccess()
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

