import ApphudSDK
import SwiftUI

struct PaywallsView: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    
    @State private var pickedProd: ApphudProduct?
    
    @State private var showErrorAlert: Bool = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            productsPart
            subButton
        }
        .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
        
            .overlay(alignment: .topTrailing, content: {
                if !purchaseManager.isLoading {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color.white)
                    }
                    .padding()
                }
            })
        
            .overlay {
                if purchaseManager.isLoading {
                    ProgressView()
                        .tint(Color.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
        
            .alert("Error", isPresented: $showErrorAlert, actions: {
                Button("Ok", role: .cancel) {
                    purchaseManager.failRestoreText = nil
                    purchaseManager.purchaseError = nil
                }
            }, message: {
                Text(purchaseManager.purchaseError ?? purchaseManager.failRestoreText ?? "")
            })
            .onAppear {
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
    
    var subButton: some View {
        Button {
            guard let pickedProd else { return }
            
            purchaseManager.makePurchase(product: pickedProd, completion: { success, errorMessage in
                if success {
                    dismiss()
                }
            })
        } label: {
            Text("Continue")
                .foregroundStyle(Color.white)
                .font(.system(size: 15, weight: .medium))
                .padding(.vertical, 19.5)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(pickedProd == nil || !purchaseManager.isReady || purchaseManager.isLoading ? Color.gray.opacity(0.5) : Color.blue)
                )
                .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(pickedProd == nil || !purchaseManager.isReady || purchaseManager.isLoading)
    }
    
    var productsPart: some View {
        VStack(spacing: 8) {
            if purchaseManager.purchaseState == .loading || purchaseManager.products.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(Color.white)
                        .scaleEffect(1.5)
                    
                    if let error = purchaseManager.purchaseError {
                        Text(error)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(Color.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 32)
            } else {
                ForEach(purchaseManager.products, id: \.productId) { product in
                    Button {
                        pickedProd = product
                    } label: {
                        productCard(prod: product, isPicked: pickedProd == product)
                    }
                    .onAppear {
                        if pickedProd == nil || (pickedProd?.price ?? 0) > product.price {
                            pickedProd = product
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func productCard(prod: ApphudProduct, isPicked: Bool) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: isPicked ? "checkmark.circle" : "circle")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(isPicked ? Color.white : Color.white.opacity(0.3))
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(prod.timeString.capitalizingFirstLetter() + "ly")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.white)
                    
                    if prod.timeString.lowercased() != "week" {
                        Text(prod.localizedPriceWeek + " / week")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(Color.white.opacity(0.7))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(prod.localizedPrice + " / \(prod.timeString.lowercased())")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 73)
        .overlay(content: {
            if isPicked {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white, lineWidth: 2)
                    .padding(1)
            }
        })
        .animation(.snappy(duration: 0.2), value: isPicked)
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .overlay(alignment: .topTrailing) {
            if prod.timeString.lowercased() != "week" {
                Text("Popular")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue)
                    )
                    .offset(x: -16, y: -5)
            }
        }
    }
}

#Preview {
    PaywallsView()
        .environmentObject(PurchaseManager.shared)
}
