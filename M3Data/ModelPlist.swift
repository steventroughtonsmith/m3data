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

    public required convenience init(plist: [String: Any]) throws {
        let version = (plist["version"] as? Int) ?? 1
        guard version == Self.version else {
            throw Errors.invalidVersion(received: version, expected: Self.version)
        }

        self.init()

        self.settings = (plist["settings"] as? [String: Any]) ?? [:]

        for persistenceTypes in Self.supportedTypes {
            guard let modelPlists = plist[persistenceTypes.persistenceName] as? [[String: Any]] else {
                throw Errors.missingCollection(persistenceTypes.persistenceName)
            }

            let plistRepresentation = try modelPlists.map { try $0.toModelPlistRepresentation }
            try self.setPlistRepresentations(plistRepresentation, for: persistenceTypes.modelType)
        }
    }

    public required init() {
        var dictionary: [ModelType: [[ModelPlistKey: Any]]] = [:]
        for supportedType in Self.supportedTypes {
            dictionary[supportedType.modelType] = []
        }
        self.plistRepresentations = dictionary
    }


    //MARK: - Plist Generation
    public var plist: [String: Any] {
        var plist = [String: Any]()
        plist["version"] = Self.version
        plist["settings"] = self.settings
        for supportedType in Self.supportedTypes {
            plist[supportedType.persistenceName] = self.plistRepresentations(of: supportedType.modelType).map(\.toPersistanceRepresentation).sorted {
                return ($0["id"] as? String ?? "") < ($1["id"] as? String ?? "")
            }
        }
        return plist
    }


    //MARK: - Data Access
    public var settings: [String: Any] = [:]

    private var plistRepresentations: [ModelType: [[ModelPlistKey: Any]]]
    public func plistRepresentations(of modelType: ModelType) -> [[ModelPlistKey: Any]] {
        return self.plistRepresentations[modelType] ?? []
    }

    func setPlistRepresentations(_ representations: [[ModelPlistKey: Any]], for modelType: ModelType) throws {
        guard Self.supportedTypes.contains(where: { $0.modelType == modelType }) else {
            throw Errors.invalidCollection(modelType.rawValue)
        }
        self.plistRepresentations[modelType] = representations
    }

    //MARK: - Migration
    open func migrateToNextVersion() throws -> [String: Any] {
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

extension Dictionary where Key == String, Value == Any {
    var toModelPlistRepresentation: [ModelPlistKey: Any] {
        get throws {
            var modelPlistKeys = [ModelPlistKey: Any]()
            for (key, value) in self {
                let plistKey = ModelPlistKey(rawValue: key)!
                if (plistKey == .id), let rawModelID = value as? String, let modelID = ModelID(string: rawModelID) {
                    modelPlistKeys[plistKey] = modelID
                } else {
                    modelPlistKeys[plistKey] = value
                }
            }
            guard modelPlistKeys[.id] != nil else {
                throw ModelPlist.Errors.missingID(self)
            }
            return modelPlistKeys
        }
    }
}

extension Dictionary where Key == ModelPlistKey, Value == Any {
    public var toPersistanceRepresentation: [String: Any] {
        var stringKeys = [String: Any]()
        for (key, value) in self {
            if (key == .id), let modelID = value as? ModelID {
                stringKeys[key.rawValue] = modelID.stringRepresentation
            } else {
                stringKeys[key.rawValue] = value
            }
        }
        return stringKeys
    }

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

