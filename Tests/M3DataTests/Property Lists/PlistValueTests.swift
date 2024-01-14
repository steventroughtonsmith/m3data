//
//  PlistValueTests.swift
//  M3Data
//
//  Created by Martin Pilkington on 28/12/2023.
//

import XCTest
import M3Data

final class PlistValueTests: XCTestCase {
	func test_toPlistValue_returnsSelf() throws {
		XCTAssertEqual(try "Hello".toPlistValue() as? String, "Hello")
		XCTAssertEqual(try 42.toPlistValue() as? Int, 42)
		XCTAssertEqual(try (3.14).toPlistValue() as? Double, 3.14)
		XCTAssertEqual(try (13.37 as Float).toPlistValue() as? Float, 13.37)
		XCTAssertEqual(try false.toPlistValue() as? Bool, false)
		let date = Date()
		XCTAssertEqual(try date.toPlistValue() as? Date, date)
		let data = try XCTUnwrap("Some Data".data(using: .utf8))
		XCTAssertEqual(try data.toPlistValue() as? Data, data)
		XCTAssertEqual(try ["foo", "bar"].toPlistValue() as? [String], ["foo", "bar"])
		XCTAssertEqual(try ["foo": "bar"].toPlistValue() as? [String: String], ["foo": "bar"])
	}

	func test_fromPlistValue_throwsIfValueNotOwnType() throws {
		XCTAssertThrowsError(try String.fromPlistValue(42)) { error in
			XCTAssertEqual(error as? PlistConvertableError, .invalidConversion(fromPlistValue: 42, to: ""))
		}
		XCTAssertThrowsError(try Int.fromPlistValue(4.2)) { error in
			XCTAssertEqual(error as? PlistConvertableError, .invalidConversion(fromPlistValue: 4.2, to: ""))
		}
		XCTAssertThrowsError(try Float.fromPlistValue("Test")) { error in
			XCTAssertEqual(error as? PlistConvertableError, .invalidConversion(fromPlistValue: "Test", to: ""))
		}
		XCTAssertThrowsError(try Double.fromPlistValue("Test")) { error in
			XCTAssertEqual(error as? PlistConvertableError, .invalidConversion(fromPlistValue: "Test", to: ""))
		}
		XCTAssertThrowsError(try Bool.fromPlistValue(10)) { error in
			XCTAssertEqual(error as? PlistConvertableError, .invalidConversion(fromPlistValue: 10, to: ""))
		}
		XCTAssertThrowsError(try Date.fromPlistValue(42)) { error in
			XCTAssertEqual(error as? PlistConvertableError, .invalidConversion(fromPlistValue: 42, to: ""))
		}
		XCTAssertThrowsError(try Data.fromPlistValue(42)) { error in
			XCTAssertEqual(error as? PlistConvertableError, .invalidConversion(fromPlistValue: 42, to: ""))
		}
		XCTAssertThrowsError(try [String].fromPlistValue(42)) { error in
			XCTAssertEqual(error as? PlistConvertableError, .invalidConversion(fromPlistValue: 42, to: ""))
		}
//		XCTAssertThrowsError(try [String: PlistValue].fromPlistValue(42)) { error in
//			XCTAssertEqual(error as? PlistConvertableError, .invalidConversionFromPlistValue)
//		}
	}
}
