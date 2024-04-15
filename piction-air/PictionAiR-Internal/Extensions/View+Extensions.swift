//
//  View+Extensions.swift
//  PictionAiR-Internal
//
//  Created by Rahul Narayanan on 11/13/23.
//

import SwiftUI

struct GlassButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.ultraThickMaterial)
            .bold()
            .padding(8)
            .background(.ultraThinMaterial)
            .cornerRadius(8.0)
            .scaleEffect(configuration.isPressed ? 0.8 : 1)
            .animation(.spring(response: 2.5), value: configuration.isPressed)
    }
}

extension ButtonStyle {
    static var glassButton: any ButtonStyle {
        return GlassButton()
    }
}
