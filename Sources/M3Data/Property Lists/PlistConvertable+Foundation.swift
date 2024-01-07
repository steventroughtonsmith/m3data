//
//  PlistConvertable+Foundation.swift
//  M3Data
//
//  Created by Martin Pilkington on 27/12/2023.
//

import Foundation

extension String: PlistConvertable {
	public func toPlistValue() throws -> PlistValue {
		return self
	}

	public static func fromPlistValue(_ plistValue: PlistValue) throws -> Self {
		guard let value = plistValue as? Self else {
			throw PlistConvertableError.invalidConversion(fromPlistValue: plistValue, to: self)
		}
		return value
	}
}

extension Int: PlistConvertable {
	public func toPlistValue() throws -> PlistValue {
		return self
	}

	public static func fromPlistValue(_ plistValue: PlistValue) throws -> Self {
		guard let value = plistValue as? Self else {
			throw PlistConvertableError.invalidConversion(fromPlistValue: plistValue, to: self)
		}
		return value
	}
}

extension Float: PlistConvertable {
	public func toPlistValue() throws -> PlistValue {
		return self
	}

	public static func fromPlistValue(_ plistValue: PlistValue) throws -> Self {
		if let value = plistValue as? Self {
			return value
		}
		if let value = plistValue as? Int {
			return Float(value)
		}
		throw PlistConvertableError.invalidConversion(fromPlistValue: plistValue, to: self)
	}
}

extension Double: PlistConvertable {
	public func toPlistValue() throws -> PlistValue {
		return self
	}

	public static func fromPlistValue(_ plistValue: PlistValue) throws -> Self {
		if let value = plistValue as? Self {
			return value
		}
		if let value = plistValue as? Int {
			return Double(value)
		}
		throw PlistConvertableError.invalidConversion(fromPlistValue: plistValue, to: self)
	}
}

extension Bool: PlistConvertable {
	public func toPlistValue() throws -> PlistValue {
		return self
	}

	public static func fromPlistValue(_ plistValue: PlistValue) throws -> Self {
		if let value = plistValue as? Self {
			return value
		}
		if let value = plistValue as? Int {
			return value != 0
		}
		throw PlistConvertableError.invalidConversion(fromPlistValue: plistValue, to: self)
	}
}

extension Date: PlistConvertable {
	public func toPlistValue() throws -> PlistValue {
		return self
	}

	public static func fromPlistValue(_ plistValue: PlistValue) throws -> Self {
		guard let value = plistValue as? Self else {
			throw PlistConvertableError.invalidConversion(fromPlistValue: plistValue, to: self)
		}
		return value
	}
}

extension Data: PlistConvertable {
	public func toPlistValue() throws -> PlistValue {
		return self
	}

	public static func fromPlistValue(_ plistValue: PlistValue) throws -> Self {
		guard let value = plistValue as? Self else {
			throw PlistConvertableError.invalidConversion(fromPlistValue: plistValue, to: self)
		}
		return value
	}
}

extension URL: PlistConvertable {
	public static func fromPlistValue(_ plistValue: PlistValue) throws -> URL {
		guard
			let value = plistValue as? String,
			let url = URL(string: value)
		else {
			throw PlistConvertableError.invalidConversion(fromPlistValue: plistValue, to: self)
		}
		return url
	}

	public func toPlistValue() throws -> PlistValue {
		return self.absoluteString
	}
}
