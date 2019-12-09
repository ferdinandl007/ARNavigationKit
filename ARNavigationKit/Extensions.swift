//
//  Extensions.swift
//  voxelMap
//
//  Created by Ferdinand Lösch on 09/12/2019.
//  Copyright © 2019 Ferdinand Lösch. All rights reserved.
//

import Foundation
import UIKit

extension CGPoint {
    var xD: Double { return Double(x) }
    var yD: Double { return Double(y) }
    var xI: Int { return Int(x) }
    var yI: Int { return Int(y) }
}

extension CGSize {
    var heightI: Int { return Int(height) }
    var widthI: Int { return Int(width) }
}
