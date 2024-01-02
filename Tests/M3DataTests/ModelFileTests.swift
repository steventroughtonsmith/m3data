//
//  ModelFileTests.swift
//  
//
//  Created by Martin Pilkington on 28/12/2023.
//

import XCTest
import M3Data

final class ModelFileTests: XCTestCase {
	//MARK: - toPlistValue()
	func test_toPlistValue_alwaysIncludesType() throws {
		let modelFile = ModelFile(type: "FileType", filename: nil, data: nil, metadata: nil)
		let plistRepresentation = try XCTUnwrap(modelFile.toPlistValue() as? [String: Any])
		XCTAssertEqual(plistRepresentation["type"] as? String, "FileType")
	}

	func test_toPlistValue_includesFilenameIfSet() throws {
		let modelFile = ModelFile(type: "FileType", filename: "myfile.txt", data: nil, metadata: nil)
		let plistRepresentation = try XCTUnwrap(modelFile.toPlistValue() as? [String: Any])

		XCTAssertEqual(plistRepresentation["filename"] as? String, "myfile.txt")
	}

	func test_toPlistValue_includesMetadataIfSet() throws {
		let modelFile = ModelFile(type: "FileType", filename: nil, data: nil, metadata: ["key": "value", "number": 42])
		let plistRepresentation = try XCTUnwrap(modelFile.toPlistValue() as? [String: Any])

		let metadataPlist = try XCTUnwrap(plistRepresentation["metadata"] as? [String: Any])
		XCTAssertEqual(metadataPlist["key"] as? String, "value")
		XCTAssertEqual(metadataPlist["number"] as? Int, 42)
	}

	func test_toPlistValue_doesntIncludeData() throws {
		let modelFile = ModelFile(type: "FileType", filename: nil, data: try XCTUnwrap("This should not be included".data(using: .utf8)), metadata: nil)
		let plistRepresentation = try XCTUnwrap(modelFile.toPlistValue() as? [String: Any])
		XCTAssertNil(plistRepresentation["data"])
	}

	//MARK: - fromPlistValue(_:)
	func test_fromPlistValue_returnsSuppliedModelFile() throws {
		let fileData = try XCTUnwrap("File Data".data(using: .utf8))
		let expectedModelFile = ModelFile(type: "FileType", filename: "myfile.txt", data: fileData, metadata: ["key": "value", "number": 42])

		let actualModelFile = try ModelFile.fromPlistValue(expectedModelFile)
		XCTAssertEqual(actualModelFile.type, expectedModelFile.type)
		XCTAssertEqual(actualModelFile.filename, expectedModelFile.filename)
		XCTAssertEqual(actualModelFile.data, expectedModelFile.data)
		XCTAssertEqual(actualModelFile.metadata?["key"] as? String, expectedModelFile.metadata?["key"] as? String)
		XCTAssertEqual(actualModelFile.metadata?["number"] as? Int, expectedModelFile.metadata?["number"] as? Int)
	}

	func test_fromPlistValue_throwsIfValueNotDictionary() throws {
		XCTAssertThrowsError(try ModelFile.fromPlistValue("")) { error in
			XCTAssertEqual(error as? PlistConvertableError, .invalidConversionFromPlistValue)
		}
		XCTAssertThrowsError(try ModelFile.fromPlistValue(5)) { error in
			XCTAssertEqual(error as? PlistConvertableError, .invalidConversionFromPlistValue)
		}
		XCTAssertThrowsError(try ModelFile.fromPlistValue(5.1)) { error in
			XCTAssertEqual(error as? PlistConvertableError, .invalidConversionFromPlistValue)
		}
		XCTAssertThrowsError(try ModelFile.fromPlistValue(42.0 as Float)) { error in
			XCTAssertEqual(error as? PlistConvertableError, .invalidConversionFromPlistValue)
		}
		XCTAssertThrowsError(try ModelFile.fromPlistValue(["Hello"])) { error in
			XCTAssertEqual(error as? PlistConvertableError, .invalidConversionFromPlistValue)
		}
		XCTAssertThrowsError(try ModelFile.fromPlistValue(Date())) { error in
			XCTAssertEqual(error as? PlistConvertableError, .invalidConversionFromPlistValue)
		}
		XCTAssertThrowsError(try ModelFile.fromPlistValue(Data())) { error in
			XCTAssertEqual(error as? PlistConvertableError, .invalidConversionFromPlistValue)
		}
	}

	func test_fromPlistValue_throwsIfDictionaryDoesntHaveType() throws {
		XCTAssertThrowsError(try ModelFile.fromPlistValue(["filename": "foobar.txt"])) { error in
			XCTAssertEqual(error as? PlistConvertableError, .invalidConversionFromPlistValue)
		}
	}

	func test_fromPlistValue_returnsModelFileWithJustType() throws {
		let actualModelFile = try ModelFile.fromPlistValue(["type": "FileType"])
		XCTAssertEqual(actualModelFile.type, "FileType")
	}

	func test_fromPlistValue_returnsModelFileWithFilename_DataAndMetadata() throws {
		let fileData = try XCTUnwrap("File Data".data(using: .utf8))

		let modelFilePlist: [String: PlistValue] = [
			"type": "FileType",
			"filename": "myfile.txt",
			"data": fileData,
			"metadata": ["key": "value", "number": 42] as PlistValue
		]

		let actualModelFile = try ModelFile.fromPlistValue(modelFilePlist as PlistValue)
		XCTAssertEqual(actualModelFile.type, "FileType")
		XCTAssertEqual(actualModelFile.filename, "myfile.txt")
		XCTAssertEqual(actualModelFile.data, fileData)
		XCTAssertEqual(actualModelFile.metadata?["key"] as? String, "value")
		XCTAssertEqual(actualModelFile.metadata?["number"] as? Int, 42)
	}

}
