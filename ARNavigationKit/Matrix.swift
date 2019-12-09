//
//  Matrix.swift
//  voxelMap
//
//  Created by Ferdinand Lösch on 27/10/2019.
//  Copyright © 2019 Ferdinand Lösch. All rights reserved.
//

import Foundation

struct Matrix {
    let rows: Int, columns: Int
    var grid: [Int]
    init(rows: Int, columns: Int) {
        self.rows = rows
        self.columns = columns
        grid = Array(repeating: 2, count: rows * columns)
    }

    func indexIsValid(row: Int, column: Int) -> Bool {
        return row >= 0 && row < rows && column >= 0 && column < columns
    }

    func get2DArray() -> [[Int]] {
        var array = [[Int]]()
        var row = [Int]()
        var count = 0
        for i in grid {
            row.append(i)
            count += 1
            if count == rows {
                array.append(row)
                row = []
                count = 0
            }
        }
        return array
    }

    subscript(row: Int, column: Int) -> Int {
        get {
            assert(indexIsValid(row: row, column: column), "Index out of range")
            return grid[(row * columns) + column]
        }
        set {
            assert(indexIsValid(row: row, column: column), "Index out of range")
            grid[(row * columns) + column] = newValue
        }
    }
}
