import ApphudSDK
import StoreKit
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "demo", category: "ApphudExtension")

extension Apphud {
    @MainActor
    static func fetchPaywallsWithFallback() async -> [ApphudPaywall] {
        logger.info("Apphud+: Fetching SKProducts")
        _ = await Apphud.fetchSKProducts()

        logger.info("Apphud+: Loading remote paywalls")
        let remote: [ApphudPaywall] = await withCheckedContinuation { continuation in
            Apphud.paywallsDidLoadCallback { paywalls, error in
                if let error = error {
                    logger.error("Apphud+: Failed to load remote paywalls - \(error.localizedDescription)")
                } else {
                    logger.info("Apphud+: Loaded \(paywalls.count) remote paywalls")
                }
                continuation.resume(returning: paywalls)
            }
        }

        guard !remote.isEmpty else {
            logger.warning("Apphud+: No remote paywalls, loading fallback")
            let fallback: [ApphudPaywall] = await withCheckedContinuation { continuation in
                Apphud.loadFallbackPaywalls { paywalls, error in
                    if let error = error {
                        logger.error("Apphud+: Failed to load fallback paywalls - \(error.localizedDescription)")
                    } else if let paywalls = paywalls {
                        logger.info("Apphud+: Loaded \(paywalls.count) fallback paywalls")
                    }
                    continuation.resume(returning: paywalls ?? [])
                }
            }
            return fallback
        }

        return remote
    }
    
    @MainActor static func fallbackPurchase(product: ApphudProduct) async -> Bool {
        logger.info("Apphud+: Starting purchase for product \(product.productId)")
        let success: Bool
        
        if (Apphud.isSandbox() || product.skProduct == nil), let sk2Product = try? await product.product() {
            logger.info("Apphud+: Using StoreKit 2 purchase method")
            let result = await Apphud.purchase(sk2Product)
            if Apphud.isSandbox(), result.transaction != nil {
                logger.info("Apphud+: Purchase successful (sandbox transaction)")
                success = true
            } else if let subscription = result.subscription, subscription.isActive() {
                logger.info("Apphud+: Purchase successful (active subscription)")
                success = true
            } else if let purchase = result.nonRenewingPurchase, purchase.isActive() {
                logger.info("Apphud+: Purchase successful (active non-renewing purchase)")
                success = true
            } else {
                logger.error("Apphud+: Purchase failed - no active subscription/purchase")
                success = false
            }
        } else {
            logger.info("Apphud+: Using StoreKit 1 purchase method")
            let result = await Apphud.purchase(product)
            if !result.success, Apphud.isSandbox(), result.transaction?.transactionState == .purchased {
                logger.info("Apphud+: Purchase successful (sandbox transaction state)")
                success = true
            } else if let subscription = result.subscription, subscription.isActive() {
                logger.info("Apphud+: Purchase successful (active subscription)")
                success = true
            } else if let purchase = result.nonRenewingPurchase, purchase.isActive() {
                logger.info("Apphud+: Purchase successful (active non-renewing purchase)")
                success = true
            } else {
                logger.error("Apphud+: Purchase failed - result.success=\(result.success), transactionState=\(String(describing: result.transaction?.transactionState))")
                success = false
            }
        }
        
        logger.info("Apphud+: Purchase completed with result: \(success)")
        return success
    }
}


extension ApphudProduct {
    private var provider: ProductDataProvider {
        if let skProduct {
            SKProductDataProvider(skProduct: skProduct)
        } else {
            LocalStoreKitProductDataProvider(localProduct: StoreKitContent.defaultContent.products.first(where: { $0.productID == productId })!)
        }
    }

    var isTrial: Bool { provider.isTrial }
    var price: Decimal { provider.price }
    var localizedPrice: String { provider.localizedPrice }
    var localizedPriceWeek: String { provider.localizedPriceWeek }
    var pricePerWeek: Decimal { provider.pricePerWeek }
    var localizedPeriod: String? { provider.localizedPeriod }
    var localizedIntroductory: String? { provider.localizedIntroductory }
    var fullPrice: String { provider.fullPrice }
    var timeString: String { provider.timeString }
    var revertedFullPrice: String { provider.revertedFullPrice }
    var firstPaymentPrice: Decimal { provider.firstPaymentPrice }
    var firstPaymentLocalizedPrice: String { provider.firstPaymentLocalizedPrice }
    func firstPaymentLocalizedPriceDivided(by divider: Decimal, minimumFractionDigits: Int = 0, maximumFractionDigits: Int = 2) -> String {
        provider.firstPaymentLocalizedPriceDivided(by: divider, minimumFractionDigits: minimumFractionDigits, maximumFractionDigits: maximumFractionDigits)
    }
    func localizedPriceDivided(by divider: Decimal, minimumFractionDigits: Int = 0, maximumFractionDigits: Int = 2) -> String {
        provider.localizedPriceDivided(by: divider, minimumFractionDigits: minimumFractionDigits, maximumFractionDigits: maximumFractionDigits)
    }
    
