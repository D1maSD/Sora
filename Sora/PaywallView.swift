//
//  PaywallView.swift
//  Sora
//
//  Экран пейвола: фон paywallBack, два плана (Annual/Weekly), Cancel Anytime, кнопка Continue, ссылки.
//

import SwiftUI

struct PaywallView: View {
    var onDismiss: (() -> Void)? = nil
    var onContinue: (() -> Void)? = nil
    var onPrivacyPolicy: (() -> Void)? = nil
    var onRestorePurchases: (() -> Void)? = nil
    var onTermsOfUse: (() -> Void)? = nil
    
    /// true = выбран Annual (верхний), false = выбран Weekly (нижний)
    @State private var isAnnualSelected = true
    
    private let blueGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(hex: "#6CABE9"),
            Color(hex: "#2F76BC")
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    var body: some View {
        ZStack {
            // Фон на весь экран
            Image("paywallBack")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            // Контент на полную ширину, без смещения
            VStack {
                Spacer()
                
                // Два плана подписки (отступ 30 по горизонтали)
                VStack(spacing: 12) {
                        Button(action: { isAnnualSelected = true }) {
                            ZStack(alignment: .leading) {
                                Image(isAnnualSelected ? "firstOn" : "firstOff")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 72)
                                    .clipped()
                                    .cornerRadius(14)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Just $29.99 / Annual")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text("Auto renewable. Cancel anytime.")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(.white.opacity(0.8))
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
                                    .frame(height: 72)
                                    .clipped()
                                    .cornerRadius(14)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Just $29.99 / Weekly")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text("Auto renewable. Cancel anytime.")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .padding(.leading, 52)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 16)
                    
                    // clockArrow и Cancel Anytime в одном HStack по центру
                    HStack(spacing: 8) {
                        Image("clockArrow")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .foregroundColor(.white.opacity(0.8))
                        Text("Cancel Anytime")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.bottom, 16)
                    
                    // Кнопка Continue с синим градиентом (как Save)
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
                    .padding(.bottom, 24)
                    
                    // Три ссылки внизу
                    HStack {
                        Button(action: { onPrivacyPolicy?() }) {
                            Text("Privacy Policy")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button(action: { onRestorePurchases?() }) {
                            Text("Restore Purchases")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                        Button(action: { onTermsOfUse?() }) {
                            Text("Terms of Use")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
                .frame(maxWidth: .infinity)
            }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        }
        
    }


#Preview {
    PaywallView(
        onDismiss: {},
        onContinue: {},
        onPrivacyPolicy: {},
        onRestorePurchases: {},
        onTermsOfUse: {}
    )
}
