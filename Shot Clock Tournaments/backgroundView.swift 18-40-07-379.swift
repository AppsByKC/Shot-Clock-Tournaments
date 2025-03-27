//
//  backgroundView.swift
//  
//
//  Created by Owner on 14/04/2025.
//

import Foundation
import SwiftUI

func backgroundMesh(sixColors: [Color]) -> MeshGradient {
    
    return MeshGradient(width: 3, height: 4, points: [
        .init(0, 0), .init(0.5, 0), .init(1, 0),
        .init(0, 0.2), .init(0.5, 0.2), .init(1, 0.2),
        .init(0, 0.7), .init(0.7, 0.7), .init(1, 0.7),
        .init(0, 1), .init(0.5, 1), .init(1, 1)
    ], colors: [
        .black, .black, .black,
        .black, .black, .black,
        sixColors[0], sixColors[1],sixColors[2],
        sixColors[3],sixColors[4],sixColors[5]
    ])
    
}

func generateRandomColorsFromPool(count: Int = 6) -> [Color] {
    let colorPool: [Color] = [.cyan, .mint, .teal]
    var randomColors: [Color] = []
    
    for _ in 0..<count {
        if let randomColor = colorPool.randomElement() {
            randomColors.append(randomColor)
        }
    }
    
    return randomColors
}
