//
//  SplashView.swift
//  Sora
//
//  Created by Dima Melnik on 2/12/26.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            Image("splashLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
        }
    }
}

#Preview {
    SplashView()
}
