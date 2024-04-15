//
//  SplashScreen.swift
//  PictionAiR
//
//  Created by Rahul Narayanan on 11/16/23.
//

import SwiftUI

fileprivate struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))

        return path
    }
}

struct SplashScreen: View {
    @State private var didFinishAnimation = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                let shapeSize = geo.size.width / 5
                
                if didFinishAnimation {
                    // Top Square
                    RoundedRectangle(cornerRadius: 0)
                        .frame(width: shapeSize, height: shapeSize)
                        .rotationEffect(.degrees(-20))
                        .animation(.easeOut(duration: 0.5).delay(0.2), value: didFinishAnimation)
                        .foregroundStyle(Color(uiColor: UIColor("#F4E185")))
                        .offset(y: -geo.size.height / 3.5)
                        .shadow(radius: 20)
                        .transition(.scale(scale: 0.8).combined(with: .opacity).animation(.spring().delay(1)))

                    // Red Triangle
                    Triangle()
                        .frame(width: shapeSize, height: shapeSize)
                        .animation(.easeOut(duration: 0.5).delay(0.5), value: didFinishAnimation)
                        .foregroundStyle(.red)
                        .rotationEffect(.degrees(15))
                        .offset(x: -geo.size.width / 4, y: -geo.size.height / 3.5 + 100)
                        .shadow(radius: 20)
                        .transition(.scale(scale: 0.8).combined(with: .opacity).animation(.spring().delay(0.8)))
                    
                    // Blue Triangle
                    Triangle()
                        .frame(width: shapeSize, height: shapeSize)
                        .animation(.easeOut(duration: 0.5).delay(0.5), value: didFinishAnimation)
                        .foregroundStyle(.blue)
                        .rotationEffect(.degrees(-30))
                        .offset(x: geo.size.width / 4, y: -geo.size.height / 3.5 + 100)
                        .shadow(radius: 20)
                        .transition(.scale(scale: 0.8).combined(with: .opacity).animation(.spring().delay(1.2)))
                                    
                    // Green Square
                    RoundedRectangle(cornerRadius: 0)
                        .frame(width: shapeSize, height: shapeSize)
                        .animation(.easeOut(duration: 0.5).delay(1), value: didFinishAnimation)
                        .foregroundStyle(greenColor)
                        .rotationEffect(.degrees(30))
                        .offset(x: geo.size.width / 10, y: 50)
                        .shadow(radius: 20)
                        .transition(.scale(scale: 0.8).combined(with: .opacity).animation(.spring().delay(1.5)))

                    // Orange Circle
                    Circle()
                        .frame(width: shapeSize, height: shapeSize)
                        .offset(x: -geo.size.width / 4, y: 50)
                        .animation(.easeOut(duration: 0.5).delay(0.75), value: didFinishAnimation)
                        .foregroundStyle(.orange)
                        .shadow(radius: 20)
                        .transition(.scale(scale: 0.8).combined(with: .opacity).animation(.spring().delay(0.5)))
                    
                    // Purple Circle
                    Circle()
                        .frame(width: shapeSize, height: shapeSize)
                        .animation(.easeOut(duration: 0.5).delay(0.9), value: didFinishAnimation)
                        .foregroundStyle(purpleColor)
                        .shadow(radius: 10)
                        .offset(x: -geo.size.width / 3.5, y: geo.size.height / 3.5)
                        .transition(.scale(scale: 0.8).combined(with: .opacity).animation(.spring().delay(0.3)))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.linearGradient(colors: [Color(uiColor: .systemBackground), .gray.opacity(0.5)], startPoint: .top, endPoint: .bottom))
        }
        .blur(radius: didFinishAnimation ? 10.0 : 0.0)
        .overlay {
            if didFinishAnimation {
                LaunchView()
            }
        }
        .animation(.spring().delay(2), value: didFinishAnimation)
        .onAppear {
            didFinishAnimation = true
        }
    }
    
    // MARK: - Drawing Constants
    private let purpleColor = Color(uiColor: UIColor("#CD9BEB"))
    private let greenColor = Color(uiColor: UIColor("#8CB369"))
}

#Preview {
    SplashScreen()
}
