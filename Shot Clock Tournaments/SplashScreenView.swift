//
//  SplashScreen.swift
//  Shot Clock Tournaments
//
//  Created by Owner on 08/04/2025.
//

import Foundation
import SwiftUI

struct SplashScreenView: View {
    
    let layoutProperties:LayoutProperties
    @StateObject var networkMonitor = NetworkMonitor()
    @State private var opacity = 0.0
    @State var backgroundColors = generateRandomColorsFromPool()
    
    var body: some View {
        ZStack {
            
            backgroundMesh(sixColors: backgroundColors)
                .ignoresSafeArea()
            
            GeometryReader {container in
                let imageDiameter:CGFloat = min(layoutProperties.width*0.75, layoutProperties.height*0.75)
                VStack {
                    Image("logo no bg")
                        .resizable()
                        .frame(width: imageDiameter, height: imageDiameter, alignment: .center)
                        .position(x: container.size.width/2.0, y: container.size.height/2)
                        .opacity(opacity)
                        .onAppear {
                            withAnimation(.easeIn(duration: 1)) {
                                self.opacity = 1.00
                            }
                        }
                    HStack {
                        Text("Loading")
                        ProgressView()
                            .padding()
                            .tint(.white)
                        if !networkMonitor.isConnected {Text("Check Network").foregroundStyle(.red)}
                    }
                    .ignoresSafeArea()
                    Spacer()
                }
            }
        }
    }
    
}
