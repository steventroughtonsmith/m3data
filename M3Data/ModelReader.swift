//
//  ModelReader.swift
//  M3Data
//
//  Created by Martin Pilkington on 25/07/2022.
//

import Foundation

public class ModelReader {
    public enum Errors: Error, Equatable {
        case invalidPlist
        case versionNotSupported
    }

    public let modelController: ModelController
    public let plists: [ModelPlist.Type]

    public init(modelController: ModelController, plists: [ModelPlist.Type]) {
        self.modelController = modelController
        self.plists = plists.sorted(by: { $0.version < $1.version })
    }

    public func read(plistWrapper: FileWrapper, contentWrapper: FileWrapper?) throws {
        guard
            let plistData = plistWrapper.regularFileContents,
            let plistDict = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any]
        else {
            throw Errors.invalidPlist
        }

        //We default to 1 here as the only thing that should not have a version property is a v1 Coppice document
        let version = (plistDict["version"] as? Int) ?? 1
        let plistTypes = self.plistTypes(fromVersion: version)
        guard plistTypes.count > 0 else {
            throw Errors.versionNotSupported
        }

        let plist = try self.loadPlist(fromDictionary: plistDict, usingTypes: plistTypes)

        self.modelController.settings.update(withPlist: plist.settings)

        for (modelType, collection) in self.modelController.allCollections {
            self.createAndDeleteObjects(in: collection, using: plist.plistRepresentations(of: modelType))
        }

        for (modelType, collection) in self.modelController.allCollections {
            try self.updateObjects(in: collection, using: plist.plistRepresentations(of: modelType), content: contentWrapper?.fileWrappers)
        }


    }

    private func plistTypes(fromVersion version: Int) -> [ModelPlist.Type] {
        return self.plists.filter { $0.version >= version }
    }

    private func loadPlist(fromDictionary plistDict: [String: Any], usingTypes plistTypes: [ModelPlist.Type]) throws -> ModelPlist {
        var nextTypes = plistTypes
        let plistType = nextTypes.removeFirst()
        let plist = try plistType.init(plist: plistDict)
        if nextTypes.count == 0 {
            return plist
        }

        return try self.loadPlist(fromDictionary: try plist.migrateToNextVersion(), usingTypes: nextTypes)
    }

    private func createAndDeleteObjects(in collection: AnyModelCollection, using plistRepresentations: [[ModelPlistKey: Any]]) {
        collection.disableUndo {
            let existingIDs = Set(collection.all.map { $0.id })
            let newIDs = Set(plistRepresentations.compactMap { $0[.id] as? ModelID })

            let itemsToAdd = newIDs.subtracting(existingIDs)
            let itemsToRemove = existingIDs.subtracting(newIDs)

            for id in itemsToRemove {
                if let item = collection.objectWithID(id) {
                    collection.delete(item)
                }
            }

            for id in itemsToAdd {
                collection.newObject() { $0.id = id }
            }
        }
    }

    private func updateObjects(in collection: AnyModelCollection, using plistRepresentations: [[ModelPlistKey: Any]], content: [String: FileWrapper]?) throws {
        try collection.disableUndo {
            for plistRepresentation in plistRepresentations {
                guard
                    let id = plistRepresentation[.id] as? ModelID,
                    let item = collection.objectWithID(id)
                else {
                    return
                }


                var plistItemWithModelFiles = plistRepresentation
                for modelFileProperty in item.modelFileProperties {
                    let modelFilePlist = plistItemWithModelFiles[modelFileProperty] as? [String: Any]
                    guard let type = modelFilePlist?["type"] as? String else {
                        continue
                    }

                    let metadata = modelFilePlist?["metadata"] as? [String: Any]
                    let modelFile: ModelFile
                    if let filename = modelFilePlist?["filename"] as? String {
                        let data = content?[filename]?.regularFileContents
                        modelFile = ModelFile(type: type, filename: filename, data: data, metadata: metadata)
                    } else {
                        modelFile = ModelFile(type: type, filename: nil, data: nil, metadata: metadata)
                    }

                    plistItemWithModelFiles[modelFileProperty] = modelFile
                }
                try item.update(fromPlistRepresentation: plistItemWithModelFiles)
            }
        }
    }
}
