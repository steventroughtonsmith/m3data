//
//  PlistConvertable+FoundationCollection.swift
//  M3Data
//
//  Created by Martin Pilkington on 07/01/2024.
//

import Foundation

extension Array where Element == PlistConvertable {
	public func toPlistValue() throws -> PlistValue {
		throw PlistConvertableError.attemptedToConvertNonHomogeneousCollection
	}

	static public func fromPlistValue(_ plistValue: PlistValue) throws -> Array<PlistConvertable> {
		print("array conversion")
		throw PlistConvertableError.attemptedToConvertNonHomogeneousCollection
	}
}

extension Array: PlistConvertable where Element: PlistConvertable {
	public func toPlistValue() throws -> PlistValue {
		return try self.map { try $0.toPlistValue() } as PlistValue
	}

	public static func fromPlistValue(_ plistValue: PlistValue) throws -> [Element] {
		let array = plistValue as? [PlistValue]
		guard let array else {
			throw PlistConvertableError.invalidConversion(fromPlistValue: plistValue, to: self)
		}
		return try array.map { try .fromPlistValue($0) }
	}
}

extension NSArray {
	public func toPlistValue() throws -> PlistValue {
		return try self.map {
			guard let plistConvertable = $0 as? PlistConvertable else {
				throw PlistConvertableError.invalidConversionToPlistValue
			}
			return try plistConvertable.toPlistValue()
		} as PlistValue
	}

	public static func fromPlistValue(_ plistValue: PlistValue) throws -> Self {
		let array = plistValue as? [PlistValue]
		guard let array else {
			throw PlistConvertableError.invalidConversion(fromPlistValue: plistValue, to: self)
		}
		return array as NSArray as! Self
	}
}

extension Dictionary where Value == PlistConvertable {
	public func toPlistValue() throws -> PlistValue {
		throw PlistConvertableError.attemptedToConvertNonHomogeneousCollection
	}

	static public func fromPlistValue(_ plistValue: PlistValue) throws -> Array<PlistConvertable> {
		throw PlistConvertableError.attemptedToConvertNonHomogeneousCollection
	}
}

extension Dictionary: PlistConvertable where Key == String, Value: PlistConvertable {
	public func toPlistValue() throws -> PlistValue {
		return try self.mapValues { try $0.toPlistValue() } as PlistValue
	}

	public static func fromPlistValue(_ plistValue: PlistValue) throws -> [String: Value] {
		guard let dictionary = plistValue as? [String: PlistValue] else {
			throw PlistConvertableError.invalidConversion(fromPlistValue: plistValue, to: self)
		}

		return try dictionary.mapValues { try .fromPlistValue($0) }
	}
}

extension NSDictionary {
	public func toPlistValue() throws -> PlistValue {
		var newDictionary: [String: PlistValue] = [:]
		for (key, value) in self {
			guard
				let typedKey = key as? String,
				let plistValue = value as? PlistConvertable else {
				throw PlistConvertableError.invalidConversionToPlistValue
			}
			newDictionary[typedKey] = try plistValue.toPlistValue()
		}

		return newDictionary as PlistValue
	}

	public static func fromPlistValue(_ plistValue: PlistValue) throws -> Self {
		guard let dictionary = plistValue as? [String: PlistValue] else {
			throw PlistConvertableError.invalidConversion(fromPlistValue: plistValue, to: self)
		}

		return dictionary as NSDictionary as! Self
	}
}
