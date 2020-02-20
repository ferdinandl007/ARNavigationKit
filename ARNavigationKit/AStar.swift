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

    private func distance(_ point: CGPoint) -> Double {
        if diag { // if diagonal movement is alloweed.
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
                    continue // skip if diagonal movement is not allowed.
                }
                let newX: Int = now.position.xI + x
                let newY: Int = now.position.yI + y
                node = Node(parent: now, position: CGPoint(x: newX, y: newY), g: now.g, h: distance(CGPoint(x: x, y: y)))
                let move = getNNabers(arr: map, x: newX, y: newY, n: 1).0
                
                if x != 0 || y != 0,
                    isValid(newX, newY),move,
                    !closed.contains(node), !openSet.contains(node) {
                    guard let currentParent = node.parent else { continue }
                    node.g = currentParent.g + 1 // Horizontal/vertical cost = 1.0.
                    node.g += Double(map[newX][newY]) // add movement cost for this square.
                    node.g += map[newX][newY] == 2 ? 3 : 0
                    
                    // Ensures a safe boundary around obstacles if possible.
                    let gAdd  = getNNabers(arr: map, x: newX, y: newY, n: 4)
                    if !gAdd.0 {
                        node.g += 5.0 - Double(gAdd.1)
                    }
                    
                    if diag, x != 0, y != 0 {
                        node.g += 0.4 // Diagonal movement cost = 1.4.
                    }

                    open.insert(value: node)
                    openSet.insert(node)
                }
            }
        }
    }
    
    
    private func getNNabers(arr:[[Int]],x: Int,y: Int,n: Int) -> (Bool,Int) {
        if !isValid(x, y) || arr[x][y] == 1 {
            return (false , n)
        }
        
        if n == 0 {
            return (true, n)
        }
        let r1 = getNNabers(arr: arr, x: x + 1, y: y, n: n - 1)
        let r2 = getNNabers(arr: arr, x: x - 1, y: y, n: n - 1)
        let r3 = getNNabers(arr: arr, x: x, y: y + 1, n: n - 1)
        let r4 = getNNabers(arr: arr, x: x, y: y - 1, n: n - 1)
        
        let minR = [r1.1,r2.1,r3.1,r4.1].min() ?? n
        let boolR = r1.0 && r2.0 && r3.0 && r4.0
        return (boolR,minR)
    }

    private func isValid(_ x: Int, _ y: Int) -> Bool {
        guard let inerList =  map.first else { return false }
        return (x >= 0) && (x < map.count)
            && (y >= 0) && (y < inerList.count)
    }
}
