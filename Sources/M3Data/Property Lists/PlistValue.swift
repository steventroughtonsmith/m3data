//
//  PlistValue.swift
//  M3Data
//
//  Created by Martin Pilkington on 27/12/2023.
//

import Foundation

protocol PlistValue: PlistConvertable {}

extension PlistValue {
	func toPlistValue() throws -> PlistValue {
		return self
	}

	static func fromPlistValue(_ plistValue: PlistValue) throws -> Self {
		guard let value = plistValue as? Self else {
			throw PlistConvertableError.invalidConversionFromPlistValue
		}
		return value
	}
}

extension String: PlistValue {}
extension Int: PlistValue {}
extension Float: PlistValue {}
extension Double: PlistValue {}
extension Bool: PlistValue {}
extension Date: PlistValue {}
extension Data: PlistValue {}
extension Array: PlistValue {}
extension Dictionary: PlistValue {}
