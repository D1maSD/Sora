//
//  SettingsView.swift
//  Sora
//

import SwiftUI

struct SettingsView: View {
    let onBack: () -> Void
    
    @State private var notificationsEnabled = false
    
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
            .padding(.horizontal, 20)
            
            Button(action: {}) {
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
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(hex: "#2F76BC"))
                .cornerRadius(20)
            }
            .padding(.trailing, 20)
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
                .padding(.horizontal, 20)
            
            VStack(spacing: 8) {
                content()
            }
            .background(Color(hex: "#0C151F"))
            .cornerRadius(12)
            .padding(.horizontal, 40)
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
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
    
    private func settingsRowWithToggle(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            if icon == "bell" {
                Image(systemName: "bell")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "#2F76BC"))
                    .frame(width: 24, height: 24)
            } else {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
            
            Text(title)
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color(hex: "#2F76BC"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
    
    private var footer: some View {
        Text("App Version: 1.0.0")
            .font(.system(size: 13, weight: .regular))
            .foregroundColor(.white.opacity(0.5))
            .padding(.bottom, 34)
    }
}

#Preview {
    SettingsView(onBack: {})
}
