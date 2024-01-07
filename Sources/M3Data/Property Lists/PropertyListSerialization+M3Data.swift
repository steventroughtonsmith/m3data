//
//  PropertyListSerialization+M3Data.swift
//  M3Data
//
//  Created by Martin Pilkington on 05/01/2024.
//

import Foundation

extension PropertyListSerialization {
	static func propertyListValue(from data: Data) throws -> PlistValue {
		let rawPlist = try self.propertyList(from: data, options: .mutableContainers, format: nil)

		return try self.convert(value: rawPlist)
	}

	private static func convert(value: Any) throws -> PlistValue {
		if let string = value as? String {
			return string
		}
		if let int = value as? Int {
			return int
		}
		if let float = value as? Float {
			return float
		}
		if let double = value as? Double {
			return double
		}
		if let bool = value as? Bool {
			return bool
		}
		if let date = value as? Date {
			return date
		}
		if let data = value as? Data {
			return data
		}
		if let array = value as? [Any] {
			return try array.map { try self.convert(value: $0) } as PlistValue
		}
		if let dictionary = value as? [String: Any] {
			return try dictionary.mapValues { try self.convert(value: $0) } as PlistValue
		}

		throw PlistConvertableError.invalidConversionToPlistValue
	}
}
