//
//  SettingsView.swift
//  Sora
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var tokensStore: TokensStore
    let onBack: () -> Void
    
    @State private var notificationsEnabled = false
    @State private var showNotificationsAlert = false
    @State private var showPaywall = false
    
    private var currentUserId: String? {
        KeychainStorage.shared.getUserId()
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
                        userIdSection
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
                showNotificationsAlert = true
                notificationsEnabled = false
            }
        }
        .overlay {
            if showNotificationsAlert {
                AllowNotificationsAlertView(
                    onCancel: { showNotificationsAlert = false },
                    onAllow: {
                        notificationsEnabled = true
                        showNotificationsAlert = false
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(onDismiss: { showPaywall = false })
                .environmentObject(tokensStore)
        }
    }
    
    private var header: some View {
        ZStack(alignment: .trailing) {
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
                
                Text("Settings")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.leading, 12)
                
                Spacer()
            }
            .padding(.horizontal, 40)
            
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
            .padding(.trailing, 40)
        }
        .padding(.top, 20)
        .padding(.bottom, 24)
    }
    
    private var supportUsSection: some View {
        settingsSection(title: "Support us") {
            settingsRow(icon: "starBlue", title: "Rate app")
            settingsRow(icon: "shareBlue", title: "Share with friends")
        }
    }
    
    private var purchasesSection: some View {
        settingsSection(title: "Purchases & Actions") {
            settingsRow(icon: "starsBlue", title: "Upgrade plan")
            settingsRowWithToggle(icon: "bageBlue", title: "Notifications", isOn: $notificationsEnabled)
            settingsRow(icon: "trashBlue", title: "Clear cache", trailing: "5 MB")
            settingsRow(icon: "cloudBlue", title: "Restore purchases")
        }
    }
    
    private var userIdSection: some View {
        settingsSection(title: "Account") {
            VStack(alignment: .leading, spacing: 8) {
                Text("User ID (send to support to get tokens)")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 10)
                if let id = currentUserId {
                    HStack(spacing: 12) {
                        Text(id)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer(minLength: 8)
                        Button(action: {
                            UIPasteboard.general.string = id
                        }) {
                            Text("Copy")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color(hex: "#2F76BC"))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(12)
                } else {
                    Text("Not signed in")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                }
            }
        }
    }
    
    private var infoLegalSection: some View {
        settingsSection(title: "Info & legal") {
            settingsRow(icon: "messageBlue", title: "Contact us")
            settingsRow(icon: "fileBlue", title: "Privacy Policy")
            settingsRow(icon: "filesBlue", title: "Usage Policy")
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
    
    private func settingsRow(icon: String, title: String, trailing: String? = nil) -> some View {
        Button(action: {}) {
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

private let notificationsAlertDividerHeight: CGFloat = 0.8
private let notificationsAlertDividerColor = Color(hex: "#333334")

struct AllowNotificationsAlertView: View {
    let onCancel: () -> Void
    let onAllow: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture(perform: onCancel)
            
            VStack(spacing: 0) {
                Text("Allow notifications?")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
                    .padding(.bottom, 8)
                
                Text("This app will be able to send you")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
                Text("messages in your notification center")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 20)
                
                Rectangle()
                    .fill(notificationsAlertDividerColor)
                    .frame(height: notificationsAlertDividerHeight)
                
                HStack(spacing: 0) {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(hex: "#0C4CD6"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .buttonStyle(.plain)
                    
                    Rectangle()
                        .fill(notificationsAlertDividerColor)
                        .frame(width: notificationsAlertDividerHeight, height: 44)
                    
                    Button(action: onAllow) {
                        Text("Allow")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(hex: "#0C4CD6"))
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
}
