//
//  EffectsListView.swift
//  Sora
//

import SwiftUI

struct EffectsListView: View {
    let onBack: () -> Void
    
    private let filterTitles = ["Hot", "Category 1", "Category 2", "Category 3", "Category 4", "Category 5"]
    @State private var selectedFilterIndex: Int = 0
    @State private var showEffectPreview = false
    
    private let gradientColors = [
        Color(hex: "#6CABE9"),
        Color(hex: "#2F76BC")
    ]
    
    var body: some View {
        ZStack {
            Color(hex: "#0D0D0F")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Nav bar: chevronLeft, заголовок по центру, кнопка 1000 + sparkles
                navbar
                
                // Вертикальные кнопки: Hot и 5 Category
                filterButtons
                
                // Двухколоночная вертикальная коллекция effectCard
                effectsGrid
            }
        }
        .fullScreenCover(isPresented: $showEffectPreview) {
            EffectPreviewView(onBack: { showEffectPreview = false })
        }
    }
    
    private var navbar: some View {
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
                .background(Color(hex: "#2B2D30"))
                .cornerRadius(12)
                
                Spacer()
                
                Button(action: {}) {
                    HStack(spacing: 6) {
                        Text("1000")
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
                    .background(Color(hex: "#1F2022"))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            
            Text("Effects")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
        }
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    private var filterButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(filterTitles.enumerated()), id: \.offset) { index, title in
                    Button(action: { selectedFilterIndex = index }) {
                        Text(title)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    .background(
                        selectedFilterIndex == index
                            ? LinearGradient(
                                gradient: Gradient(colors: gradientColors),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "#2B2D30"), Color(hex: "#2B2D30")]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    )
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 16)
    }
    
    private var effectsGrid: some View {
        GeometryReader { geometry in
            let horizontalPadding: CGFloat = 20
            let spacing: CGFloat = 12
            let contentWidth = geometry.size.width - horizontalPadding * 2
            let cellWidth = (contentWidth - spacing) / 2
            let cellHeight = cellWidth * 1.4
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: [
                    GridItem(.fixed(cellWidth), spacing: spacing),
                    GridItem(.fixed(cellWidth), spacing: spacing)
                ], spacing: spacing) {
                    ForEach(0..<12, id: \.self) { _ in
                        Button(action: { showEffectPreview = true }) {
                            ZStack(alignment: .bottomLeading) {
                                Image("effectCard")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: cellWidth, height: cellHeight)
                                Text("Name")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.leading, 20)
                                    .padding(.bottom, 10)
                            }
                            .frame(width: cellWidth, height: cellHeight)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(width: contentWidth)
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, 40)
            }
        }
        .frame(maxHeight: .infinity)
    }
}

#Preview {
    EffectsListView(onBack: {})
}
