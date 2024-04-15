//
//  DrawingView.swift
//  PictionAiR
//
//  Created by Rahul Narayanan on 9/2/23.
//

import SwiftUI

struct DrawingView: UIViewControllerRepresentable {
    @Binding var penColor : Color
    @Binding var thickness : CGFloat
    @ObservedObject var arPictionaryGame: ARPictionaryGame
    
    func makeUIViewController(context: Context) -> DrawingViewController {
        let view = DrawingViewController()
        view.nodeManager.penColor = UIColor(penColor)
        view.nodeManager.defaultSphereRadius = thickness
        view.arPictionaryGame = arPictionaryGame
        return view
    }
    
    func updateUIViewController(_ uiViewController: DrawingViewController, context: Context) {
        uiViewController.nodeManager.penColor = UIColor(penColor)
        uiViewController.nodeManager.defaultSphereRadius = thickness
    }
}
