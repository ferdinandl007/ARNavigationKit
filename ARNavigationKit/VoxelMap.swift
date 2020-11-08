//
//  VoxelMap.swift
//  voxelMap
//
//  Created by Ferdinand Lösch on 21/10/2019.
//  Copyright © 2019 Ferdinand Lösch. All rights reserved.
//

import ARKit
import Foundation
import simd
import UIKit
import RealityKit

public protocol ARNavigationKitDelegate: class {
    ///   Returns a UIView object of the current navigation map once computation is complete
    /// - Parameter View: navigation map
    func updateDebugView(_ View: UIView)
    ///   Retrieves  path
    /// - Parameter path: path.
    func getPathupdate(_ path: [vector_float3]?)
}
/// Map noise reduction filters.
public enum filters: Int {
    case none = 0
    case ruste = 1
    case removeSingle = 2
}

/**
 A configuration for running world tracking.
 
 @discussion World tracking provides 6 degrees of freedom tracking of the device.
 By finding feature points in the scene, world tracking enables performing hit-tests against the frame.
 Tracking can no longer be resumed once the session is paused.
 */
public class ARNavigationKit {
    private let queue = DispatchQueue(label: "com.ferdinand.ARNavigationKit", qos: .userInitiated)
    private var voxelSet = Set<Voxel>()
    private var gridSize: Float!
    private var groundHeight: Float?
    private var groundHeightOffSet: Float
    private var xMax: Float? // Max width.
    private var xMin: Float? // Min width.
    private var zMax: Float? // Max length.
    private var zMin: Float? // Min length.
    private let semaphore = DispatchSemaphore(value: 1)
    /// A record of voxels which have already been added to the SCNScene.
    private var alreadyRenderedVoxels = Set<Voxel>()

    /// Set minimum noise level to be considered voxel.
    public var noiseLevel = 12
    
    /// Sets the Buffer between the nearest obstacles in the path.
    public var obstacleBufferForPath = 5
    
    /// Set filter option for map  processing.
    public var filter: filters = .none
    
    public var allowDiagonalMovement = true
    
    public var allowBlockMoveWithCost: Double?

    /// Delegate  required for callbacks.
    public weak var arNavigationKitDelegate: ARNavigationKitDelegate?
 
    ///  Sets the minimum resolution of a Voxel in metres cubed as well as the grid size used.
    /// - Parameter VoxelGridCellSize: grid cell size  in metres.
    public init(VoxelGridCellSize: Float) {
        gridSize = 1 / VoxelGridCellSize
        groundHeightOffSet = VoxelGridCellSize * 2
        
    }
    
    /// Default initialiser.
    public init() {
        gridSize = 10
        groundHeightOffSet =  (1 / gridSize) * 2
    }
    
    /// Use this initialiser when initialising a Voxle map from a data object.
    /// - Parameters:
    ///   - data: Voxle map, data object
    ///   - VoxelGridCellSize: Grid cell size  in metres.
    public init(data: Data,_ VoxelGridCellSize: Float) {
        gridSize = 1 / VoxelGridCellSize
        groundHeightOffSet = VoxelGridCellSize * 2
        lodeMapFromData(data)
    }
    
