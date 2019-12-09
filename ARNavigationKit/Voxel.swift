//
//  Voxel.swift
//  voxelMap
//
//  Created by Ferdinand Lösch on 21/10/2019.
//  Copyright © 2019 Ferdinand Lösch. All rights reserved.
//

import Foundation
import simd

class Voxel: Hashable, Codable {
    var Position: vector_float3
    var density: Int
    var scale: vector_float3

    init(vector: vector_float3, scale: vector_float3, density: Int) {
        Position = vector
        self.density = density
        self.scale = scale
    }

    func hash(into hasher: inout Hasher) {
        let hash = (Int(Position.x * scale.x) * 499) + (Int(Position.y * scale.y) * 937) + (Int(Position.z * scale.z) * 139)
        hasher.combine(hash)
    }

    static func == (lhs: Voxel, rhs: Voxel) -> Bool {
        return vector_int3(lhs.Position * lhs.scale) == vector_int3(rhs.Position * rhs.scale)
    }
}
