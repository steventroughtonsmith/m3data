//
//  ModelPlist.swift
//  M3Data
//
//  Created by Martin Pilkington on 24/07/2022.
//

import Foundation

open class ModelPlist {
    open class var version: Int {
        preconditionFailure("Implement in subclass")
    }

    public struct PersistenceTypes {
        public let modelType: ModelType
        public let persistenceName: String

        public init(modelType: ModelType, persistenceName: String) {
            self.modelType = modelType
            self.persistenceName = persistenceName
        }
    }

    open class var supportedTypes: [PersistenceTypes] {
        preconditionFailure("Implement in subclass")
    }

    required public convenience init(plist: [String: PlistValue]) throws {
        let version = (plist["version"] as? Int) ?? 1
        guard version == Self.version else {
            throw Errors.invalidVersion(received: version, expected: Self.version)
        }

        self.init()

        self.settings = (plist["settings"] as? [String: Any]) ?? [:]

        for persistenceTypes in Self.supportedTypes {
			guard
				let modelPlists = plist[persistenceTypes.persistenceName] as? [[String: Any]]
			else {
                throw Errors.missingCollection(persistenceTypes.persistenceName)
            }

			let typedModelPlists = modelPlists.map { $0.mapValues({
				guard let plistValue = $0 as? PlistValue else {
					return "" as PlistValue
				}
				return plistValue
			})}

            let plistRepresentation = try typedModelPlists.map { try ModelObjectPlistRepresentation(persistenceRepresentation: $0) }
            try self.setPlistRepresentations(plistRepresentation, for: persistenceTypes.modelType)
        }
    }

    required public init() {
        var dictionary: [ModelType: [ModelObjectPlistRepresentation]] = [:]
        for supportedType in Self.supportedTypes {
            dictionary[supportedType.modelType] = []
        }
        self.plistRepresentations = dictionary
    }


    //MARK: - Plist Generation
    public var plist: [String: PlistValue] {
        var plist = [String: PlistValue]()
        plist["version"] = Self.version
        plist["settings"] = self.settings as PlistValue
        for supportedType in Self.supportedTypes {
            plist[supportedType.persistenceName] = self.plistRepresentations(of: supportedType.modelType).map(\.persistenceRepresentation).sorted {
                return ($0["id"] as? String ?? "") < ($1["id"] as? String ?? "")
			} as PlistValue
        }
        return plist
    }


    //MARK: - Data Access
    public var settings: [String: Any] = [:]

    private var plistRepresentations: [ModelType: [ModelObjectPlistRepresentation]]
    public func plistRepresentations(of modelType: ModelType) -> [ModelObjectPlistRepresentation] {
        return self.plistRepresentations[modelType] ?? []
    }

    func setPlistRepresentations(_ representations: [ModelObjectPlistRepresentation], for modelType: ModelType) throws {
        guard Self.supportedTypes.contains(where: { $0.modelType == modelType }) else {
            throw Errors.invalidCollection(modelType.rawValue)
        }
        self.plistRepresentations[modelType] = representations
    }


    //MARK: - Migration
    open func migrateToNextVersion() throws -> [String: PlistValue] {
        preconditionFailure("Implement in subclass")
    }
}

extension ModelPlist {
    public enum Errors: Error {
        case invalidVersion(received: Int, expected: Int)
        case missingCollection(String)
        case invalidCollection(String)
        case missingID([String: Any])
        case migrationNotAvailable
        case migrationFailed(String)
    }
}

extension Dictionary where Key == ModelPlistKey, Value == Any {
    public func attribute<T>(withKey key: ModelPlistKey) -> T? {
        return self[key] as? T
    }

    public func requiredAttribute<T>(withKey key: ModelPlistKey) throws -> T {
        guard let value: T = self.attribute(withKey: key) else {
            throw ModelObjectUpdateErrors.attributeNotFound(key.rawValue)
        }
        return value
    }
}
