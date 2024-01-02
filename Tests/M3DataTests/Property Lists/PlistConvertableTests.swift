//
//  PlistConvertableTests.swift
//  M3Data
//
//  Created by Martin Pilkington on 28/12/2023.
//

import XCTest
import M3Data

final class PlistConvertableTests: XCTestCase {
	//MARK: - Array
	func test_array_toPlistValue_convertsAllValuesToPlistValue() throws {
		let array = [URL(string: "https://mcubedsw.com")!, URL(string: "https://apple.com")!]
		let convertedArray = try XCTUnwrap(array.toPlistValue() as? [Any])
		XCTAssertEqual(convertedArray[0] as? String, "https://mcubedsw.com")
		XCTAssertEqual(convertedArray[1] as? String, "https://apple.com")
	}

	func test_array_toPlistValue_throwsErrorIfNotHomogeneous() throws {
		let array: [PlistConvertable] = ["hello", 42]
		XCTAssertThrowsError(try array.toPlistValue()) { error in
			XCTAssertEqual(error as? PlistConvertableError, .attemptedToConvertNonHomogeneousCollection)
		}
	}

	func test_array_fromPlistValue_throwsErrorIfValueNotArray() throws {
		XCTAssertThrowsError(try [String].fromPlistValue("test")) { error in
			XCTAssertEqual(error as? PlistConvertableError, .invalidConversionFromPlistValue)
		}
	}

	func test_array_fromPlistValue_throwsErrorIfNotHomogeneous() throws {
		XCTAssertThrowsError(try [PlistConvertable].fromPlistValue(["hello", 42] as PlistValue)) { error in
			XCTAssertEqual(error as? PlistConvertableError, .attemptedToConvertNonHomogeneousCollection)
		}
	}

	func test_array_fromPlistValue_returnsConvertedArray() throws {
		let plistValue: [URL] = try .fromPlistValue(["https://mcubedsw.com", "https://apple.com"])
		XCTAssertEqual(plistValue, [
			URL(string: "https://mcubedsw.com")!,
			URL(string: "https://apple.com")!
		])
	}

	//MARK: - Dictionary
	func test_dictionary_toPlistValue_convertsAllValuesToPlistValue() throws {
		let dictionary = [
			"foo": URL(string: "https://apple.com")!,
			"baz": URL(string: "https://mcubedsw.com")!
		]

		let convertedDictionary = try XCTUnwrap(try dictionary.toPlistValue() as? [String: PlistValue])
		XCTAssertEqual(convertedDictionary["foo"] as? String, "https://apple.com")
		XCTAssertEqual(convertedDictionary["baz"] as? String, "https://mcubedsw.com")
	}

	func test_dictionary_toPlistValue_throwsErrorIfNotHomogeneous() throws {
		let dictionary: [String: PlistConvertable] = ["foo": "hello", "bar": 42]
		XCTAssertThrowsError(try dictionary.toPlistValue()) { error in
			XCTAssertEqual(error as? PlistConvertableError, .attemptedToConvertNonHomogeneousCollection)
		}
	}

	func test_dictionary_fromPlistValue_throwsErrorIfValueNotDictionary() throws {
		XCTAssertThrowsError(try [String: URL].fromPlistValue("test")) { error in
			XCTAssertEqual(error as? PlistConvertableError, .invalidConversionFromPlistValue)
		}
	}

	func test_dictionary_fromPlistValue_throwsErrorIfNotHomogeneous() throws {
		XCTAssertThrowsError(try [String: PlistConvertable].fromPlistValue(["foo": "hello", "bar": 42] as PlistValue)) { error in
			XCTAssertEqual(error as? PlistConvertableError, .attemptedToConvertNonHomogeneousCollection)
		}
	}

	func test_dictionary_fromPlistValue_returnsConvertedDictionary() throws {
		let plistValue: [String: URL] = try .fromPlistValue(["foo": "https://mcubedsw.com", "bar": "https://apple.com"])
		XCTAssertEqual(plistValue, [
			"foo": URL(string: "https://mcubedsw.com")!,
			"bar": URL(string: "https://apple.com")!
		])
	}

	//MARK: - URL
	func test_url_toPlistValue_convertsToString() throws {
		let urlString = try URL(string: "https://mcubedsw.com/coppice")!.toPlistValue()
		XCTAssertEqual(urlString as? String, "https://mcubedsw.com/coppice")
	}

	func test_url_fromPlistValue_throwsIfValueNotString() throws {
		XCTAssertThrowsError(try URL.fromPlistValue(42)) { error in
			XCTAssertEqual(error as? PlistConvertableError, .invalidConversionFromPlistValue)
		}
	}

	func test_url_fromPlistValue_throwsIfStringNotValidURL() throws {
		XCTAssertThrowsError(try URL.fromPlistValue("")) { error in
			XCTAssertEqual(error as? PlistConvertableError, .invalidConversionFromPlistValue)
		}
	}

	func test_url_fromPlistValue_returnsURL() throws {
		let url = try URL.fromPlistValue("https://mcubedsw.com")
		XCTAssertEqual(url, URL(string: "https://mcubedsw.com")!)
	}
}
