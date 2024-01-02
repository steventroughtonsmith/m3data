//
//  PlistConvertable+Foundation.swift
//  M3Data
//
//  Created by Martin Pilkington on 27/12/2023.
//

import Foundation

extension Array where Element == PlistConvertable {
	public func toPlistValue() throws -> PlistValue {
		throw PlistConvertableError.attemptedToConvertNonHomogeneousCollection
	}

	static public func fromPlistValue(_ plistValue: PlistValue) throws -> Array<PlistConvertable> {
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
			throw PlistConvertableError.invalidConversionFromPlistValue
		}
		return try array.map { try .fromPlistValue($0) }
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

extension Dictionary: PlistConvertable where Value: PlistConvertable {
	public func toPlistValue() throws -> PlistValue {
		return try self.mapValues { try $0.toPlistValue() } as PlistValue
	}

	public static func fromPlistValue(_ plistValue: PlistValue) throws -> [Key: Value] {
		guard let dictionary = plistValue as? [Key: PlistValue] else {
			throw PlistConvertableError.invalidConversionFromPlistValue
		}

		return try dictionary.mapValues { try .fromPlistValue($0) }
	}
}

extension URL: PlistConvertable {
	public static func fromPlistValue(_ plistValue: PlistValue) throws -> URL {
		guard
			let value = plistValue as? String,
			let url = URL(string: value)
		else {
			throw PlistConvertableError.invalidConversionFromPlistValue
		}
		return url
	}

	public func toPlistValue() throws -> PlistValue {
		return self.absoluteString
	}
}

extension CGRect: PlistConvertable {
	public func toPlistValue() throws -> PlistValue {
		return NSStringFromRect(self)
	}
	
	public static func fromPlistValue(_ plistValue: PlistValue) throws -> CGRect {
		guard let value = plistValue as? String else {
			throw PlistConvertableError.invalidConversionFromPlistValue
		}
		return NSRectFromString(value)
	}
}

extension CGPoint: PlistConvertable {
	public func toPlistValue() throws -> PlistValue {
		return NSStringFromPoint(self)
	}
	
	public static func fromPlistValue(_ plistValue: PlistValue) throws -> CGPoint {
		guard let value = plistValue as? String else {
			throw PlistConvertableError.invalidConversionFromPlistValue
		}
		return NSPointFromString(value)
	}
}

extension CGSize: PlistConvertable {
	public func toPlistValue() throws -> PlistValue {
		return NSStringFromSize(self)
	}

	public static func fromPlistValue(_ plistValue: PlistValue) throws -> CGSize {
		guard let value = plistValue as? String else {
			throw PlistConvertableError.invalidConversionFromPlistValue
		}
		return NSSizeFromString(value)
	}
}
