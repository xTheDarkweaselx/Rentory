//
//  PhotoStorageService.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Foundation
import ImageIO

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct PhotoStorageService {
    private static let thumbnailCache = NSCache<NSString, UIImage>()

    private let fileStorageService: FileStorageService
    private let compressionQuality: CGFloat
    private let maxLongestEdge: CGFloat
    private let thumbnailLongestEdge: CGFloat

    init(
        fileStorageService: FileStorageService = FileStorageService(),
        compressionQuality: CGFloat = 0.82,
        maxLongestEdge: CGFloat = 2400,
        thumbnailLongestEdge: CGFloat = 420
    ) {
        self.fileStorageService = fileStorageService
        self.compressionQuality = compressionQuality
        self.maxLongestEdge = maxLongestEdge
        self.thumbnailLongestEdge = thumbnailLongestEdge
    }

    func savePhoto(_ image: UIImage) throws -> String {
        let preparedImage = ImageResizer.resizedImage(from: image, maxLongestEdge: maxLongestEdge)

        guard let jpegData = preparedImage.rrJPEGData(compressionQuality: compressionQuality) else {
            throw ImageProcessingError.unableToPrepareImage
        }

        do {
            return try fileStorageService.saveImageData(jpegData, fileExtension: "jpg")
        } catch {
            throw ImageProcessingError.unableToSaveImage
        }
    }

    func loadPhoto(fileName: String) throws -> UIImage {
        do {
            let photoURL = try fileStorageService.urlForEvidencePhoto(fileName: fileName)
            let imageData = try Data(contentsOf: photoURL, options: [.mappedIfSafe])

            guard let image = UIImage(data: imageData) else {
                throw ImageProcessingError.unableToLoadImage
            }

            return image
        } catch let error as ImageProcessingError {
            throw error
        } catch let error as FileStorageError {
            switch error {
            case .invalidFileName, .unableToReadFile:
                throw ImageProcessingError.unableToLoadImage
            default:
                throw ImageProcessingError.unableToReadImage
            }
        } catch {
            throw ImageProcessingError.unableToReadImage
        }
    }

    func loadThumbnailCGImage(fileName: String) throws -> CGImage {
        do {
            let photoURL = try fileStorageService.urlForEvidencePhoto(fileName: fileName)
            return try Self.makeThumbnailCGImage(for: photoURL, maxPixelSize: Int(thumbnailLongestEdge))
        } catch let error as ImageProcessingError {
            throw error
        } catch let error as FileStorageError {
            switch error {
            case .invalidFileName, .unableToReadFile:
                throw ImageProcessingError.unableToLoadImage
            default:
                throw ImageProcessingError.unableToReadImage
            }
        } catch {
            throw ImageProcessingError.unableToReadImage
        }
    }

    func deletePhoto(fileName: String) throws {
        do {
            try fileStorageService.deleteEvidencePhoto(fileName: fileName)
            Self.thumbnailCache.removeObject(forKey: fileName as NSString)
        } catch {
            throw ImageProcessingError.unableToLoadImage
        }
    }

    func cachedThumbnail(for fileName: String) -> UIImage? {
        Self.thumbnailCache.object(forKey: fileName as NSString)
    }

    func storeThumbnail(_ image: UIImage, for fileName: String) {
        Self.thumbnailCache.setObject(image, forKey: fileName as NSString)
    }

    nonisolated static func makeThumbnailCGImage(for url: URL, maxPixelSize: Int) throws -> CGImage {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: false,
            kCGImageSourceShouldCache: false,
        ]

        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw ImageProcessingError.unableToLoadImage
        }

        return cgImage
    }
}
