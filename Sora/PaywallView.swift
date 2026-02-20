//
//  PaywallView.swift
//  Sora
//
//  Экран пейвола подписки PRO (Annual/Weekly).
//

import SwiftUI
import ApphudSDK
import StoreKit

struct PaywallView: View {
    var onDismiss: (() -> Void)? = nil
    var onContinue: (() -> Void)? = nil
    var onPrivacyPolicy: (() -> Void)? = nil
    var onRestorePurchases: (() -> Void)? = nil
    var onTermsOfUse: (() -> Void)? = nil
    
    @EnvironmentObject var tokensStore: TokensStore
    @EnvironmentObject var purchaseManager: PurchaseManager
    @State private var showRestoreAlert = false
    
    /// true = выбран Annual (верхний), false = выбран Weekly (нижний)
    @State private var isAnnualSelected = true
    /// Цены из Apphud (yearly_49.99_not_trial → Annual, week_6.99_not_trial → Weekly)
    @State private var yearlyPriceString: String = "49.99"
    @State private var weeklyPriceString: String = "6.99"
    
    private let blueGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(hex: "#6CABE9"),
            Color(hex: "#2F76BC")
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    var body: some View {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        ZStack {
            // Подложка и картинка — по размеру всего экрана, без safe area (без отступов по краям)
            Color.black
                .frame(width: screenWidth, height: screenHeight)
                .ignoresSafeArea(.all)
            
            Image("paywallBack")
                .resizable()
                .scaledToFill()
                .frame(width: screenWidth, height: screenHeight)
                .clipped()
                .ignoresSafeArea(.all)
            
            // Кнопка закрытия в правом верхнем углу
            VStack {
                HStack {
                    Spacer()
                    Button(action: { onDismiss?() }) {
                        Image("xmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .foregroundColor(.white)
                            .contentShape(Rectangle())
                    }
                    .opacity(0.2)
                    .padding(.top, 55)
                    .padding(.trailing, 10)
                }
                Spacer()
            }
            .allowsHitTesting(true)
            
            // Контент: в GeometryReader, чтобы не сдвигаться (geo = область с учётом safe area)
            GeometryReader { geo in
                subscriptionContent(geo: geo)
            }
        }
        .clipped()
        .ignoresSafeArea(.all)
        .task { await loadApphudPrices() }
    }
    
    // MARK: - Subscription (PRO)
    private func subscriptionContent(geo: GeometryProxy) -> some View {
        VStack {
            Spacer()
            
            // Большой тайтл в 2 строчки
            VStack(alignment: .center, spacing: 4) {
                Text("Unreal videos and photo")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                        Text("with PRO")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 16)
                    
                    // Три пункта: слева sparkles 15×15, справа текст; айтемы .leading
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 5) {
                            Image("sparkles")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundColor(.white)
                            Text("Access to all effects")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white)
                        }
                        HStack(spacing: 5) {
                            Image("sparkles")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundColor(.white)
                            Text("Unlimited generation")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white)
                        }
                        HStack(spacing: 5) {
                            Image("sparkles")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundColor(.white)
                            Text("Access to all functions")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 20)
                    
                    VStack(spacing: 7) {
                        Button(action: { isAnnualSelected = true }) {
                            ZStack(alignment: .leading) {
                                Image(isAnnualSelected ? "firstOn" : "firstOff")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 60)
                                    .clipped()
                                    .cornerRadius(14)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Just $\(yearlyPriceString) / Annual")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text("Auto renewable. Cancel anytime.")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(.white.opacity(0.4))
                                }
                                .padding(.leading, 52)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: { isAnnualSelected = false }) {
                            ZStack(alignment: .leading) {
                                Image(isAnnualSelected ? "secondOff" : "secondOn")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 60)
                                    .clipped()
                                    .cornerRadius(14)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Just $\(weeklyPriceString) / Weekly")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text("Auto renewable. Cancel anytime.")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(.white.opacity(0.4))
                                }
                                .padding(.leading, 52)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 70)
                    .padding(.bottom, 0)
                    
                    HStack(spacing: 2) {
                        Image("clockGrayArrow")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25, height: 25)
                            .foregroundColor(.white.opacity(0.4))
                        Text("Cancel Anytime")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(.bottom, 0)
                    
                    Button(action: {
                        onContinue?()
                        onDismiss?()
                    }) {
                        Text("Continue")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(blueGradient)
                            .cornerRadius(28)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 15)
                    
                    HStack {
                        Button(action: {
                            if let url = URL(string: PolicyURL.privacy) { UIApplication.shared.open(url) }
                            onPrivacyPolicy?()
                        }) {
                            Text("Privacy Policy")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button(action: {
                            purchaseManager.restorePurchase { _ in }
                            onRestorePurchases?()
                        }) {
                            Text("Restore Purchases")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                        Button(action: {
                            if let url = URL(string: PolicyURL.usageTerms) { UIApplication.shared.open(url) }
                            onTermsOfUse?()
                        }) {
                            Text("Terms of Use")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 52)
        }
        .alert("Restore", isPresented: $showRestoreAlert) {
            Button("OK", role: .cancel) {
                purchaseManager.failRestoreText = nil
            }
        } message: {
            if let text = purchaseManager.failRestoreText {
                Text(text)
            }
        }
        .onChange(of: purchaseManager.failRestoreText) { _, newValue in
            if newValue != nil { showRestoreAlert = true }
        }
        .frame(width: geo.size.width)
    }
    
    /// Загружает цены из Apphud (yearly_49.99_not_trial, week_6.99_not_trial) и обновляет UI.
    private func loadApphudPrices() async {
        let placementId = "main"
        guard let placement = await Apphud.placement(placementId),
              let paywall = placement.paywall else { return }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        
        for product in paywall.products {
            let id = product.productId.lowercased()
            if id.contains("yearly") {
                if let skProduct = product.skProduct {
                    formatter.locale = skProduct.priceLocale
                    if let str = formatter.string(from: skProduct.price) {
                        let trimmed = str.replacingOccurrences(of: formatter.currencySymbol, with: "").trimmingCharacters(in: .whitespaces)
                        await MainActor.run { yearlyPriceString = trimmed }
                    }
                } else if let num = parsePriceFromProductId(product.productId) {
                    await MainActor.run { yearlyPriceString = num }
                }
            } else if id.contains("week") {
                if let skProduct = product.skProduct {
                    formatter.locale = skProduct.priceLocale
                    if let str = formatter.string(from: skProduct.price) {
                        let trimmed = str.replacingOccurrences(of: formatter.currencySymbol, with: "").trimmingCharacters(in: .whitespaces)
                        await MainActor.run { weeklyPriceString = trimmed }
                    }
                } else if let num = parsePriceFromProductId(product.productId) {
                    await MainActor.run { weeklyPriceString = num }
                }
            }
        }
    }
    
    /// Парсит цену из productId вида "yearly_49.99_not_trial" или "week_6.99_not_trial".
    private func parsePriceFromProductId(_ productId: String) -> String? {
        let parts = productId.split(separator: "_")
        guard parts.count >= 2, let lastNum = parts.dropFirst().first(where: { Double($0) != nil }) else { return nil }
        return String(lastNum)
    }
}

#Preview {
    PaywallView(onDismiss: {}, onContinue: {}, onPrivacyPolicy: {}, onRestorePurchases: {}, onTermsOfUse: {})
        .environmentObject(TokensStore())
        .environmentObject(PurchaseManager.shared)
}
