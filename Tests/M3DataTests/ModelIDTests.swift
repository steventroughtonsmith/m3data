//
//  ModelIDTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 01/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import M3Data
import XCTest

class ModelIDTests: XCTestCase {
    //MARK: - init?(modelType:uuidString:)
    func test_init_successfullyInitialisesWithValidUUIDString() throws {
        let expectedUUID = UUID()
        let modelID = try XCTUnwrap(ModelID(modelType: ModelType(""), uuidString: expectedUUID.uuidString))
        XCTAssertEqual(modelID.uuid, expectedUUID)
    }

    func test_init_returnsNilIfUUIDStringInvalid() {
        XCTAssertNil(ModelID(modelType: ModelType(""), uuidString: "12345"))
    }


    //MARK: - .pasteboardItem
    func test_pasteboardItem_returnsPasteboardItemWithPropertyListForCorrectType() {
        let modelID = ModelID(modelType: ModelType(""))
        let pasteboardItem = modelID.pasteboardItem

        XCTAssertTrue(pasteboardItem.types.contains(ModelID.PasteboardType))
        XCTAssertNotNil(pasteboardItem.propertyList(forType: ModelID.PasteboardType))
    }


    //MARK: - init?(pasteboardItem:)
    func test_initPasteboardItem_returnsNilIfPasteboardItemDoesntContainModelID() {
        XCTAssertNil(ModelID(pasteboardItem: NSPasteboardItem()))
    }

    func test_initPasteboardItem_returnsNilIfPasteboardItemModelIDIsntDictionary() {
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setPropertyList("Test", forType: ModelID.PasteboardType)
        XCTAssertNil(ModelID(pasteboardItem: NSPasteboardItem()))
    }

    func test_initPasteboardItem_returnsNilIfUUIDNotInDictionary() {
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setPropertyList(["modelType": ""], forType: ModelID.PasteboardType)
        XCTAssertNil(ModelID(pasteboardItem: NSPasteboardItem()))
    }

    func test_initPasteboardItem_returnsNilIfModelTypeNotInDictionary() {
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setPropertyList(["uuid": UUID().uuidString], forType: ModelID.PasteboardType)
        XCTAssertNil(ModelID(pasteboardItem: NSPasteboardItem()))
    }

    func test_initPasteboardItem_correctlyInitialisesModelIDFromPasteboardItem() throws {
        let modelID = ModelID(modelType: ModelType(""))
        let pasteboardItem = modelID.pasteboardItem
        let newModelID = ModelID(pasteboardItem: pasteboardItem)
        XCTAssertEqual(modelID, newModelID)
    }

	//MARK: - .stringRepresentation
	func test_stringRepresentation_includesTypeAndUUID() throws {
		let modelID = ModelID(modelType: ModelType("MyModel"), uuid: UUID())
		XCTAssertEqual(modelID.stringRepresentation, "MyModel_\(modelID.uuid.uuidString)")
	}

	//MARK: - init?(string:)
	func test_initWithString_returnsNilIfMissingComponent() throws {
		let uuid = UUID()
		XCTAssertNil(ModelID(string: uuid.uuidString))
	}

	func test_initWithString_returnsNilIfUUIDInvalid() throws {
		XCTAssertNil(ModelID(string: "MyModel_12345"))
	}

	func test_initWithString_returnsModelID() throws {
		let uuid = UUID()
		let modelID = try XCTUnwrap(ModelID(string: "MyModel_\(uuid.uuidString)"))
		XCTAssertEqual(modelID.modelType, ModelType("MyModel"))
		XCTAssertEqual(modelID.uuid, uuid)
	}


	//MARK: - toPlistValue()
	func test_toPlistValue_equalsStringRepresentation() throws {
		let modelID = ModelID(modelType: ModelType("MyModel"), uuid: UUID())
		XCTAssertEqual(try modelID.toPlistValue() as? String, modelID.stringRepresentation)
	}


	//MARK: - fromPlistValue(_:)
	func test_fromPlistValue_throwsIfValueNotString() throws {
		XCTAssertThrowsError(try ModelID.fromPlistValue(["Hello": "World"])) { error in
			XCTAssertEqual(error as? PlistConvertableError, .invalidConversionFromPlistValue)
		}
		XCTAssertThrowsError(try ModelID.fromPlistValue(5)) { error in
			XCTAssertEqual(error as? PlistConvertableError, .invalidConversionFromPlistValue)
		}
		XCTAssertThrowsError(try ModelID.fromPlistValue(5.1)) { error in
			XCTAssertEqual(error as? PlistConvertableError, .invalidConversionFromPlistValue)
		}
		XCTAssertThrowsError(try ModelID.fromPlistValue(42.0 as Float)) { error in
			XCTAssertEqual(error as? PlistConvertableError, .invalidConversionFromPlistValue)
		}
		XCTAssertThrowsError(try ModelID.fromPlistValue(["Hello"])) { error in
			XCTAssertEqual(error as? PlistConvertableError, .invalidConversionFromPlistValue)
		}
		XCTAssertThrowsError(try ModelID.fromPlistValue(Date())) { error in
			XCTAssertEqual(error as? PlistConvertableError, .invalidConversionFromPlistValue)
		}
		XCTAssertThrowsError(try ModelID.fromPlistValue(Data())) { error in
			XCTAssertEqual(error as? PlistConvertableError, .invalidConversionFromPlistValue)
		}
	}

	func test_fromPlistValue_throwsIfMissingComponent() throws {
		let uuid = UUID()
		XCTAssertThrowsError(try ModelID.fromPlistValue(uuid.uuidString)) { error in
			XCTAssertEqual(error as? PlistConvertableError, .invalidConversionFromPlistValue)
		}
	}

	func test_fromPlistValue_throwsIfUUIDInvalid() throws {
		XCTAssertThrowsError(try ModelID.fromPlistValue("MyModel_12345")) { error in
			XCTAssertEqual(error as? PlistConvertableError, .invalidConversionFromPlistValue)
		}
	}

	func test_fromPlistValue_returnsModelID() throws {
		let uuid = UUID()
		let modelID = try ModelID.fromPlistValue("MyModel_\(uuid.uuidString)")
		XCTAssertEqual(modelID.modelType, ModelType("MyModel"))
		XCTAssertEqual(modelID.uuid, uuid)
	}
}
