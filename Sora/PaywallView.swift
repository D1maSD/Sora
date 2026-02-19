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
            
            // Контент: в GeometryReader, чтобы не сдвигаться (geo = область с учётом safe area)
            GeometryReader { geo in
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
                                    Text("Just $29.99 / Annual")
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
                                    Text("Just $29.99 / Weekly")
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
                        Button(action: { onPrivacyPolicy?() }) {
                            Text("Privacy Policy")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button(action: { onRestorePurchases?() }) {
                            Text("Restore Purchases")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                        Button(action: { onTermsOfUse?() }) {
                            Text("Terms of Use")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 52)
                }
                .frame(width: geo.size.width)
            }
        }
        .clipped()
        .ignoresSafeArea(.all)
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
