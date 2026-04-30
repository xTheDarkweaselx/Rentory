//
//  ImageProcessingError.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Foundation

enum ImageProcessingError: LocalizedError {
    case unableToReadImage
    case unableToPrepareImage
    case unableToSaveImage
    case unableToLoadImage

    var errorDescription: String? {
        switch self {
        case .unableToReadImage, .unableToLoadImage:
            return "This photo could not be opened."
        case .unableToPrepareImage:
            return "This photo could not be prepared."
        case .unableToSaveImage:
            return "This photo could not be saved."
        }
    }
}
