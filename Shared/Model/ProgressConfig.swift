//
//  ProgressConfig.swift
//  FileProgressView (iOS)
//
//  Created by Swaminathan Venkataraman on 8/28/23.
//

import Foundation
import SwiftUI

struct ProgressConfig {
    var title: String
    var progressImage: String
    var expandedImage: String
    var tint: Color
    var rotationEnabled: Bool = false
}

extension Color {
    static let brandPrimary = Color("brandPrimary")
}
