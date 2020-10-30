//
//  Extensions.swift
//  voxelMap
//
//  Created by Ferdinand Lösch on 09/12/2019.
//  Copyright © 2019 Ferdinand Lösch. All rights reserved.
//

import Foundation
import UIKit
import ARKit
extension CGPoint {
    var xD: Double { return Double(x) }
    var yD: Double { return Double(y) }
    var xI: Int { return Int(x) }
    var yI: Int { return Int(y) }
}

extension CGSize {
    var heightI: Int { return Int(height) }
    var widthI: Int { return Int(width) }
}

@available(iOS 13.4, *)
extension ARMeshGeometry {
    func vertex(at index: UInt32) -> (Float, Float, Float) {
        assert(vertices.format == MTLVertexFormat.float3, "Expected three floats (twelve bytes) per vertex.")
        let vertexPointer = vertices.buffer.contents().advanced(by: vertices.offset + (vertices.stride * Int(index)))
        let vertex = vertexPointer.assumingMemoryBound(to: (Float, Float, Float).self).pointee
        return vertex
    }
}
extension simd_float4x4 {
    var position: SIMD3<Float> {
        return SIMD3<Float>(columns.3.x, columns.3.y, columns.3.z)
    }
}