    var isLifetime: Bool { provider.subscriptionPeriod == nil }
}

struct ProductDataPeriod {
    let unit: NSCalendar.Unit
    let numberOfUnits: Int

    private static var calendar: Calendar {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "en_US")
        return calendar
    }

    func format(omitOneUnit: Bool) -> String {
        var unit = unit
        var numberOfUnits = numberOfUnits
        if unit == .day, numberOfUnits == 7 {
            unit = .weekOfMonth
            numberOfUnits = 1
        }
        let componentFormatter: DateComponentsFormatter = {
            let formatter = DateComponentsFormatter()
            formatter.maximumUnitCount = 1
            formatter.unitsStyle = .full
            formatter.zeroFormattingBehavior = .dropAll
            formatter.calendar = Self.calendar
            formatter.allowedUnits = [unit]
            return formatter
        }()
        var dateComponents = DateComponents()
        dateComponents.calendar = Self.calendar
        switch unit {
        case .day:
            if omitOneUnit, numberOfUnits == 1 { return "day" }
            dateComponents.setValue(numberOfUnits, for: .day)
        case .weekOfMonth:
            if omitOneUnit, numberOfUnits == 1 { return "week" }
            dateComponents.setValue(numberOfUnits, for: .weekOfMonth)
        case .month:
            if omitOneUnit, numberOfUnits == 1 { return "month" }
            dateComponents.setValue(numberOfUnits, for: .month)
        case .year:
            if omitOneUnit, numberOfUnits == 1 { return "year" }
            dateComponents.setValue(numberOfUnits, for: .year)
        default:
            assertionFailure("invalid storekit")
        }

        return componentFormatter.string(from: dateComponents)!
    }
}

enum ProductDataIntroductory {
    case freeTrial(ProductDataPeriod)
    case payUpFront(Decimal, ProductDataPeriod)
    case payAsYouGo(Decimal, ProductDataPeriod, Int)
}

protocol ProductDataProvider {
    var price: Decimal { get }
    var priceLocale: Locale { get }
    var subscriptionPeriod: ProductDataPeriod? { get }
    var introductory: ProductDataIntroductory? { get }
}

extension ProductDataProvider {
    var isTrial: Bool {
        if case .freeTrial = introductory {
            return true
        } else {
            return false
        }
    }

