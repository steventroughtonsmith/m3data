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