    ///  Generates a new navigational map from ARMeshAnchors recommended on devices with LIDAR scanner for improved performance.
    ///  Use this method on devices which support LIDAR scanner instead  generating the map  from the point cloud.
    ///  Additionally  it is recommended to set the noiseLevel to 1 when  generating a map from mesh.
    ///  Available form ios 13.4
    /// - Parameters:
    ///   - meshs: [ARMeshAnchor]
    @available(iOS 13.4, *)
    public func generatingMapFromMesh(_ meshs: [ARMeshAnchor]) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.semaphore.wait()
            self.voxelSet = []
            let verticesPositions = meshs.flatMap { ARNavigationKit.vertexToWorldSpace($0) }
            verticesPositions.forEach({self._addVoxel($0)})
            self.semaphore.signal()
        }
    }

    /// Method to add individual feature points into the voxle map.
    /// - Parameter vector: X,Y,Z vector in metres
    public func addVoxel(_ vector: vector_float3) {
        queue.sync { [weak self] in
            guard let self = self else { return }
            self._addVoxel(vector)
        }
    }

    /// add collection of vectors into the Voxel map.
    /// use this method instead of calling at voxel repeatedly.
    /// - Parameter vectors: mutable array of vector_float3
    public func addVoxels(_ vectors: [vector_float3]) {
        vectors.forEach { addVoxel($0) }
    }

    /// Method to be called every time a new  horizontal plane is detected.
    /// - Parameter plane: ARPlaneAnchor of the horizontal plane
    public func updateGroundPlane(_ plane: ARPlaneAnchor) {
        queue.sync { [weak self] in
            guard let self = self else { return }
            self.groundHeight = min(plane.transform.columns.3.y, self.groundHeight ?? Float(Int.max))
        }
    }

    /// Callback method to receive rendered SCNNode of the current point cloud.
    public func getPointCloudNode(completion: @escaping (SCNNode) -> Void) {
        queue.sync { [weak self] in
            guard let self = self else { return }
            let points = self.voxelSet.map { SIMD3<Float>($0.Position) }

            let featurePointsGeometry = self.pointCloudGeometry(for: points)

            let featurePointsNode = SCNNode(geometry: featurePointsGeometry)

            completion(featurePointsNode)
        }
    }

    /// Method to request a path calculation from a starting point and endpoint within current range of the map.
    /// Use the ARNavigationKitDelegate (getPathupdate) delegate method to receive the path update.
    /// - Parameters:
    ///   - start: The starting Vector from where Path planning should begin.
    ///   - end:  The vector of the destination.
    public func getPath(start: SCNVector3, end: SCNVector3) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.semaphore.wait()
            self.setMinMax()
            guard let map = self.makeGraph() else { return }
            guard let xmax = self.xMax else { return }
            guard let zmax = self.zMax else { return }
            let _start = self.vectorToIndex(start)
            let _end = self.vectorToIndex(end)
            let aStar = AStar(map: map,
                              start: _start,
                              diag: self.allowDiagonalMovement,
                              nearestNeighbour: self.obstacleBufferForPath,
                              costForBlockedMoves: self.allowBlockMoveWithCost)
            let path = aStar.findPathTo(end: _end)?.map { (pathNode) -> vector_float3 in
                
                let row = Float(pathNode.position.xD)
                let column = Float(pathNode.position.yD)
                let x = xmax - ((row - 1) / self.gridSize)
                let z = zmax - ((column - 1) / self.gridSize)
                let pathHeight = (self.groundHeight ?? -1) + 0.4
                
                return vector_float3(x: x, y: pathHeight, z: z)
            }

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.arNavigationKitDelegate?.getPathupdate(path)
                self.semaphore.signal()
            }
        }
    }

    /// Converts current Voxle map in to SCNNodes objects.
    /// best used for debugging and finding optimal parameters.
    ///  - Parameter redrawAll: option if only new Voxels should be returned or if a whole new Voxel map should be rendered.
    ///  - Parameter onlyObstacles: option if true will only return Voxle Nodes of obstacles.
    ///  - Parameter completion:  callback  returns SCNNode of Voxles.
    public func getVoxelMap(redrawAll: Bool,onlyObstacles: Bool, completion: @escaping ([SCNNode]) -> Void) {
        queue.sync { [weak self] in
            guard let self = self else { return }
            var voxelNodes = [SCNNode]()
            let voxels = self.voxelSet
            for voxel in voxels {
                if voxel.density < self.noiseLevel  { continue }
                if onlyObstacles && voxel.Position.y < (self.groundHeight ?? -10) + self.groundHeightOffSet + 0.1 { continue }
                if !redrawAll, self.alreadyRenderedVoxels.contains(voxel) { continue } // To increase rendering efficiency.
                let position = voxel.Position
                let box = SCNBox(width: CGFloat(1 / voxel.scale.x), height: CGFloat(1 / voxel.scale.y), length: CGFloat(1 / voxel.scale.z), chamferRadius: 0)
                box.firstMaterial = self.material(isObstacle: position.y < ((self.groundHeight ?? -10) + self.groundHeightOffSet))
                let voxelNode = SCNNode(geometry: box)
                voxelNode.position = SCNVector3(position)
                voxelNode.name = "voxelNode"
                voxelNodes.append(voxelNode)
                self.alreadyRenderedVoxels.insert(voxel)
            }
            completion(voxelNodes)
        }
    }

    /// Requests the current navigational map used for path planning.
    /// Use the ARNavigationKitDelegate (updateDebugView) delegate method to receive the rendered navigational map.
    public func getObstacleGraphDebug() {
        queue.sync { [weak self] in
            guard let matrix = self?.makeGraph() else { return }
            DispatchQueue.main.async {
                self?.arNavigationKitDelegate?.updateDebugView(MapVisualisation(map: matrix))
            }
        }
    }

    /// Requests the current navigational map used for path planning and renders the requested path inside the map for path validation.
    /// Use the ARNavigationKitDelegate (updateDebugView) delegate method to receive the rendered navigational map.
    /// - Parameters:
    ///   - start: The starting Vector from where Path planning should begin.
    ///   - end:  The vector of the destination.
    public func getObstacleGraphAndPathDebug(start: SCNVector3, end: SCNVector3) {
        queue.sync { [weak self] in
            guard let self = self else { return }
            self.setMinMax()
            guard var map = self.makeGraph() else { return }
            let _start = self.vectorToIndex(start)
            let _end = self.vectorToIndex(end)

            let aStar = AStar(map: map,
                              start: _start,
                              diag: self.allowDiagonalMovement,
                              nearestNeighbour: self.obstacleBufferForPath,
                              costForBlockedMoves: self.allowBlockMoveWithCost
            )
            guard let path = aStar.findPathTo(end: _end) else { return }
            path.forEach { map[$0.position.xI][$0.position.yI] = map[$0.position.xI][$0.position.yI] == 1 ? 4 : 3 }
            DispatchQueue.main.async {
                self.arNavigationKitDelegate?.updateDebugView(MapVisualisation(map: map))
            }
        }
    }
    
    
    /// In codes  and records the current state  of the Voxle Map and returns the data object
    /// which can be used for re-initialisation of the map at a later point.
    public func getMapData() -> Data {
        let voxelArray: [Voxel] = voxelSet.map({$0})
        let data = Data(buffer: UnsafeBufferPointer(start: voxelArray, count: voxelArray.count))
        return data
    }
    

    public func lodeMapFromData(_ data: Data){
        queue.async { [weak self] in
            guard let self = self else { return }
            let dataStride = data.count
            let voxelArray = data.withUnsafeBytes {
                Array(UnsafeBufferPointer<Voxel>(start: $0, count: dataStride/MemoryLayout<Voxel>.stride))
            }
            voxelArray.forEach {self.voxelSet.insert($0)}
        }
    }
    
    @available(iOS 13.4, *)
    private static func vertexToWorldSpace(_ mesh: ARMeshAnchor) -> [vector_float3] {
        let geometry = mesh.geometry
        let vertices = geometry.vertices
        var verticesPosition = [vector_float3](repeating: vector_float3(), count: vertices.count)
        for vertexIndex in 0..<vertices.count {
            let vertex = geometry.vertex(at: UInt32(vertexIndex))
            var vertexLocalTransform = matrix_identity_float4x4
            vertexLocalTransform.columns.3 = SIMD4<Float>(x: vertex.0, y: vertex.1, z: vertex.2, w: 1)
            let vertexWorldPosition = vector_float3((mesh.transform * vertexLocalTransform).position)
            verticesPosition[vertexIndex] = vertexWorldPosition
        }
        return verticesPosition
    }

    private func vectorToIndex(_ vector: SCNVector3) -> CGPoint {
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
        guard let xmax = xMax else { return nil }
        guard let xmin = xMin else { return nil }
        guard let zmax = zMax else { return nil }
        guard let zmin = zMin else { return nil }

        let rows = Int((xmax - xmin) * gridSize) + 10 // x
        let columns = Int((zmax - zmin) * gridSize) + 10 // y

        var graph = Array(repeating: Array(repeating: 2, count: columns + 2), count: rows + 2)
        
        let voxels: [Voxel] = self.voxelSet.map {$0}
        
        for voxel in voxels {
            let row = Int((xmax - voxel.Position.x) * gridSize) + 1
            let column = Int((zmax - voxel.Position.z) * gridSize) + 1
            if voxel.Position.y < (groundHeight ?? -10) + groundHeightOffSet {
                graph[row][column] = 0
            } else if voxel.density > noiseLevel {
                graph[row][column] = 1
            }
        }
        
        switch filter {
            case .ruste:
                return Mapfilters.mapRoasting(graph, kernel: CGSize(width: 2, height: 2))
            case .removeSingle:
                return Mapfilters.removeVoxleClustersOfSize(map: graph,size: 2)
            case .none:
                return graph
        }
        
    }
    
    private func _addVoxel(_ vector: vector_float3) {
        let voxel = Voxel(vector: self.normaliseVector(vector), scale: vector_float3(self.gridSize,self.gridSize, self.gridSize), density: 1)
        let check = voxelSet.insert(voxel)
        if check.inserted {
            var newVoxel = check.memberAfterInsert
            newVoxel.density += 1
            self.voxelSet.update(with: newVoxel)
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
        material.diffuse.contents = UIColor.white
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
    
    private func material(isObstacle: Bool) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .blinn
        material.transparencyMode = .dualLayer
        material.fresnelExponent = 1.5
        material.isDoubleSided = true
        material.specular.contents = UIColor(white: 0.6, alpha: 1.0)
        material.diffuse.contents =  isObstacle ? UIColor.green :
        UIColor.red 
        material.shininess = 25
        material.reflective.contents = 0.7// glass won’t look good unless it has something
        return material
    }
    
}


