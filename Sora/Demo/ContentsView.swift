import SwiftUI

struct ContentsView: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    @State private var showSubPaywall: Bool = false
    @State private var showTokPaywall: Bool = false
    @State private var showAvaPaywall: Bool = false
    
    var body: some View {
        VStack {
            Text("Sub: \(purchaseManager.isSubscribed)")
            Text("Tokens: \(purchaseManager.tokens)")
            Text("Avatars: \(purchaseManager.avatars)")
            
            Button {
                showSubPaywall = true
            } label: {
                Text("Show subs")
            }
            .buttonStyle(.borderedProminent)
            
            if purchaseManager.isSubscribed {
                Button {
                    showTokPaywall = true
                } label: {
                    Text("Show tokens")
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    showAvaPaywall = true
                } label: {
                    Text("Show avatars")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        
        .fullScreenCover(isPresented: $showSubPaywall) {
            PaywallsView()
        }
        .fullScreenCover(isPresented: $showTokPaywall) {
            TokensPaywallsView()
        }
        .fullScreenCover(isPresented: $showAvaPaywall) {
            AvatarsPaywallsView()
        }
    }
}

#Preview {
    ContentsView()
        .environmentObject(PurchaseManager.shared)
}
