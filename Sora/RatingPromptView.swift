//
//  RatingPromptView.swift
//  Sora
//

import SwiftUI
import StoreKit

struct RatingPromptView: View {
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "#0A0A0A")
                .ignoresSafeArea()

            // Кнопка закрытия — как в PaywallView (правый верхний угол)
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        RatingPromptService.shared.dismissPrompt()
                        onDismiss()
                    }) {
                        Image("closeBlue")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 10)
                    .padding(.trailing, 15)
                }
                Spacer()
            }

            VStack(spacing: 24) {
                Image("previewImage")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 310, maxHeight: 240)
                VStack(spacing: 5) {
                    Text("Do you like our app?")
                        .font(.system(size: 23, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Please rate our app so we can improve it for\nyou and make it even cooler")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                HStack(spacing: 12) {
                    Button(action: {
                        if let url = URL(string: "https://forms.gle/NPFjqanjYhaenH7J8") {
                            UIApplication.shared.open(url)
                        }
                        RatingPromptService.shared.dismissPrompt()
                        onDismiss()
                    }) {
                        Text("No")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(Color(hex: "#2F76BC"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 55)
                            .background(Color(hex: "#111A24"))
                            .cornerRadius(29)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        if let url = URL(string: PolicyURL.appstoreLink) {
                            UIApplication.shared.open(url)
                        }
                        RatingPromptService.shared.markRated()
                        onDismiss()
                    }) {
                        Text("Yes")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 55)
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
                            .cornerRadius(29)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8)
            }
            .padding(.horizontal, 24)
        }
    }
}
