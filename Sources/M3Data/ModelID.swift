//
//  ModelID.swift
//  Coppice
//
//  Created by Martin Pilkington on 01/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

/// Used for determining model type
public struct ModelType: RawRepresentable, Equatable, Hashable {
    public typealias RawValue = String

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}


public struct ModelID: Equatable, Hashable {
    public let modelType: ModelType
    public let uuid: UUID

    public init(modelType: ModelType, uuid: UUID = UUID()) {
        self.modelType = modelType
        self.uuid = uuid
    }

    public init?(modelType: ModelType, uuidString: String) {
        guard let uuid = UUID(uuidString: uuidString) else {
            return nil
        }
        self.init(modelType: modelType, uuid: uuid)
    }
}


//MARK: - PlistConversion
extension ModelID: PlistConvertable {
	public func toPlistValue() throws -> PlistValue {
		return self.stringRepresentation
	}

	public static func fromPlistValue(_ plistValue: PlistValue) throws -> ModelID {
		guard
			let value = plistValue as? String,
			let modelID = ModelID(string: value)
		else {
			throw PlistConvertableError.invalidConversionFromPlistValue
		}
		return modelID
	}
}

//MARK: - String representation
extension ModelID {
    public var stringRepresentation: String {
        return "\(self.modelType.rawValue)_\(self.uuid.uuidString)"
    }

    public init?(string: String) {
        let components = string.split(separator: "_")
        guard components.count == 2 else {
            return nil
        }
        self.init(modelType: ModelType(rawValue: String(components[0])), uuidString: String(components[1]))
    }
}
