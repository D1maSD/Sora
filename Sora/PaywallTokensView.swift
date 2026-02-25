//
//  PaywallTokensView.swift
//  Sora
//
//  Экран покупки токенов: продукты из PurchaseManager.tokenProducts (paywall "tokens"),
//  логика покупки как в TokensPaywallsView (Demo).
//

import SwiftUI
import ApphudSDK

struct PaywallTokensView: View {
    var onDismiss: (() -> Void)? = nil
    var onPrivacyPolicy: (() -> Void)? = nil
    var onTermsOfUse: (() -> Void)? = nil

    @EnvironmentObject var tokensStore: TokensStore
    @EnvironmentObject var purchaseManager: PurchaseManager
    @Environment(\.dismiss) var dismiss

    @State private var pickedProd: ApphudProduct?
    @State private var showErrorAlert = false
    @State private var canClose = false

    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height

    var body: some View {
        ZStack {
            Color.black
                .frame(width: screenWidth, height: screenHeight)
                .ignoresSafeArea(.all)

            Image("paywallBack")
                .resizable()
                .scaledToFill()
                .frame(width: screenWidth, height: screenHeight)
                .clipped()
                .ignoresSafeArea(.all)

            VStack {
                HStack {
                    Spacer()
                    if !purchaseManager.isLoading && canClose {
                        Button(action: { onDismiss?(); dismiss() }) {
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
                }
                Spacer()
            }
            .allowsHitTesting(true)

            GeometryReader { geo in
                tokensContent(geo: geo)
            }
        }
        .clipped()
        .ignoresSafeArea(.all)
        .overlay {
            if purchaseManager.isLoading {
                ProgressView()
                    .tint(Color.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
            }
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {
                purchaseManager.failRestoreText = nil
                purchaseManager.purchaseError = nil
            }
        } message: {
            Text(purchaseManager.purchaseError ?? purchaseManager.failRestoreText ?? "")
        }
        .onAppear {
            canClose = false
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 4_000_000_000)
                canClose = true
            }
            if purchaseManager.purchaseError != nil || purchaseManager.failRestoreText != nil {
                showErrorAlert = true
            }
        }
        .onChange(of: purchaseManager.failRestoreText != nil) { _, newValue in
            if newValue { showErrorAlert = true }
        }
        .onChange(of: purchaseManager.purchaseError != nil) { _, newValue in
            if newValue { showErrorAlert = true }
        }
        .animation(.easeInOut(duration: 0.2), value: purchaseManager.isLoading)
    }

    private func tokensContent(geo: GeometryProxy) -> some View {
        VStack {
            Spacer()
            VStack(alignment: .center, spacing: 8) {
                Text("Need more generations?")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                Text("Buy additional tokens")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.5))
                HStack(spacing: 4) {
                    Text("My tokens: ")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    Text(PaywallTokensView.tokensString(tokensStore.tokens))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#6CABE9"))
                }
            }
            .padding(.bottom, 24)

            if purchaseManager.tokenProducts.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(Color.white)
                        .scaleEffect(1.5)
                    if let error = purchaseManager.purchaseError {
                        Text(error)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 32)
            } else {
                VStack(spacing: 12) {
                    ForEach(purchaseManager.tokenProducts, id: \.productId) { product in
                        Button {
                            pickedProd = product
                        } label: {
                            productCard(prod: product, isPicked: pickedProd == product)
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            if pickedProd == nil || (pickedProd?.price ?? 0) > product.price {
                                pickedProd = product
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }

            if !purchaseManager.tokenProducts.isEmpty {
                Button {
                    guard let pickedProd else { return }
                    purchaseManager.makePurchase(product: pickedProd) { success, _ in
                        if success {
                            let added = Self.tokensCount(from: pickedProd.productId)
                            if added > 0 {
                                tokensStore.tokens += added
                            }
                            onDismiss?()
                            dismiss()
                        }
                    }
                } label: {
                    Text("Buy tokens")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(
                                    LinearGradient(
                                        colors: pickedProd == nil || purchaseManager.isLoading
                                            ? [Color.gray.opacity(0.5), Color.gray.opacity(0.5)]
                                            : [Color(hex: "#6CABE9"), Color(hex: "#2F76BC")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 28))
                }
                .disabled(pickedProd == nil || purchaseManager.isLoading)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }

            HStack {
                Button(action: {
                    if let url = URL(string: PolicyURL.privacy) { UIApplication.shared.open(url) }
                    onPrivacyPolicy?()
                }) {
                    Text("Privacy Policy")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                Button(action: {
                    if let url = URL(string: PolicyURL.usageTerms) { UIApplication.shared.open(url) }
                    onTermsOfUse?()
                }) {
                    Text("Terms of Use")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 52)
        }
        .frame(width: geo.size.width)
    }

    @ViewBuilder
    private func productCard(prod: ApphudProduct, isPicked: Bool) -> some View {
        HStack {
            HStack(spacing: 4) {
                Text(PaywallTokensView.tokensString(Self.tokensCount(from: prod.productId)))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                Text(" tokens")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 10)
            Spacer()
            Text(prod.localizedPrice)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
                .padding(.trailing, 10)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 23)
        .background(Color(hex: "#1F2022"))
        .cornerRadius(14)
        .overlay {
            if isPicked {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(hex: "#6CABE9"), lineWidth: 2)
            }
        }
        .animation(.snappy(duration: 0.2), value: isPicked)
        .contentShape(RoundedRectangle(cornerRadius: 14))
    }

    /// Количество токенов из productId (например "100_tokens" → 100).
    private static func tokensCount(from productId: String) -> Int {
        let components = productId.components(separatedBy: "_")
        if let first = components.first, let count = Int(first) { return count }
        let regex = try? NSRegularExpression(pattern: "^([0-9]+)", options: [])
        let range = NSRange(location: 0, length: productId.utf16.count)
        guard let match = regex?.firstMatch(in: productId, options: [], range: range),
              let matchRange = Range(match.range, in: productId),
              let count = Int(String(productId[matchRange])) else { return 0 }
        return count
    }

    private static func tokensString(_ value: Int) -> String {
        let f = NumberFormatter()
        f.usesGroupingSeparator = false
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

#Preview {
    PaywallTokensView(onDismiss: {}, onPrivacyPolicy: {}, onTermsOfUse: {})
        .environmentObject(TokensStore())
        .environmentObject(PurchaseManager.shared)
}
