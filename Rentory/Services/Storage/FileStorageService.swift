//
//  FileStorageService.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Foundation

struct FileStorageService {
    private let fileManager: FileManager
    private let baseDirectoryURL: URL
    private let supportedDocumentExtensions = Set([
        "pdf", "jpg", "jpeg", "png", "heic", "txt", "rtf", "doc", "docx",
    ])
    private let supportedImageExtensions = Set([
        "jpg", "jpeg", "png", "heic",
    ])

    init(
        fileManager: FileManager = .default,
        baseDirectoryURL: URL? = nil
    ) {
        self.fileManager = fileManager
        self.baseDirectoryURL = baseDirectoryURL ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    }

    func saveDocument(from sourceURL: URL) throws -> String {
        let fileExtension = try normalisedExtension(
            from: sourceURL.pathExtension,
            allowedExtensions: supportedDocumentExtensions
        )

        let fileName = makeGeneratedFileName(withExtension: fileExtension)
        let destinationURL = try fileURL(for: .importedDocument, fileName: fileName)

        do {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            try applyFileProtection(to: destinationURL)
            return fileName
        } catch let error as FileStorageError {
            throw error
        } catch {
            throw FileStorageError.unableToCopyFile
        }
    }

    func saveImageData(_ data: Data, fileExtension: String) throws -> String {
        let normalisedFileExtension = try normalisedExtension(
            from: fileExtension,
            allowedExtensions: supportedImageExtensions
        )

        let fileName = makeGeneratedFileName(withExtension: normalisedFileExtension)
        let destinationURL = try fileURL(for: .evidencePhoto, fileName: fileName)

        do {
            try data.write(to: destinationURL, options: .atomic)
            try applyFileProtection(to: destinationURL)
            return fileName
        } catch let error as FileStorageError {
            throw error
        } catch {
            throw FileStorageError.unableToWriteFile
        }
    }

    func saveTemporaryExportData(_ data: Data, preferredFileName: String) throws -> URL {
        let fileExtension = try normalisedExtension(
            from: URL(fileURLWithPath: preferredFileName).pathExtension,
            allowedExtensions: supportedDocumentExtensions
        )
        let baseName = preferredFileName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ".\(fileExtension)", with: "")
        let safeBaseName = try validateFileName(baseName)
        let fileName = "\(safeBaseName).\(fileExtension)"
        let destinationURL = try fileURL(for: .temporaryExport, fileName: fileName)

        do {
            try data.write(to: destinationURL, options: .atomic)
            try applyFileProtection(to: destinationURL)
            return destinationURL
        } catch let error as FileStorageError {
            throw error
        } catch {
            throw FileStorageError.unableToWriteFile
        }
    }

    func urlForDocument(fileName: String) throws -> URL {
        try readURL(for: .importedDocument, fileName: fileName)
    }

    func urlForEvidencePhoto(fileName: String) throws -> URL {
        try readURL(for: .evidencePhoto, fileName: fileName)
    }

    func urlForTemporaryExport(fileName: String) throws -> URL {
        try readURL(for: .temporaryExport, fileName: fileName)
    }

    func deleteDocument(fileName: String) throws {
        try deleteFile(for: .importedDocument, fileName: fileName)
    }

    func deleteEvidencePhoto(fileName: String) throws {
        try deleteFile(for: .evidencePhoto, fileName: fileName)
    }

    func deleteTemporaryExport(fileName: String) throws {
        try deleteFile(for: .temporaryExport, fileName: fileName)
    }

    func deleteAllStoredFiles() throws {
        for kind in [StoredFileKind.evidencePhoto, .importedDocument, .temporaryExport] {
            try deleteStoredFiles(of: kind)
        }
    }

    func deleteStoredFiles(of kind: StoredFileKind) throws {
        let folderURL = baseDirectoryURL.appendingPathComponent(kind.folderName, isDirectory: true)

        guard fileManager.fileExists(atPath: folderURL.path) else {
            return
        }

        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: folderURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )

            for fileURL in fileURLs {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            throw FileStorageError.unableToDeleteFile
        }
    }

    private func readURL(for kind: StoredFileKind, fileName: String) throws -> URL {
        let fileURL = try fileURL(for: kind, fileName: fileName)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw FileStorageError.unableToReadFile
        }

        return fileURL
    }

    private func deleteFile(for kind: StoredFileKind, fileName: String) throws {
        let fileURL = try fileURL(for: kind, fileName: fileName)

        do {
            try fileManager.removeItem(at: fileURL)
        } catch {
            throw FileStorageError.unableToDeleteFile
        }
    }

    private func fileURL(for kind: StoredFileKind, fileName: String) throws -> URL {
        let validFileName = try validateFileName(fileName)
        try ensureFolderExists(for: kind)

        return baseDirectoryURL
            .appendingPathComponent(kind.folderName, isDirectory: true)
            .appendingPathComponent(validFileName, isDirectory: false)
    }

    private func ensureFolderExists(for kind: StoredFileKind) throws {
        let folderURL = baseDirectoryURL.appendingPathComponent(kind.folderName, isDirectory: true)

        guard !fileManager.fileExists(atPath: folderURL.path) else {
            return
        }

        do {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
            try applyFileProtection(to: folderURL)
        } catch {
            throw FileStorageError.unableToCreateFolder
        }
    }

    private func applyFileProtection(to url: URL) throws {
#if os(iOS) || os(tvOS) || os(watchOS) || targetEnvironment(macCatalyst)
        do {
            try fileManager.setAttributes(
                [.protectionKey: FileProtectionType.complete],
                ofItemAtPath: url.path
            )
        } catch {
            throw FileStorageError.unableToWriteFile
        }
#endif
    }

    private func validateFileName(_ fileName: String) throws -> String {
        let trimmedFileName = fileName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedFileName.isEmpty,
              !trimmedFileName.contains("/"),
              !trimmedFileName.contains("..") else {
            throw FileStorageError.invalidFileName
        }

        return trimmedFileName
    }

    private func normalisedExtension(from fileExtension: String, allowedExtensions: Set<String>) throws -> String {
        let normalisedFileExtension = fileExtension
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !normalisedFileExtension.isEmpty,
              allowedExtensions.contains(normalisedFileExtension) else {
            throw FileStorageError.unsupportedFileType
        }

        return normalisedFileExtension
    }

    private func makeGeneratedFileName(withExtension fileExtension: String) -> String {
        "\(UUID().uuidString.lowercased()).\(fileExtension)"
    }
}