    var localizedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: price as NSNumber)!
    }
    
    var localizedPriceWeek: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        
        guard let subscriptionPeriod = subscriptionPeriod else {
            return formatter.string(from: price as NSNumber)!
        }
        
        let weeksInPeriod: Decimal
        switch subscriptionPeriod.unit {
        case .day:
            weeksInPeriod = Decimal(subscriptionPeriod.numberOfUnits) / 7.0
        case .weekOfMonth:
            weeksInPeriod = Decimal(subscriptionPeriod.numberOfUnits)
        case .month:
            weeksInPeriod = Decimal(subscriptionPeriod.numberOfUnits) * 4.348
        case .year:
            weeksInPeriod = Decimal(subscriptionPeriod.numberOfUnits) * 52.0
        default:
            return formatter.string(from: price as NSNumber)!
        }
        
        let pricePerWeek = price / weeksInPeriod
        
        return formatter.string(from: pricePerWeek as NSNumber)!
    }
    
    var pricePerWeek: Decimal {
        guard let subscriptionPeriod = subscriptionPeriod else {
            return price
        }
        
        let weeksInPeriod: Decimal
        switch subscriptionPeriod.unit {
        case .day:
            weeksInPeriod = Decimal(subscriptionPeriod.numberOfUnits) / 7.0
        case .weekOfMonth:
            weeksInPeriod = Decimal(subscriptionPeriod.numberOfUnits)
        case .month:
            weeksInPeriod = Decimal(subscriptionPeriod.numberOfUnits) * 4.348
        case .year:
            weeksInPeriod = Decimal(subscriptionPeriod.numberOfUnits) * 52.0
        default:
            return price
        }
        
        return price / weeksInPeriod
    }

    var localizedPeriod: String? {
        subscriptionPeriod?.format(omitOneUnit: true)
    }

    var localizedIntroductory: String? {
        introductory.map { introductory in
            switch introductory {
            case .freeTrial(let period):
                return "\(period.format(omitOneUnit: false)) free trial"
            case .payUpFront(let price, let period):
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.locale = priceLocale
                return "first \(period.format(omitOneUnit: false)) for \(formatter.string(from: price as NSNumber)!)"
            case .payAsYouGo(let price, let period, let numberOfPeriods):
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.locale = priceLocale
                return "first \(ProductDataPeriod(unit: period.unit, numberOfUnits: period.numberOfUnits * numberOfPeriods).format(omitOneUnit: false)) for \(formatter.string(from: price as NSNumber)!)/\(period.format(omitOneUnit: true))"
            }
        }
    }

    var fullPrice: String {
        var price = localizedPrice
        if let localizedPeriod {
            price += "/\(localizedPeriod)"
        } else {
            price += " at once"
        }
        if let discount = localizedIntroductory {
            price += " + \(discount)"
        }
        return price
    }

    var revertedFullPrice: String {
        var price = ""
        if let discount = localizedIntroductory {
            price += "\(discount), then "
        }
        price += "\(localizedPrice)"
        if let localizedPeriod {
            price += "/\(localizedPeriod)"
        } else {
            price += " at once"
        }
        return price
    }
    
    var timeString: String {
        (localizedPeriod ?? "").capitalizingFirstLetter()
    }

    var firstPaymentPrice: Decimal {
        if let introductory = introductory {
            switch introductory {
            case .freeTrial(_): return price
            case .payUpFront(let price, _): return price
            case .payAsYouGo(let price, _, _): return price
            }
        } else {
            return price
        }
    }

    var firstPaymentLocalizedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: firstPaymentPrice as NSNumber)!
    }

    func firstPaymentLocalizedPriceDivided(by divider: Decimal, minimumFractionDigits: Int, maximumFractionDigits: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        formatter.minimumFractionDigits = minimumFractionDigits
        formatter.maximumFractionDigits = maximumFractionDigits
        return formatter.string(from: (firstPaymentPrice / divider) as NSNumber)!
    }


    func localizedPriceDivided(by amount: Decimal, minimumFractionDigits: Int, maximumFractionDigits: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        formatter.minimumFractionDigits = 0
        formatter.minimumFractionDigits = minimumFractionDigits
        formatter.maximumFractionDigits = maximumFractionDigits
        return formatter.string(from: (price / amount) as NSNumber)!
    }
}

private struct SKProductDataProvider: ProductDataProvider {
    private let skProduct: SKProduct
    init(skProduct: SKProduct) {
        self.skProduct = skProduct
    }

    var price: Decimal {
        skProduct.price.decimalValue
    }

    var priceLocale: Locale {
        skProduct.priceLocale
    }

    var subscriptionPeriod: ProductDataPeriod? {
        skProduct.subscriptionPeriod.map { period in
            ProductDataPeriod(unit: period.unit.toCalendarUnit(), numberOfUnits: period.numberOfUnits)
        }
    }

    var introductory: ProductDataIntroductory? {
        skProduct.introductoryPrice.map { introductory in
            let period = ProductDataPeriod(unit: introductory.subscriptionPeriod.unit.toCalendarUnit(), numberOfUnits: introductory.subscriptionPeriod.numberOfUnits)
            switch introductory.paymentMode {
            case .freeTrial: return .freeTrial(period)
            case .payUpFront: return .payUpFront(introductory.price.decimalValue, period)
            case .payAsYouGo: return .payAsYouGo(introductory.price.decimalValue, period, introductory.numberOfPeriods)
            }
        }
    }
}

private extension SKProduct.PeriodUnit {
    func toCalendarUnit() -> NSCalendar.Unit {
        switch self {
        case .day:
            return .day
        case .month:
            return .month
        case .week:
            return .weekOfMonth
        case .year:
            return .year
        @unknown default:
            assertionFailure("Unknown period unit")
        }
        return .day
    }
}

private struct LocalStoreKitProductDataProvider: ProductDataProvider {
    private let localProduct: StoreKitContent.Product
    init(localProduct: StoreKitContent.Product) {
        self.localProduct = localProduct
    }

