//
//  PhotoStorageService.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct PhotoStorageService {
    private let fileStorageService: FileStorageService
    private let compressionQuality: CGFloat
    private let maxLongestEdge: CGFloat

    init(
        fileStorageService: FileStorageService = FileStorageService(),
        compressionQuality: CGFloat = 0.82,
        maxLongestEdge: CGFloat = 2400
    ) {
        self.fileStorageService = fileStorageService
        self.compressionQuality = compressionQuality
        self.maxLongestEdge = maxLongestEdge
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

    func deletePhoto(fileName: String) throws {
        do {
            try fileStorageService.deleteEvidencePhoto(fileName: fileName)
        } catch {
            throw ImageProcessingError.unableToLoadImage
        }
    }
}
