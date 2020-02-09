//
//  VoxelMap.swift
//  voxelMap
//
//  Created by Ferdinand Lösch on 21/10/2019.
//  Copyright © 2019 Ferdinand Lösch. All rights reserved.
//

import ARKit
import Foundation
import GameplayKit
import simd
import UIKit

/// Description
public protocol ARNavigationKitDelegate: class {
    /// Description
    /// - Parameter View: View description
    func updateDebugView(_ View: UIView)
    /// Description
    /// - Parameter path: path description
    func getPathupdate(_ path: [vector_float3]?)
}

public enum filters: Int {
    case none = 0
    case ruste = 1
}

/// Description
public class ARNavigationKit {
    private let queue = DispatchQueue(label: "Voxel")
    private var voxelSet = Set<Voxel>()
    private var gridSize: Float!
    private var groundHeight: Float?
    private var xMax: Float? // Max width.
    private var xMin: Float? // Min width.
    private var zMax: Float? // Max length.
    private var zMin: Float? // Min length.
    /// record of voxels which have already been added to the SCNScene.
    private var alreadyRenderedVoxels = Set<Voxel>()

    /// set minimum noise level to be considered voxel.
    public var noiseLevel = 5
    
    /// set filter option for map  processing.
    public var filter: filters = .none

    /// Delegate  required for callbacks.
    public weak var arNavigationKitDelegate: ARNavigationKitDelegate?

    ///  Sets the minimum resolution of a Voxel in metres cubed as well as the grid size used.
    /// - Parameter VoxelGridCellSize: grid cell size  in metres.
    public init(VoxelGridCellSize: Float) {
        gridSize = 1 / VoxelGridCellSize
    }
    /// Default initialiser.
    public init() {
        gridSize = 50
    }
    
    
    public init(data: Data,_ VoxelGridCellSize: Float) {
        gridSize = VoxelGridCellSize
        lodeMapFromData(data)
    }

    /// method to add individual vector points into the voxle map.
    /// - Parameter vector: X,Y,Z vector in metres
    public func addVoxel(_ vector: vector_float3) {
        queue.async {
            let voxel = Voxel(vector: self.normaliseVector(vector), scale: vector_float3(self.gridSize, self.gridSize, self.gridSize), density: 1)
            if self.voxelSet.contains(voxel) {
                guard var newVoxel = self.voxelSet.remove(voxel) else { return }
                newVoxel.density += 1
                self.voxelSet.insert(newVoxel)
            } else {
                self.voxelSet.insert(voxel)
            }
        }
    }

    /// add collection of vectors into the Voxel map.
    /// use this method instead of calling at voxel repeatedly.
    /// - Parameter vectors: mutable array of vector_float3
    public func addVoxels(_ vectors: [vector_float3]) {
        vectors.forEach { addVoxel($0) }
    }

    /// method to be called every time a new  horizontal plane is detected.
    /// - Parameter plane: ARPlaneAnchor of the horizontal plane
    public func updateGroundPlane(_ plane: ARPlaneAnchor) {
        queue.async {
            self.groundHeight = min(plane.transform.columns.3.y, self.groundHeight ?? Float(Int.max))
        }
    }

    /// Callback method to receive rendered SCNNode of the current point cloud.
    public func getPointCloudNode(completion: @escaping (SCNNode) -> Void) {
        queue.async {
            let points = self.voxelSet.map { SIMD3<Float>($0.Position) }

            let featurePointsGeometry = self.pointCloudGeometry(for: points)

            let featurePointsNode = SCNNode(geometry: featurePointsGeometry)

            completion(featurePointsNode)
        }
    }

    /// method to request a path calculation from a starting point and endpoint within current range of the map.
    /// use the ARNavigationKitDelegate (getPathupdate) delegate method to receive the path update.
    /// - Parameters:
    ///   - start: start description
    ///   - end: end description
    public func getPath(start: SCNVector3, end: SCNVector3) {
        queue.async {
            self.setMinMax()
            guard let map = self.makeGraph() else { return }
            guard let xmax = self.xMax else { return }
            guard let zmax = self.zMax else { return }
            let _start = self.indaxToCGPoint(start)
            let _end = self.indaxToCGPoint(end)
            let aStar = AStar(map: map, start: _start, diag: true)
            let path = aStar.findPathTo(end: _end)?.map { (n) -> vector_float3 in

                let r = Float(n.position.xD)
                let c = Float(n.position.yD)
                let x = xmax - ((r - 1) / self.gridSize)
                let z = zmax - ((c - 1) / self.gridSize)

                return vector_float3(x: x, y: (self.groundHeight ?? -1) + 0.4, z: z)
            }

            DispatchQueue.main.async {
                self.arNavigationKitDelegate?.getPathupdate(path)
            }
        }
    }

    /// this method returns rendered note of the current Voxel map
    /// - Parameter redrawAll: option if only new Voxels should be returned or if a whole new Voxel map should be rendered.
    public func getVoxelMap(redrawAll: Bool, completion: @escaping ([SCNNode]) -> Void) {
        queue.async {
            var voxelNodes = [SCNNode]()
            let voxels = self.voxelSet
            for voxel in voxels {
                if voxel.density < self.noiseLevel { continue }
                if !redrawAll, self.alreadyRenderedVoxels.contains(voxel) { continue } // To increase rendering efficiency.
                let position = voxel.Position
                let box = SCNBox(width: CGFloat(1 / voxel.scale.x), height: CGFloat(1 / voxel.scale.y), length: CGFloat(1 / voxel.scale.z), chamferRadius: 0)
                box.firstMaterial?.diffuse.contents = position.y < (self.groundHeight ?? -10) + 0.3 ? UIColor.green :
                    UIColor(red: CGFloat(abs(position.y * 800)) / 255, green: 0.2, blue: 0.2, alpha: 1)
                let voxelNode = SCNNode(geometry: box)
                voxelNode.position = SCNVector3(position)
                voxelNodes.append(voxelNode)
                self.alreadyRenderedVoxels.insert(voxel)
            }
            completion(voxelNodes)
        }
    }

