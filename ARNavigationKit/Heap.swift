import Foundation

public struct Heap<T> {
    var elements = [T]()

    public var isEmpty: Bool { return elements.isEmpty }
    public var count: Int { return elements.count }
    public var isOrdered: (T, T) -> Bool

    public init(sort: @escaping (T, T) -> Bool) {
        isOrdered = sort
    }

    func parentOf(_ index: Int) -> Int {
        return (index - 1) / 2
    }

    func leftOf(_ index: Int) -> Int {
        return (2 * index) + 1
    }

    func rightOf(_ index: Int) -> Int {
        return (2 * index) + 2
    }

    mutating func heapifyDown(index: Int, heapSize: Int) {
        var parentIndex = index
        while true {
            let leftIndex = leftOf(parentIndex)
            let rightIndex = leftIndex + 1

            var first = parentIndex
            if leftIndex < heapSize, isOrdered(elements[leftIndex], elements[first]) {
                first = leftIndex
            }
            if rightIndex < heapSize, isOrdered(elements[rightIndex], elements[first]) {
                first = rightIndex
            }
            if first == parentIndex { return }

            elements.swapAt(parentIndex, first)
            parentIndex = first
        }
    }

    mutating func shiftDown() {
        heapifyDown(index: 0, heapSize: elements.count)
    }

    mutating func buildHeap(fromArray array: [T]) {
        elements = array
        for i in stride(from: elements.count / 2 - 1, through: 0, by: -1) {
            heapifyDown(index: i, heapSize: elements.count)
        }
    }

    mutating func heapifyUp(index: Int) {
        var nodeIndex = index

        while true {
            let parentIndex = parentOf(nodeIndex)

            var first = parentIndex
            if parentIndex >= 0, isOrdered(elements[nodeIndex], elements[first]) {
                first = nodeIndex
            }
            if first == parentIndex { return }

            elements.swapAt(parentIndex, first)
            nodeIndex = first
        }
    }

    public mutating func insert(value: T) {
        elements.append(value)

        heapifyUp(index: elements.count - 1)
    }

    public mutating func remove(at index: Int) -> T? {
        let temp: T

        if index < 0, count - 1 <= index {
            return nil
        }
        temp = elements[index]
        elements[index] = elements[count - 1]
        elements.removeLast()
        shiftDown()
        return temp
    }
}