    var price: Decimal {
        Decimal(string: localProduct.displayPrice, locale: priceLocale)!
    }

    var priceLocale: Locale {
        Locale(identifier: "en_US")
    }

    var subscriptionPeriod: ProductDataPeriod? {
        localProduct.recurringSubscriptionPeriod.map { period in
            ProductDataPeriod(unit: period.unit, numberOfUnits: period.numberOfUnits)
        }
    }

    var introductory: ProductDataIntroductory? {
        localProduct.introductoryOffer.map { introductory in
            let period = ProductDataPeriod(unit: introductory.subscriptionPeriod.unit, numberOfUnits: introductory.subscriptionPeriod.numberOfUnits)
            switch introductory.paymentMode {
            case .free: return .freeTrial(period)
            case .payUpFront: return .payUpFront(Decimal(string: introductory.displayPrice!, locale: priceLocale)!, period)
            case .payAsYouGo: return .payAsYouGo(Decimal(string: introductory.displayPrice!, locale: priceLocale)!, period, introductory.numberOfPeriods!)
            }
        }
    }
}

fileprivate struct StoreKitContent: Decodable {
    let settings: Settings
    let nonRenewingSubscriptions: [Product]?
    let nonConsumableProducts: [Product]?
    let subscriptionGroups: [SubscriptionGroup]?
    fileprivate static let defaultContent = try! JSONDecoder().decode(StoreKitContent.self, from: Data(contentsOf: Bundle.main.url(forResource: nil, withExtension: "storekit")!))

    var products: [Product] {
        (nonRenewingSubscriptions ?? []) +
        (nonConsumableProducts ?? []) +
        (subscriptionGroups ?? []).flatMap(\.subscriptions)
    }

    enum CodingKeys: String, CodingKey {
        case settings = "settings"
        case nonRenewingSubscriptions = "nonRenewingSubscriptions"
        case nonConsumableProducts = "products"
        case subscriptionGroups = "subscriptionGroups"
    }

    struct Settings: Decodable {
        let storefront: String?

        enum CodingKeys: String, CodingKey {
            case storefront = "_storefront"
        }
    }

    struct SubscriptionGroup: Decodable {
        let subscriptions: [Product]

        enum CodingKeys: String, CodingKey {
            case subscriptions = "subscriptions"
        }
    }

    struct Product: Decodable {
        let productID: String
        let displayPrice: String
        let recurringSubscriptionPeriod: Period?
        let introductoryOffer: IntroductoryOffer?

        enum CodingKeys: String, CodingKey {
            case productID = "productID"
            case displayPrice = "displayPrice"
            case recurringSubscriptionPeriod = "recurringSubscriptionPeriod"
            case introductoryOffer = "introductoryOffer"
        }
    }

    struct IntroductoryOffer: Decodable {
        enum PaymentMode: String, Decodable {
            case free
            case payAsYouGo
            case payUpFront
        }
        let paymentMode: PaymentMode
        let subscriptionPeriod: Period
        let numberOfPeriods: Int?
        let displayPrice: String?

        enum CodingKeys: String, CodingKey {
            case paymentMode = "paymentMode"
            case subscriptionPeriod = "subscriptionPeriod"
            case numberOfPeriods = "numberOfPeriods"
            case displayPrice = "displayPrice"
        }
    }

    struct Period: Decodable {
        let unit: NSCalendar.Unit
        let numberOfUnits: Int

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let periodString = try container.decode(String.self)

            guard periodString.first == "P" else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid period format. Must start with 'P'.")
            }

            let duration = periodString.dropFirst()

            let pattern = #"^(\d+)([YMWD])$"#
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let durationString = String(duration)

            guard
                let match = regex.firstMatch(in: durationString, options: [], range: NSRange(location: 0, length: durationString.utf16.count)),
                let numberRange = Range(match.range(at: 1), in: durationString),
                let unitRange = Range(match.range(at: 2), in: durationString),
                let number = Int(durationString[numberRange])
            else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid period format.")
            }

            let unitChar = durationString[unitRange]
            let calendarUnit: NSCalendar.Unit

            switch unitChar {
            case "Y": calendarUnit = .year
            case "M": calendarUnit = .month
            case "W": calendarUnit = .weekOfMonth
            case "D": calendarUnit = .day
            default:
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported time unit: \(unitChar)")
            }

            self.unit = calendarUnit
            self.numberOfUnits = number
        }
    }
}


