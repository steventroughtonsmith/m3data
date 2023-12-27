//
//  File.swift
//  
//
//  Created by Martin Pilkington on 27/12/2023.
//

import Foundation

//ModelFile, PageLink, URL, ModelID, EntryPoint, PageRef, LinkRef
protocol PlistConvertable {
	func toPlistValue() -> Any?
}

protocol PlistValue: PlistConvertable {}

extension PlistValue {
	func toPlistValue() -> Any? {
		return self
	}
}


extension String: PlistValue {}
extension Int: PlistValue {}
extension Float: PlistValue {}
extension Double: PlistValue {}
extension Bool: PlistValue {}
extension Date: PlistValue {}
extension Data: PlistValue {}

//Handle differently
extension Array: PlistValue {}
extension Dictionary: PlistValue {}
