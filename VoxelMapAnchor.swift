//
//  VoxelMapAnchor.swift
//  ARNavigationKit
//
//  Created by Ferdinand Lösch on 08/02/2020.
//

import ARKit

/// - Tag: SnapshotAnchor
public class VoxelMapAnchor: ARAnchor {
    public let map: Data

    public init(map: Data) {
        self.map = map
        super.init(name: "VoxelMap", transform: float4x4())
    }

    public required init(anchor: ARAnchor) {
        map = (anchor as! VoxelMapAnchor).map
        super.init(anchor: anchor)
    }

    override public class var supportsSecureCoding: Bool {
        return true
    }

    public required init?(coder aDecoder: NSCoder) {
        if let snapshot = aDecoder.decodeObject(forKey: "VoxelMap") as? Data {
            map = snapshot
        } else {
            return nil
        }

        super.init(coder: aDecoder)
    }

    public override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(map, forKey: "VoxelMap")
    }
}
