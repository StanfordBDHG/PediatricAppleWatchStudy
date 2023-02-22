//
// This source file is part of the CS342 2023 Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


extension Bundle {
    /// Loads an image from the `Bundle` and returns the content as a SwiftUI `Image`.
    /// - Parameter name: The name of the image file.
    /// - Returns: SwiftUI `Image` instance loaded from the `Bundle`.
    public func image(fromFileNamed name: String, type: String = "jpeg") -> Image {
        guard let imagePath = self.path(forResource: name, ofType: type),
           let image = UIImage(contentsOfFile: imagePath) else {
            return Image(systemName: "person.fill")
        }
        
        return Image(uiImage: image)
    }
}
