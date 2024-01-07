//
//  PlistConvertable.swift
//  M3Data
//
//  Created by Martin Pilkington on 27/12/2023.
//

import Foundation

public protocol PlistConvertable {
	func toPlistValue() throws -> PlistValue

	static func fromPlistValue(_ plistValue: PlistValue) throws -> Self
}

public enum PlistConvertableError: Error {
	case invalidConversion(fromPlistValue: PlistValue, to: Any)
	case invalidConversionToPlistValue
	case attemptedToConvertNonHomogeneousCollection
}
