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
        case migrationCancelled
    }

    public let modelController: ModelController
    public let plists: [ModelPlist.Type]

    public init(modelController: ModelController, plists: [ModelPlist.Type]) {
        self.modelController = modelController
        self.plists = plists.sorted(by: { $0.version < $1.version })
    }

    public func read(plistWrapper: FileWrapper, contentWrapper: FileWrapper?, shouldMigrate: () -> Bool) throws {
        guard
            let plistData = plistWrapper.regularFileContents,
			let plistDict = try? PropertyListSerialization.propertyListValue(from: plistData) as? [String: PlistValue],
			let convertedDict = plistDict as? [String: PlistValue]
        else {
            throw Errors.invalidPlist
        }

        //We default to 1 here as the only thing that should not have a version property is a v1 Coppice document
		let version: Int = try .fromPlistValue(convertedDict["version", default: 1])
        let plistTypes = self.plistTypes(fromVersion: version)
        guard plistTypes.count > 0 else {
            throw Errors.versionNotSupported
        }

        if plistTypes.count > 1 {
            guard shouldMigrate() else {
                throw Errors.migrationCancelled
            }
        }

        let plist = try self.loadPlist(fromDictionary: convertedDict, usingTypes: plistTypes)

        self.modelController.settings.update(withPlist: plist.settings)

		for (modelType, collection) in self.modelController.allCollections.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            self.createAndDeleteObjects(in: collection, using: plist.plistRepresentations(of: modelType))
        }

        for (modelType, collection) in self.modelController.allCollections.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
			print("Updating \(modelType.rawValue)")
            try self.updateObjects(in: collection, using: plist.plistRepresentations(of: modelType), content: contentWrapper?.fileWrappers)
        }
    }

    private func plistTypes(fromVersion version: Int) -> [ModelPlist.Type] {
        return self.plists.filter { $0.version >= version }
    }

    private func loadPlist(fromDictionary plistDict: [String: PlistValue], usingTypes plistTypes: [ModelPlist.Type]) throws -> ModelPlist {
        var nextTypes = plistTypes
        let plistType = nextTypes.removeFirst()
        let plist = try plistType.init(plist: plistDict)
        if nextTypes.count == 0 {
            return plist
        }

        return try self.loadPlist(fromDictionary: try plist.migrateToNextVersion(), usingTypes: nextTypes)
    }

    private func createAndDeleteObjects(in collection: AnyModelCollection, using plistRepresentations: [ModelObjectPlistRepresentation]) {
        try? collection.disableUndo {
            let existingIDs = Set(collection.all.map { $0.id })
			let newIDs = Set(plistRepresentations.compactMap { $0.id })

            let itemsToAdd = newIDs.subtracting(existingIDs)
            let itemsToRemove = existingIDs.subtracting(newIDs)

            for id in itemsToRemove {
                if let item = collection.objectWithID(id) {
                    collection.delete(item)
                }
            }

            for id in itemsToAdd {
				collection.newObject(modelID: id)
            }
        }
    }

    private func updateObjects(in collection: AnyModelCollection, using plistRepresentations: [ModelObjectPlistRepresentation], content: [String: FileWrapper]?) throws {
        try collection.disableUndo {
            for plistRepresentation in plistRepresentations {
                guard let item = collection.objectWithID(plistRepresentation.id) else {
                    return
                }

				let plist: ModelObjectPlistRepresentation
				if let content {
					print("has content")
					plist = try plistRepresentation.applyingModelFiles(from: content, to: item.modelFileProperties)
				} else {
					print("doesn't have content")
					plist = plistRepresentation
				}

				try item.update(fromPlistRepresentation: plist)
            }
        }
    }
}
