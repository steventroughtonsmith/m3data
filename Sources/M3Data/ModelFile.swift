//
//  ModelFile.swift
//  M3Data
//
//  Created by Martin Pilkington on 27/12/2023.
//

import Foundation

public struct ModelFile {
	public let type: String
	public let filename: String?
	public let data: Data?
	public let metadata: [String: Any]?

	public init(type: String, filename: String?, data: Data?, metadata: [String: Any]?) {
		self.type = type
		self.filename = filename
		self.data = data
		self.metadata = metadata
	}
}

extension ModelFile: PlistValue {
	public func toPlistValue() throws -> PlistValue {
		var plist: [String: Any] = ["type": self.type]
		if let filename = self.filename {
			plist["filename"] = filename
		}
		if let metadata = self.metadata {
			plist["metadata"] = metadata
		}
		return plist as PlistValue
	}

	public static func fromPlistValue(_ plistValue: PlistValue) throws -> ModelFile {
		if let modelFile = plistValue as? ModelFile {
			return modelFile
		}

		guard
			let modelFileDict = plistValue as? [String: Any],
			let type = modelFileDict["type"] as? String
		else {
			throw PlistConvertableError.invalidConversionFromPlistValue
		}

		return ModelFile(type: type,
						 filename: modelFileDict["filename"] as? String,
						 data: modelFileDict["data"] as? Data,
						 metadata: modelFileDict["metadata"] as? [String: Any])
	}
}