    /// Description
    public func getObstacleGraphDebug() {
        queue.async {
            guard let matrix = self.makeGraph() else { return }
            self.arNavigationKitDelegate?.updateDebugView(MapVisualisation(map: matrix))
        }
    }

    /// Description
    /// - Parameters:
    ///   - start: start description
    ///   - end: end description
    public func getObstacleGraphAndPathDebug(start: SCNVector3, end: SCNVector3) {
        queue.async {
            self.setMinMax()
            guard var map = self.makeGraph() else { return }
            let _start = self.indaxToCGPoint(start)
            let _end = self.indaxToCGPoint(end)

            let aStar = AStar(map: map, start: _start, diag: false)
            guard let path = aStar.findPathTo(end: _end) else { return }
            path.forEach { map[$0.position.xI][$0.position.yI] = map[$0.position.xI][$0.position.yI] == 1 ? 4 : 3 }
            DispatchQueue.main.async {
                self.arNavigationKitDelegate?.updateDebugView(MapVisualisation(map: map))
            }
        }
    }
    
    
    public func getMapData() -> Data {
        let voxelArray: [Voxel] = voxelSet.map({$0})
        let data = Data(buffer: UnsafeBufferPointer(start: voxelArray, count: voxelArray.count))
        return data
    }
    
    public func lodeMapFromData(_ data: Data){
        queue.async {
            let dataStride = data.count
            let voxelArray = data.withUnsafeBytes {
                Array(UnsafeBufferPointer<Voxel>(start: $0, count: dataStride/MemoryLayout<Voxel>.stride))
            }
            voxelArray.forEach({self.voxelSet.insert($0)})
        }
    }

    /// Description
    /// - Parameter vector: vector description
    private func indaxToCGPoint(_ vector: SCNVector3) -> CGPoint {
        guard let xmax = xMax else { return CGPoint() }
        guard let zmax = zMax else { return CGPoint() }
        let x = Int(((xmax - vector.x) * gridSize) + 1)
        let y = Int(((zmax - vector.z) * gridSize) + 1)
        return CGPoint(x: x, y: y)
    }

    private func setMinMax() {
        let voxels = voxelSet
        voxels.forEach { voxel in
            xMax = max(voxel.Position.x, xMax ?? -100_000)
            xMin = min(voxel.Position.x, xMin ?? 100_000)
            zMax = max(voxel.Position.z, zMax ?? -100_000)
            zMin = min(voxel.Position.z, zMin ?? 100_000)
        }
    }

    private func makeGraph() -> [[Int]]? {
        setMinMax()
        //let voxels = self.voxelSet
        guard let xmax = xMax else { return nil }
        guard let xmin = xMin else { return nil }
        guard let zmax = zMax else { return nil }
        guard let zmin = zMin else { return nil }

        let rows = Int((xmax - xmin) * gridSize) + 10 // x
        let columns = Int((zmax - zmin) * gridSize) + 10 // y

        var graph = Array(repeating: Array(repeating: 2, count: columns + 2), count: rows + 2)
        
        let voxels: [Voxel] = self.voxelSet.map({$0})
        for voxel in voxels {
            let row = Int((xmax - voxel.Position.x) * gridSize) + 1
            let column = Int((zmax - voxel.Position.z) * gridSize) + 1
            if voxel.Position.y < (groundHeight ?? -10) + 0.3 {
                graph[row][column] = 0
            } else if voxel.density > noiseLevel {
                graph[row][column] = 1
            }
        }
        
        switch filter {
            case .ruste:
                return Mapfilters.mapRoasting(graph, kernel: CGSize(width: 2, height: 2))
            case .none:
                return graph
        }
    }

    /// Generate a geometry point cloud out of current Vertices.
    private func pointCloudGeometry(for points: [SIMD3<Float>]) -> SCNGeometry? {
        guard !points.isEmpty else { return nil }

        let stride = MemoryLayout<SIMD3<Float>>.size
        let pointData = Data(bytes: points, count: stride * points.count)

        let source = SCNGeometrySource(data: pointData,
                                       semantic: SCNGeometrySource.Semantic.vertex,
                                       vectorCount: points.count,
                                       usesFloatComponents: true,
                                       componentsPerVector: 3,
                                       bytesPerComponent: MemoryLayout<Float>.size,
                                       dataOffset: 0,
                                       dataStride: stride)

        let pointSize: CGFloat = 10
        let element = SCNGeometryElement(data: nil, primitiveType: .point, primitiveCount: points.count, bytesPerIndex: 0)
        element.pointSize = 0.01
        element.minimumPointScreenSpaceRadius = pointSize * 2
        element.maximumPointScreenSpaceRadius = pointSize / 2

        let pointsGeometry = SCNGeometry(sources: [source], elements: [element])

        let material = SCNMaterial()
        material.diffuse.contents = getRandomColoer()
        material.isDoubleSided = true
        material.locksAmbientWithDiffuse = true

        return pointsGeometry
    }

    private func normaliseVector(_ vector: vector_float3) -> vector_float3 {
        return vector_float3(vector_int3(vector * gridSize)) / gridSize
    }

    private func getRandomColoer() -> UIColor {
        switch Int.random(in: 0 ... 2) {
        case 0:
            return UIColor.gray
        case 1:
            return UIColor.darkGray
        case 2:
            return UIColor.lightGray
        default:
            return UIColor.orange
        }
    }
}
