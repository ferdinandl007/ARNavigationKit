import Foundation
import UIKit

class AStar {
    class Node: Comparable, Hashable {
        var parent: Node?
        var position: CGPoint
        var g: Double
        var h: Double

        init(parent: Node?, position: CGPoint, g: Double, h: Double) {
            self.parent = parent
            self.position = position
            self.g = g
            self.h = h
        }

        func hash(into hasher: inout Hasher) {
            let hash = (Int(position.x) * 499) + (Int(position.y) * 937)
            hasher.combine(hash)
        }

        init() {
            parent = nil
            position = CGPoint()
            g = 0
            h = 0
        }

        static func < (lhs: AStar.Node, rhs: AStar.Node) -> Bool {
            return (lhs.g + lhs.h) < (rhs.g + rhs.h)
        }

        static func == (lhs: AStar.Node, rhs: AStar.Node) -> Bool {
            return lhs.position == rhs.position
        }
    }

    private var open: Heap<Node>
    private var openSet: Set<Node>
    private var closed: Set<Node>
    private var path: [Node]
    private var map: [[Int]]
    private var now: Node
    private var start: CGPoint
    private var end: CGPoint
    private var diag: Bool

    init(map: [[Int]], start: CGPoint, diag: Bool) {
        open = Heap<Node>(sort: <)
        closed = Set<Node>()
        path = []
        self.map = map
        now = Node(parent: nil, position: start, g: 0, h: 0)
        self.start = start
        end = CGPoint()
        self.diag = diag
        openSet = Set<Node>()
        // If the source is out of range.
        if !isValid(start.xI, start.yI) {
            print("Source is invalid")
        }
        // Either the source or the destination is blocked.
        if map[start.xI][start.yI] == 1 {
            print("Source is blocked")
        }
    }

    /// Finds path to xend/yend or returns nil
    /// - Parameter end: end coordinates of the target position
    func findPathTo(end: CGPoint) -> [Node]? {
        // If the destination is out of range.
        if !isValid(end.xI, end.yI) {
            print("Destination is invalid")
            return nil
        }

        // destination is blocked.
        if map[end.xI][end.yI] == 1 {
            print("destination is blocked")
            return nil
        }

        self.end = end
        closed.insert(now)
        addNeigborsToOpenList()
        while now.position.x != end.x || now.position.y != end.y {
            if open.isEmpty { // Nothing to examine
                return nil
            }
            now = open.remove(at: 0)!
            openSet.remove(now)
            closed.insert(now)
            addNeigborsToOpenList()
        }
        path.insert(now, at: 0)
        while now.position.x != start.x || now.position.y != start.y {
            now = now.parent!
            path.insert(now, at: 0)
        }

        return path
    }

    /// Calulate distance between this.now and xend/yend
    /// -@return (int) distance
    private func distance(_ point: CGPoint) -> Double {
        if diag { // if diagonal movement is alloweed
            return sqrt(pow((now.position.xD + point.xD) - end.xD, 2) + pow((now.position.yD + point.yD) - end.yD, 2)) // return hypothenuse
        } else {
            return abs((now.position.xD + point.xD) - end.xD) + abs((now.position.yD + point.yD) - end.yD) // else return "Manhattan distance
        }
    }

    private func addNeigborsToOpenList() {
        var node = Node()
        for x in -1 ... 1 {
            for y in -1 ... 1 {
                if !diag && x != 0 && y != 0 {
                    continue // skip if diagonal movement is not allowed
                }
                let newX: Int = now.position.xI + x
                let newY: Int = now.position.yI + y
                node = Node(parent: now, position: CGPoint(x: newX, y: newY), g: now.g, h: distance(CGPoint(x: x, y: y)))
                let move = getNNabers(arr: map, x: newX, y: newY, n: 1)
                
                if x != 0 || y != 0,
//                    now.position.xI + x >= 0, now.position.xI + x < map.count, // check maze boundaries x
//                    now.position.yI + y >= 0, now.position.yI + y < map[0].count,
                    isValid(newX, newY),
//                    map[now.position.xI + x][now.position.yI + y] != 1,// check if square is walkable
                    move,
                    !closed.contains(node), !openSet.contains(node) {
                    node.g = node.parent!.g + 1 // Horizontal/vertical cost = 1.0
                    node.g += Double(map[newX][newY]) // add movement cost for this square
                    node.g += map[newX][newY] == 2 ? 3 : 0
                    // diagonal cost = sqrt(hor_cost² + vert_cost²)
                    // in this example the cost would be 12.2 instead of 11
                    if diag, x != 0, y != 0 {
                        node.g += 0.4 // Diagonal movement cost = 1.4
                    }

                    open.insert(value: node)
                    openSet.insert(node)
                }
            }
        }
    }
    
    
    private func getNNabers(arr:[[Int]],x: Int,y: Int,n: Int) -> Bool {
        if !isValid(x, y) || arr[x][y] == 1 {
            return false
        }
        
        if n == 0 {
            return true
        }
        
        return (getNNabers(arr: arr, x: x + 1, y: y, n: n - 1) &&
            getNNabers(arr: arr, x: x - 1, y: y, n: n - 1) &&
            getNNabers(arr: arr, x: x, y: y + 1, n: n - 1) &&
            getNNabers(arr: arr, x: x, y: y - 1, n: n - 1))
    }

    private func isValid(_ x: Int, _ y: Int) -> Bool {
        return (x >= 0) && (x < map.count)
            && (y >= 0) && (y < map.first!.count)
    }
}
