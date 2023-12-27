//
//  PlistConvertable+Foundation.swift
//  M3Data
//
//  Created by Martin Pilkington on 27/12/2023.
//

import Foundation

extension Array where Element: PlistConvertable {
	func toPlistValue() throws -> PlistValue {
		return try self.map { try $0.toPlistValue() }
	}

	static func fromPlistValue(_ plistValue: PlistValue) throws -> [Element] {
		let array = plistValue as? [PlistValue]
		guard let array else {
			throw PlistConvertableError.invalidConversionFromPlistValue
		}
		return try array.map { try .fromPlistValue($0) }
	}
}

extension Dictionary where Key == String, Value: PlistConvertable {
	func toPlistValue() throws -> PlistValue {
		return try self.mapValues { try $0.toPlistValue() }
	}

	static func fromPlistValue(_ plistValue: PlistValue) throws -> [String: Value] {
		guard let dictionary = plistValue as? [String: PlistValue] else {
			throw PlistConvertableError.invalidConversionFromPlistValue
		}

		return try dictionary.mapValues { try .fromPlistValue($0) }
	}
}

extension URL: PlistConvertable {
	static func fromPlistValue(_ plistValue: PlistValue) throws -> URL {
		guard
			let value = plistValue as? String,
			let url = URL(string: value)
		else {
			throw PlistConvertableError.invalidConversionFromPlistValue
		}
		return url
	}

	func toPlistValue() throws -> PlistValue {
		return self.absoluteString
	}
}
