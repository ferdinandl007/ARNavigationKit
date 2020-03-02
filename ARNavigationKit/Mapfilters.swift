//
//  Mapfilters.swift
//  voxelMap
//
//  Created by Ferdinand Lösch on 09/12/2019.
//  Copyright © 2019 Ferdinand Lösch. All rights reserved.
//

import Foundation
import UIKit
class Mapfilters {
    public static func mapRoasting(_ _map: [[Int]], kernel: CGSize) -> [Array<Int>] {
        var map = _map
        if map.count < 1 || map[0].count < 1 { return map }
        if kernel.widthI > map[0].count || kernel.heightI > map.count { return  map }

        for row in 0 ... map.count - kernel.heightI {
            for column in 0 ... map[0].count - kernel.widthI {
                if checkgrid(map: _map, kernel, row, column, isAllBlockt: true) {
                    upadteMap(map: &map, kernel, row, column, mackBlock: false)
                }
            }
        }

        let temp = map
        for row in 0 ... map.count - kernel.heightI {
            for column in 0 ... map[0].count - kernel.widthI {
                if checkgrid(map: temp, kernel, row, column, isAllBlockt: false) {
                    upadteMap(map: &map, kernel, row, column, mackBlock: true)
                }
            }
        }

        return map
    }

    private static func checkgrid(map: [[Int]], _ kernel: CGSize, _ row: Int, _ column: Int, isAllBlockt: Bool) -> Bool {
        var count = kernel.heightI * kernel.widthI

        for kH in row ..< (row + kernel.heightI) {
            for kC in column ..< (column + kernel.widthI) {
                if map[kH][kC] == 1 {
                    count -= 1
                }
            }
        }

        return isAllBlockt ? count != 0 : count < kernel.heightI * kernel.widthI
    }

    private static func upadteMap(map: inout [[Int]], _ kernel: CGSize, _ row: Int, _ column: Int, mackBlock: Bool) {
        for kH in row ... (row + kernel.heightI - 1) {
            for kC in column ... (column + kernel.widthI - 1) {
                if mackBlock {
                    map[kH][kC] = 1
                } else {
                    map[kH][kC] = 0
                }
            }
        }
    }
    
    
    
    public static func removeVoxleClustersOfSize(map: [[Int]],size: Int) -> [Array<Int>] {
        var maps = map
        var count = 0
        var v = Set<[Int]>()
        var vls = [[Int]]()
        func countVoxleCluster(map: [[Int]],x: Int, y: Int) {
            if !isValid(map: map, x, y) || map[x][y] != 1 || v.contains([x,y]){
                return
            }
            count += 1
            v.insert([x,y])
            vls.append([x,y])
            countVoxleCluster(map: map, x: x + 1, y: y)
            countVoxleCluster(map: map, x: x - 1, y: y)
            countVoxleCluster(map: map, x: x, y: y + 1)
            countVoxleCluster(map: map, x: x, y: y - 1)
            countVoxleCluster(map: map, x: x + 1, y: y + 1)
            countVoxleCluster(map: map, x: x + 1, y: y - 1)
            countVoxleCluster(map: map, x: x - 1, y: y + 1)
            countVoxleCluster(map: map, x: x - 1, y: y - 1)
        }
        
        for x in 0 ..< maps.count {
            for y in 0 ..< maps[x].count {
                if maps[x][y] == 1 {
                    countVoxleCluster(map: maps, x: x, y: y)
                    if count <= size {
                        vls.forEach { maps[$0[0]][$0[1]] = 2 }
                    }
                    vls.removeAll()
                    count = 0
                }
            }
        }
        return maps
    }
    
    
    
    private static func isValid(map: [[Int]], _ x: Int, _ y: Int) -> Bool {
        guard let inerList =  map.first else { return false }
        return (x >= 0) && (x < map.count)
            && (y >= 0) && (y < inerList.count)
    }
    
    
}
