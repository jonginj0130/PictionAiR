//
//  ARSCNView+Extensions1.swift
//  PictionAiR-Internal
//
//  Created by Sankaet Cheemalamarri on 2/3/24.
//

import ARKit

extension ARSCNView {
    var cameraPosition: SCNVector3? {
        guard let lastFrame = session.currentFrame else {
            return nil
        }
        let position = lastFrame.camera.transform * SIMD4(x: 0, y: 0, z: 0, w: 1)
        let camera: SCNVector3 = SCNVector3(position.x, position.y, position.z)

        return camera
    }
    
    func position(of point: CGPoint, distanceFromCamera distance: Float = 0.2) -> SCNVector3? {
        guard let cameraPosition = self.cameraPosition else {
            return nil
        }
        
        let directionOfPoint = self.direction(for: point).normalized()
        return (directionOfPoint * distance) + cameraPosition
    }
    
    static func getPositionsOnLineBetween(point1: SCNVector3,
                                          and point2: SCNVector3,
                                          spacing: Float) -> [SCNVector3] {
        var positions: [SCNVector3] = []
        // Calculate the distance between previous point and current point
        let distance = point1.distance(vector: point2)
        let numberOfCirclesToCreate = Int(distance / spacing)

        // Begin by creating a vector BA by subtracting A from B (A = previousPoint, B = currentPoint)
        let vectorBA = point2 - point1
        // Normalize vector BA by dividng it by it's length
        let vectorBANormalized = vectorBA.normalized()
        // This new vector can now be scaled and added to A to find the point at the specified distance
        for i in 0...((numberOfCirclesToCreate > 1) ? (numberOfCirclesToCreate - 1) : numberOfCirclesToCreate) {
            let position = point1 + (vectorBANormalized * (Float(i) * spacing))
            positions.append(position)
        }
        return positions
    }
}
