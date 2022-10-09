//
//  ModelWriterTests.swift
//  M3DataTests
//
//  Created by Martin Pilkington on 25/07/2022.
//

import XCTest
@testable import M3Data

final class ModelWriterTests: XCTestCase {
    var modelController: PersistenceTestObjects.PersistenceModelController!
    var modelWriter: ModelWriter!
    var testFileData: Data!

    override func setUpWithError() throws {
        self.modelController = PersistenceTestObjects.PersistenceModelController()
        self.modelWriter = ModelWriter(modelController: self.modelController, plist: PersistenceTestObjects.PlistV3.self)

        self.testFileData = try XCTUnwrap(NSImage(named: "NSAddTemplate")?.tiffRepresentation)
    }

    func test_generateFileWrappers_dataPlistContainsAllModelObjects() throws {
        XCTFail()
    }

    func test_generateFileWrappers_includesSettings() throws {
        XCTFail()
    }

    func test_generateFileWrappers_includesDataFilesInContent() throws {
        XCTFail()
    }

    //MARK: - Conversions
    func test_generateFileWrappers_convertsModelIDToString() throws {
        XCTFail()
    }

    func test_generateFileWrappers_convertsModelFileToDictionary() throws {
        XCTFail()
    }

    func test_generateFileWrappers_convertsArrayOfModelIDsToArrayOfStrings() throws {
        XCTFail()
    }

    func test_generateFileWrappers_convertsArrayOfModelFilesToArrayOfStrings() throws {
        XCTFail()
    }

    func test_generateFileWrappers_convertsPropertiesInDictionary() throws {
        XCTFail()
    }

    func test_generateFileWrappers_doesntConvertDictionaryPropertiesNotListed() throws {
        XCTFail()
    }
}
