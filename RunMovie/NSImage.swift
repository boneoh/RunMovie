//
//  NSImage.swift
//  CustomCompositor
//
//  Created by peterappleby on 3/24/22.
//  Copyright © 2022 Peter M. Appleby aka Boneoh.  All rights reserved.
//
import SwiftUI
import AVKit
import AVFoundation
import CoreImage

import Foundation
import os
 
extension NSImage {
    
    /// Generates a CIImage for this NSImage.
    /// - Returns: A CIImage optional.
    func ciImage() -> CIImage? {
        guard let data = self.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: data) else {
            return nil
        }
        let ci = CIImage(bitmapImageRep: bitmap)
        return ci
    }
    
    /// Generates an NSImage from a CIImage.
    /// - Parameter ciImage: The CIImage
    /// - Returns: An NSImage optional.
    static func fromCIImage(_ ciImage: CIImage) -> NSImage {
        let rep = NSCIImageRep(ciImage: ciImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        return nsImage
    }
    
    var pngData: Data? {
        guard let tiffRepresentation = tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmapImage.representation(using: .png, properties: [:])
    }

    func pngWrite(to url: URL, options: Data.WritingOptions = .atomic) -> Bool {
        do {
            try pngData?.write(to: url, options: options)
            return true
        } catch {
            print(error)
            return false
        }
    }
}
