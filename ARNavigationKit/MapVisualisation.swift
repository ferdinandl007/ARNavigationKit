//
//  "MapVisualisation.swift
//  voxelMap
//
//  Created by Ferdinand Lösch on 11/11/2019.
//  Copyright © 2019 Ferdinand Lösch. All rights reserved.
//

import Foundation
import UIKit

private class Cell: Hashable {
    let x: Int, y: Int
    var state: State
    var neighbours: [Cell]

    func hash(into hasher: inout Hasher) {
        hasher.combine(y * 499)
        hasher.combine(x * 937)
    }

    init(x: Int, y: Int) {
        self.x = x
        self.y = y
        state = .notKnown
        neighbours = [Cell]()
    }
}

private func == (lhs: Cell, rhs: Cell) -> Bool {
    return lhs.x == rhs.x && lhs.y == rhs.y
}

private enum State {
    case free, blockt, notKnown, path, error
}

// the Game of Life 'World', contains an array of cells
private class World {
    var cells: [Cell]
    var dimensions: Int = 100

    init(arr: [[Int]]) {
        cells = [Cell]()
        dimensions = arr.count

        // create the cells
        for x in 0 ..< arr.count {
            for y in 0 ..< arr.first!.count {
                let cell = Cell(x: x, y: y)
                switch arr[x][y] {
                case 0:
                    cell.state = .free
                case 1:
                    cell.state = .blockt
                case 2:
                    cell.state = .notKnown
                case 3:
                    cell.state = .path
                case 4:
                    cell.state = .error
                default:
                    cell.state = .path
                }
                cells.append(cell)
            }
        }
    }
}

// A UIView subclass that renders the Game of Life 'World'
public class MapVisualisation: UIView {
    fileprivate let world: World

    public init(map: [[Int]]) {
        world = World(arr: map)
        super.init(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
    }

    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func draw(_: CGRect) {
        let context = UIGraphicsGetCurrentContext()

        func fillColorForCell(state: State) -> UIColor {
            switch state {
            case .free:
                return UIColor.lightGray
            case .blockt:
                return UIColor.black
            case .notKnown:
                return UIColor.white
            case .error:
                return UIColor.red
            default:
                return UIColor.green
            }
        }

        func frameForCell(cell: Cell) -> CGRect {
            let dimensions = CGFloat(world.dimensions)
            let cellSize = CGSize(width: bounds.width / dimensions, height: bounds.height / dimensions)
            return CGRect(x: CGFloat(cell.x) * cellSize.width, y: CGFloat(cell.y) * cellSize.height,
                          width: cellSize.width, height: cellSize.height)
        }

        for cell in world.cells {
            context!.setFillColor(fillColorForCell(state: cell.state).cgColor)
            context!.addRect(frameForCell(cell: cell))
            context!.fillPath()
        }
    }
}
