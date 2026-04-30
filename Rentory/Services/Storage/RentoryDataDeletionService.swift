//
//  RentoryDataDeletionService.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Foundation
import SwiftData

enum RentoryDataDeletionError: LocalizedError {
    case recordDeletionFailed
    case someFilesCouldNotBeRemoved
    case temporaryReportsCouldNotBeCleared

    var errorDescription: String? {
        switch self {
        case .recordDeletionFailed:
            return "This record could not be deleted."
        case .someFilesCouldNotBeRemoved:
            return "Some files could not be removed."
        case .temporaryReportsCouldNotBeCleared:
            return "Temporary reports could not be cleared."
        }
    }
}

struct RentoryDataDeletionService {
    private let fileStorageService: FileStorageService

    init(fileStorageService: FileStorageService = FileStorageService()) {
        self.fileStorageService = fileStorageService
    }

    func deletePropertyPack(_ propertyPack: PropertyPack, context: ModelContext) throws {
        do {
            try deleteLinkedFiles(for: propertyPack)
            context.delete(propertyPack)
            try context.save()
        } catch let error as FileStorageError {
            switch error {
            case .invalidFileName, .unableToDeleteFile:
                throw RentoryDataDeletionError.someFilesCouldNotBeRemoved
            default:
                throw RentoryDataDeletionError.recordDeletionFailed
            }
        } catch let error as RentoryDataDeletionError {
            throw error
        } catch {
            throw RentoryDataDeletionError.recordDeletionFailed
        }
    }

    func deleteAllData(context: ModelContext) throws {
        do {
            let propertyPacks = try context.fetch(FetchDescriptor<PropertyPack>())

            for propertyPack in propertyPacks {
                context.delete(propertyPack)
            }

            try fileStorageService.deleteAllStoredFiles()
            try context.save()
        } catch let error as FileStorageError {
            switch error {
            case .invalidFileName, .unableToDeleteFile:
                throw RentoryDataDeletionError.someFilesCouldNotBeRemoved
            default:
                throw RentoryDataDeletionError.recordDeletionFailed
            }
        } catch let error as RentoryDataDeletionError {
            throw error
        } catch {
            throw RentoryDataDeletionError.recordDeletionFailed
        }
    }

    func clearTemporaryReports() throws {
        do {
            try fileStorageService.deleteStoredFiles(of: .temporaryExport)
        } catch {
            throw RentoryDataDeletionError.temporaryReportsCouldNotBeCleared
        }
    }

    private func deleteLinkedFiles(for propertyPack: PropertyPack) throws {
        for room in propertyPack.rooms {
            for checklistItem in room.checklistItems {
                for photo in checklistItem.photos {
                    try fileStorageService.deleteEvidencePhoto(fileName: photo.localFileName)
                }
            }
        }

        for document in propertyPack.documents {
            try fileStorageService.deleteDocument(fileName: document.localFileName)
        }
    }
}
