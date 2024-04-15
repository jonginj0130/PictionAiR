//
//  SCNView+Extensions.swift
//  PictionAiR-Internal
//
//  Created by Sankaet Cheemalamarri on 2/3/24.
//

import SceneKit

extension SCNView {
    // Takes the coordinates of the 2D point and converts it to a vector in the real world
    func direction(for point: CGPoint) -> SCNVector3 {
        let farPoint  = self.unprojectPoint(SCNVector3Make(Float(point.x), Float(point.y), 1))
        let nearPoint = self.unprojectPoint(SCNVector3Make(Float(point.x), Float(point.y), 0))

        return SCNVector3Make(farPoint.x - nearPoint.x, farPoint.y - nearPoint.y, farPoint.z - nearPoint.z)
    }
}
