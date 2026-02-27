//
//  SettingsView.swift
//  Sora
//

import SwiftUI
import StoreKit
import UserNotifications

extension Notification.Name {
    static let chatCacheDidClear = Notification.Name("ChatCacheDidClear")
}

struct SettingsView: View {
    @EnvironmentObject var tokensStore: TokensStore
    @EnvironmentObject var purchaseManager: PurchaseManager
    let onBack: () -> Void
    
    @State private var notificationsEnabled = false
    @State private var showPaywall = false
    @State private var showRestoreAlert = false
    @State private var cacheSizeBytes: Int64 = 0
    @State private var showClearCacheAlert = false
    @State private var showShareSheet = false
    
    private var cacheSizeString: String {
        let mb = Double(cacheSizeBytes) / (1024 * 1024)
        if mb < 0.01 { return "0 MB" }
        if mb < 1 { return String(format: "%.2f MB", mb) }
        return String(format: "%.1f MB", mb)
    }
    
    private var shareActivityItems: [Any] {
        let url = URL(string: "https://apps.apple.com/app/id6759724131")!
        return [url]
    }
    
    var body: some View {
        ZStack {
            Image("phone")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        supportUsSection
                        purchasesSection
                        infoLegalSection
                    }
                    .padding(.bottom, 40)
                }
                .frame(maxHeight: .infinity)
                footer
            }
        }
        .onChange(of: notificationsEnabled) { _, newValue in
            if newValue {
                notificationsEnabled = false
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                    DispatchQueue.main.async {
                        notificationsEnabled = granted
                    }
                }
            }
        }
        .onAppear {
            cacheSizeBytes = ChatStore.shared.chatCacheSizeInBytes()
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                DispatchQueue.main.async {
                    notificationsEnabled = settings.authorizationStatus == .authorized
                }
            }
        }
        .overlay {
            if showClearCacheAlert {
                ClearCacheAlertView(
                    onCancel: { showClearCacheAlert = false },
                    onClear: {
                        ChatStore.shared.clearAllChatCache()
                        NotificationCenter.default.post(name: .chatCacheDidClear, object: nil)
                        cacheSizeBytes = ChatStore.shared.chatCacheSizeInBytes()
                        showClearCacheAlert = false
                    }
                )
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: shareActivityItems)
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(onDismiss: { showPaywall = false })
                .environmentObject(tokensStore)
                .environmentObject(purchaseManager)
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
    }
    
    private var header: some View {
        ZStack {
            HStack {
                Button(action: onBack) {
                    Image("chevronLeft")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                }
                .background(Color(hex: "#1F2023"))
                .cornerRadius(12)
                
                Spacer()
                
                if !purchaseManager.isSubscribed {
                    Button(action: { showPaywall = true }) {
                        HStack(spacing: 6) {
                            Text("PRO")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(.white)
                            Image("sparkles")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "#6CABE9"),
                                    Color(hex: "#2F76BC")
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal, 40)
            
            Text("Settings")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
        }
        .padding(.top, 20)
        .padding(.bottom, 24)
    }
    
    private var supportUsSection: some View {
        settingsSection(title: "Support us") {
            settingsRow(icon: "starBlue", title: "Rate app", action: {
                if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                    SKStoreReviewController.requestReview(in: windowScene)
                }
            })
            settingsRow(icon: "shareBlue", title: "Share with friends", action: { showShareSheet = true })
        }
    }
    
    private var purchasesSection: some View {
        settingsSection(title: "Purchases & Actions") {
            settingsRow(icon: "starsBlue", title: "Upgrade plan", action: {
                if !purchaseManager.isSubscribed { showPaywall = true }
            })
            settingsRowWithToggle(icon: "bageBlue", title: "Notifications", isOn: $notificationsEnabled)
            settingsRow(icon: "trashBlue", title: "Clear cache", trailing: cacheSizeString, action: { showClearCacheAlert = true })
            settingsRow(icon: "cloudBlue", title: "Restore purchases", action: {
                purchaseManager.restorePurchase { _ in }
            })
        }
    }
    
    private var infoLegalSection: some View {
        settingsSection(title: "Info & legal") {
            settingsRow(icon: "messageBlue", title: "Contact us", action: {
                if let url = URL(string: "https://forms.gle/NPFjqanjYhaenH7J8") {
                    UIApplication.shared.open(url)
                }
            })
            settingsRow(icon: "fileBlue", title: "Privacy Policy", action: {
                if let url = URL(string: PolicyURL.privacy) { UIApplication.shared.open(url) }
            })
            settingsRow(icon: "filesBlue", title: "Usage Policy", action: {
                if let url = URL(string: PolicyURL.usageTerms) { UIApplication.shared.open(url) }
            })
        }
    }
    
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white.opacity(1.0))
                .padding(.horizontal, 30)
            
            VStack(spacing: 8) {
                content()
            }
            .padding(.horizontal, 30)
        }
    }
    
    private func settingsRow(icon: String, title: String, trailing: String? = nil, action: (() -> Void)? = nil) -> some View {
        Button(action: { action?() }) {
            HStack(spacing: 12) {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                
                Text(title)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.white)
                
                Spacer()
                
                if let trailing = trailing {
                    Text(trailing)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Image("chevronRightBlue")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(Color(hex: "#C71B3"))
                
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6.5)
        }
        .buttonStyle(.plain)
        .background(Color.black.opacity(0.7))
        .cornerRadius(12)
    }
    
    private func settingsRowWithToggle(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            if icon == "bell" {
                Image(systemName: "bell")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "#2F76BC"))
                    .frame(width: 30, height: 30)
            } else {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
            }
            
            Text(title)
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color(hex: "#2F76BC"))
                .padding(.trailing, 10)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6.5)
        .background(Color.black.opacity(0.7))
        .cornerRadius(12)
    }
    
    private var footer: some View {
        Text("App Version: 1.0.0")
            .font(.system(size: 13, weight: .regular))
            .foregroundColor(.white.opacity(0.5))
            .padding(.bottom, 34)
    }
}

private let clearCacheAlertDividerHeight: CGFloat = 0.8
private let clearCacheAlertDividerColor = Color(hex: "#333334")

struct ClearCacheAlertView: View {
    let onCancel: () -> Void
    let onClear: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture(perform: onCancel)
            
            VStack(spacing: 0) {
                Text("Clear cache?")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 18)
                    .padding(.bottom, 8)
                
                Text("The cached files of your videos will be")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 15)
                Text("deleted from your phone's memory. But")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 15)
                Text("your download history will be retained.")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 15)
                    .padding(.bottom, 20)
                
                Rectangle()
                    .fill(clearCacheAlertDividerColor)
                    .frame(height: clearCacheAlertDividerHeight)
                
                HStack(spacing: 0) {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(Color(hex: "#0C4CD6"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .buttonStyle(.plain)
                    
                    Rectangle()
                        .fill(clearCacheAlertDividerColor)
                        .frame(width: clearCacheAlertDividerHeight, height: 44)
                    
                    Button(action: onClear) {
                        Text("Clear")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(hex: "#FF453A"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: 280)
            .background(Color(hex: "#232323"))
            .cornerRadius(14)
        }
    }
}

#Preview {
    SettingsView(onBack: {})
        .environmentObject(TokensStore())
        .environmentObject(PurchaseManager.shared)
}
