//
//  PlistConvertable+CoreGraphics.swift
//  M3Data
//
//  Created by Martin Pilkington on 07/01/2024.
//

import Foundation

extension CGRect: PlistConvertable {
	public func toPlistValue() throws -> PlistValue {
		return NSStringFromRect(self)
	}

	public static func fromPlistValue(_ plistValue: PlistValue) throws -> CGRect {
		guard let value = plistValue as? String else {
			throw PlistConvertableError.invalidConversion(fromPlistValue: plistValue, to: self)
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
			throw PlistConvertableError.invalidConversion(fromPlistValue: plistValue, to: self)
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
			throw PlistConvertableError.invalidConversion(fromPlistValue: plistValue, to: self)
		}
		return NSSizeFromString(value)
	}
}
