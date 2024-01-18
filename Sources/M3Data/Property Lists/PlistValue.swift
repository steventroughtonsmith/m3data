//
//  PlistValue.swift
//  M3Data
//
//  Created by Martin Pilkington on 27/12/2023.
//

import Foundation

public protocol PlistValue {}

extension String: PlistValue {}
extension Int: PlistValue {}
extension Float: PlistValue {}
extension Double: PlistValue {}
extension Bool: PlistValue {}
extension Date: PlistValue {}
extension Data: PlistValue {}
extension Array: PlistValue where Element: PlistValue {}
extension Dictionary: PlistValue where Key == String, Value: PlistValue {}

//We need NS values too
extension NSNumber: PlistValue {}
extension NSDictionary: PlistValue {}
extension NSArray: PlistValue {}
extension NSString: PlistValue {}
extension NSData: PlistValue {}
extension NSDate: PlistValue {}


public func PlistValueFrom(_ value: Any) -> PlistValue? {
	if let string = value as? String {
		return string
	}
	if let bool = value as? Bool {
		return bool
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
	if let date = value as? Date {
		return date
	}
	if let data = value as? Data {
		return data
	}
	if let array = value as? [Any] {
		var plistArray = [PlistValue]()
		for arrayValue in array {
			guard let plistValue = PlistValueFrom(arrayValue) else {
				return nil
			}
			plistArray.append(plistValue)
		}
		return plistArray as PlistValue
	}
	if let dictionary = value as? [String: Any] {
		var plistDict = [String: PlistValue]()
		for (key, dictValue) in dictionary {
			guard let plistValue = PlistValueFrom(dictValue) else {
				return nil
			}
			plistDict[key] = plistValue
		}
		return plistDict as PlistValue
	}
	return nil
}
