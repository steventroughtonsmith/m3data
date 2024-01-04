//
//  File.swift
//  
//
//  Created by Martin Pilkington on 28/12/2023.
//

import Foundation


public struct ModelObjectPlistRepresentation {
	public var id: ModelID
	public var plist: [ModelPlistKey: PlistValue]

	public init(id: ModelID, plist: [ModelPlistKey : PlistValue]) {
		self.id = id
		self.plist = plist
	}

	init(persistenceRepresentation: [String: PlistValue]) throws {
		var modelID: ModelID?
		var modelPlistKeys = [ModelPlistKey: PlistValue]()
		for (key, value) in persistenceRepresentation {
			let plistKey = ModelPlistKey(rawValue: key)
			if (plistKey == .id), let plistModelID: ModelID = try .fromPlistValue(value) {
				modelID = plistModelID
			}
			modelPlistKeys[plistKey] = value
		}
		
		guard let modelID else {
			throw ModelPlist.Errors.missingID(persistenceRepresentation)
		}
		self.init(id: modelID, plist: modelPlistKeys)
	}

	public var persistenceRepresentation: [String: PlistValue] {
		return self.plist.persistenceRepresentation
	}

	public subscript<T: PlistConvertable>(key: ModelPlistKey) -> T? {
		get throws {
			guard let rawValue = self.plist[key] else {
				return nil
			}
			do {
				return try T.fromPlistValue(rawValue)
			} catch {
				throw ModelObjectUpdateErrors.invalidAttributeType(key.rawValue)
			}
		}
	}

	public subscript<T: PlistConvertable>(key: ModelPlistKey, default default: T) -> T {
		get throws {
			guard let rawValue = self.plist[key] else {
				return `default`
			}
			do {
				return try T.fromPlistValue(rawValue)
			} catch {
				throw ModelObjectUpdateErrors.invalidAttributeType(key.rawValue)
			}
		}
	}

	public subscript<T: PlistConvertable>(required key: ModelPlistKey) -> T {
		get throws {
			guard let rawValue = self.plist[key] else {
				throw ModelObjectUpdateErrors.attributeNotFound(key.rawValue)
			}
			do {
				return try T.fromPlistValue(rawValue)
			} catch {
				throw ModelObjectUpdateErrors.invalidAttributeType(key.rawValue)
			}
		}
	}

	func applyingModelFiles(from fileWrappers: [String: FileWrapper], to keys: [ModelPlistKey]) throws -> Self {
		var updatedPlist = self.plist

		for plistKey in keys {
			guard var rawModelFile = updatedPlist[plistKey] as? [String: PlistValue] else {
				continue
			}
			if let filename = rawModelFile["filename"] as? String {
				rawModelFile["data"] = fileWrappers[filename]?.regularFileContents
			}
			let modelFile: ModelFile = try .fromPlistValue(rawModelFile as PlistValue)
			updatedPlist[plistKey] = modelFile
		}
		return ModelObjectPlistRepresentation(id: self.id, plist: updatedPlist)
	}

	func convertModelFiles(from keys: [ModelPlistKey]) throws -> (Self, [ModelFile]) {
		var updatedPlist = self.plist
		var modelFiles: [ModelFile] = []

		for modelFileKey in keys {
			guard let modelFile: ModelFile = try self[modelFileKey] else {
				continue
			}
			updatedPlist[modelFileKey] = try modelFile.toPlistValue()
			modelFiles.append(modelFile)
		}
		return (ModelObjectPlistRepresentation(id: self.id, plist: updatedPlist), modelFiles)
	}
}


extension Dictionary where Key == ModelPlistKey, Value == PlistValue {
	public var persistenceRepresentation: [String: PlistValue] {
		var stringKeys = [String: PlistValue]()
		for (key, value) in self {
			stringKeys[key.rawValue] = value
		}
		return stringKeys
	}
}
