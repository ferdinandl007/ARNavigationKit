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
    public static func mapRoasting(_ _map: [[Int]], kernel: CGSize) -> [[Int]]? {
        var map = _map
        if map.count < 1 || map[0].count < 1 { return nil }
        if kernel.widthI > map[0].count || kernel.heightI > map.count { return nil }

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
}
