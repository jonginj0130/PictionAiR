//
//  NodeManager.swift
//  PictionAiR
//
//  Created by Rahul Narayanan on 8/31/23.
//

import SwiftUI

import SceneKit

class NodeManager {
    var defaultSphereRadius: CGFloat
    var penColor : UIColor
    init(penColor: UIColor, defaultSphereRadius : CGFloat) {
        self.penColor = penColor
        self.defaultSphereRadius = defaultSphereRadius
    }
    
    func sphereNode(_ color: UIColor, _ radius: CGFloat) -> SCNNode {
        createSphereNode(pColor: color, sRadius: radius)
    }
    
    // MARK: - Private
    
    private func createSphereNode(pColor: UIColor, sRadius: CGFloat) -> SCNNode {
        let sphere = SCNSphere(radius: sRadius)
        sphere.firstMaterial?.diffuse.contents = pColor
        sphere.firstMaterial?.lightingModel = .constant
        let node = SCNNode(geometry: sphere)
        return node
    }
}
