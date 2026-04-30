//
//  ImageResizer.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import CoreGraphics
import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
typealias UIImage = NSImage
#endif

enum ImageResizer {
    static func resizedImage(
        from image: UIImage,
        maxLongestEdge: CGFloat = 2400
    ) -> UIImage {
        let originalSize = image.rrSize
        let longestEdge = max(originalSize.width, originalSize.height)

        guard longestEdge > maxLongestEdge, longestEdge > 0 else {
            return image
        }

        let scaleRatio = maxLongestEdge / longestEdge
        let targetSize = CGSize(
            width: floor(originalSize.width * scaleRatio),
            height: floor(originalSize.height * scaleRatio)
        )

        guard let cgImage = image.rrCGImage,
              let context = CGContext(
                data: nil,
                width: Int(targetSize.width),
                height: Int(targetSize.height),
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            return image
        }

        context.interpolationQuality = CGInterpolationQuality.high
        context.draw(cgImage, in: CGRect(origin: .zero, size: targetSize))

        guard let resizedCGImage = context.makeImage() else {
            return image
        }

        return UIImage.rrImage(from: resizedCGImage, size: targetSize)
    }
}

#if canImport(UIKit)
extension UIImage {
    var rrSize: CGSize {
        size
    }

    var rrCGImage: CGImage? {
        if let cgImage {
            return cgImage
        }

        guard let ciImage else {
            return nil
        }

        return CIContext().createCGImage(ciImage, from: ciImage.extent)
    }

    static func rrImage(from cgImage: CGImage, size: CGSize) -> UIImage {
        UIImage(cgImage: cgImage, scale: 1, orientation: .up)
    }

    func rrJPEGData(compressionQuality: CGFloat) -> Data? {
        jpegData(compressionQuality: compressionQuality)
    }
}
#elseif canImport(AppKit)
extension NSImage {
    var rrSize: CGSize {
        size
    }

    var rrCGImage: CGImage? {
        var proposedRect = CGRect(origin: .zero, size: size)
        return cgImage(forProposedRect: &proposedRect, context: nil, hints: nil)
    }

    static func rrImage(from cgImage: CGImage, size: CGSize) -> NSImage {
        NSImage(cgImage: cgImage, size: size)
    }

    func rrJPEGData(compressionQuality: CGFloat) -> Data? {
        guard let cgImage = rrCGImage else {
            return nil
        }

        let bitmapRepresentation = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRepresentation.representation(
            using: .jpeg,
            properties: [.compressionFactor: compressionQuality]
        )
    }
}
#endif
