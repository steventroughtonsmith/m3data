//
//  ModelPlist.swift
//  M3Data
//
//  Created by Martin Pilkington on 24/07/2022.
//

import Foundation

class ModelPlist {
    class var version: Int {
        preconditionFailure("Implement in subclass")
    }

    class var supportedModelTypes: [ModelType] {
        preconditionFailure("Implement in subclass")
    }

    convenience init(plist: [String: Any]) throws {
        let version = (plist["version"] as? Int) ?? 1
        guard version == Self.version else {
            throw Errors.invalidVersion(received: version, expected: Self.version)
        }

        self.init()

        self.settings = (plist["settings"] as? [String: Any]) ?? [:]

        for modelType in Self.supportedModelTypes {
            guard let modelPlists = plist[modelType.persistenceName] as? [[String: Any]] else {
                throw Errors.missingCollection(modelType.persistenceName)
            }

            let plistRepresentation = modelPlists.map(\.toModelPlistRepresentation)
            try self.setPlistRepresentations(plistRepresentation, for: modelType)
        }
    }

    init() {
        var dictionary: [ModelType: [[ModelPlistKey: Any]]] = [:]
        for supportedType in Self.supportedModelTypes {
            dictionary[supportedType] = []
        }
        self.plistRepresentations = dictionary
    }


    //MARK: - Plist Generation
    var plist: [String: Any] {
        var plist = [String: Any]()
        plist["version"] = Self.version
        plist["settings"] = self.settings
        for modelType in Self.supportedModelTypes {
            plist[modelType.persistenceName] = self.plistRepresentations(of: modelType).map(\.toPersistanceRepresentation).sorted {
                return ($0["id"] as? String ?? "") < ($1["id"] as? String ?? "")
            }
        }
        return plist
    }


    //MARK: - Data Access
    var settings: [String: Any] = [:]

    private var plistRepresentations: [ModelType: [[ModelPlistKey: Any]]]
    func plistRepresentations(of modelType: ModelType) -> [[ModelPlistKey: Any]] {
        return self.plistRepresentations[modelType] ?? []
    }

    func setPlistRepresentations(_ representations: [[ModelPlistKey: Any]], for modelType: ModelType) throws {
        guard Self.supportedModelTypes.contains(modelType) else {
            throw Errors.invalidCollection(modelType.rawValue)
        }
        self.plistRepresentations[modelType] = representations
    }

    //MARK: - Migration
    func migrateToNextVersion() throws -> [String: Any] {
        preconditionFailure("Implement in subclass")
    }
}

extension ModelPlist {
    enum Errors: Error, Equatable {
        case invalidVersion(received: Int, expected: Int)
        case missingCollection(String)
        case invalidCollection(String)
    }
}

extension Dictionary where Key == String, Value == Any {
    var toModelPlistRepresentation: [ModelPlistKey: Any] {
        var modelPlistKeys = [ModelPlistKey: Any]()
        for (key, value) in self {
            let plistKey = ModelPlistKey(rawValue: key)!
            if (plistKey == .id), let rawModelID = value as? String, let modelID = ModelID(string: rawModelID) {
                modelPlistKeys[plistKey] = modelID
            } else {
                modelPlistKeys[plistKey] = value
            }
        }
        return modelPlistKeys
    }
}

extension Dictionary where Key == ModelPlistKey, Value == Any {
    var toPersistanceRepresentation: [String: Any] {
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
}

