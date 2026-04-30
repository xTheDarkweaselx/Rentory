//
//  FileStorageError.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Foundation

enum FileStorageError: LocalizedError {
    case invalidFileName
    case unableToCreateFolder
    case unableToCopyFile
    case unableToWriteFile
    case unableToReadFile
    case unableToDeleteFile
    case unsupportedFileType

    var errorDescription: String? {
        switch self {
        case .invalidFileName, .unableToReadFile:
            return "This file could not be opened."
        case .unableToCreateFolder, .unableToCopyFile, .unableToWriteFile:
            return "This file could not be saved."
        case .unableToDeleteFile:
            return "This file could not be deleted."
        case .unsupportedFileType:
            return "This file type is not supported."
        }
    }
}
