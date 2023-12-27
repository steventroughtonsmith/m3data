//
//  ModelReaderTests.swift
//  M3DataTests
//
//  Created by Martin Pilkington on 25/07/2022.
//

import M3Data
import XCTest

final class ModelReaderTests: XCTestCase {
    var modelController: PersistenceTestObjects.PersistenceModelController!
    var modelReader: ModelReader!
    var testFileData: Data!

    override func setUpWithError() throws {
        self.modelController = PersistenceTestObjects.PersistenceModelController()
        self.modelReader = ModelReader(modelController: self.modelController,
                                       plists: [PersistenceTestObjects.PlistV1.self, PersistenceTestObjects.PlistV2.self, PersistenceTestObjects.PlistV3.self])

        self.testFileData = try XCTUnwrap(NSImage(named: "NSAddTemplate")?.tiffRepresentation)
    }

    func test_modelReader_throwsIfInvalidPlist() throws {
        let invalidData = try XCTUnwrap(NSImage(named: "NSAddTemplate")?.tiffRepresentation)
        let plistWrapper = FileWrapper(regularFileWithContents: invalidData)

        XCTAssertThrowsError(try self.modelReader.read(plistWrapper: plistWrapper, contentWrapper: nil, shouldMigrate: { true })) {
            XCTAssertEqual(($0 as? ModelReader.Errors), .invalidPlist)
        }
    }

    func test_modelReader_throwsErrorIfPlistVersionIsTooNew() throws {
        let plist = ["version": 4]
        let plistWrapper = FileWrapper(regularFileWithContents: try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0))

        XCTAssertThrowsError(try self.modelReader.read(plistWrapper: plistWrapper, contentWrapper: nil, shouldMigrate: { true })) {
            XCTAssertEqual(($0 as? ModelReader.Errors), .versionNotSupported)
        }
    }

    func test_modelReader_loadsDataIfPlistMatchesLatestVersion() throws {
        let plist = PersistenceTestObjects.PlistV3.samplePlist
        let plistWrapper = FileWrapper(regularFileWithContents: try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0))
        let contentWrapper = FileWrapper(directoryWithFileWrappers: ["photo.png": FileWrapper(regularFileWithContents: self.testFileData)])
        XCTAssertNoThrow(try self.modelReader.read(plistWrapper: plistWrapper, contentWrapper: contentWrapper, shouldMigrate: { true }))

        try self.validateModelController()
    }

    func test_modelReader_migratePlistToNextVersionBeforeLoading() throws {
        let plist = PersistenceTestObjects.PlistV2.samplePlist
        let plistWrapper = FileWrapper(regularFileWithContents: try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0))
        let contentWrapper = FileWrapper(directoryWithFileWrappers: ["photo.png": FileWrapper(regularFileWithContents: self.testFileData)])
        XCTAssertNoThrow(try self.modelReader.read(plistWrapper: plistWrapper, contentWrapper: contentWrapper, shouldMigrate: { true }))

        try self.validateModelController()
    }

    func test_modelReader_migratesPlistThroughMultipleVersionsBeforeLoading() throws {
        let plist = PersistenceTestObjects.PlistV1.samplePlist
        let plistWrapper = FileWrapper(regularFileWithContents: try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0))
        let contentWrapper = FileWrapper(directoryWithFileWrappers: ["photo.png": FileWrapper(regularFileWithContents: self.testFileData)])
        XCTAssertNoThrow(try self.modelReader.read(plistWrapper: plistWrapper, contentWrapper: contentWrapper, shouldMigrate: { true }))

        try self.validateModelController()
    }

    //MARK: - Helper
    func validateModelController() throws {
        let animalsCollection = self.modelController.collection(for: PersistenceTestObjects.Animal.self)

        let animal1 = try XCTUnwrap(animalsCollection.objectWithID(ModelID(modelType: PersistenceTestObjects.Animal.modelType, uuidString: "4932FB60-6D49-4E15-AFD0-599D32CC5F94")!))
        XCTAssertEqual(animal1.plistRepresentation[ModelPlistKey(rawValue: "species")] as? String, "Birb")
        XCTAssertEqual(animal1.plistRepresentation[ModelPlistKey(rawValue: "lastMeal")] as? String, "Bob")
        let animal2 = try XCTUnwrap(animalsCollection.objectWithID(ModelID(modelType: PersistenceTestObjects.Animal.modelType, uuidString: "5932FB60-6D49-4E15-AFD0-599D32CC5F94")!))
        XCTAssertEqual(animal2.plistRepresentation[ModelPlistKey(rawValue: "species")] as? String, "Bear")
        XCTAssertEqual(animal2.plistRepresentation[ModelPlistKey(rawValue: "lastMeal")] as? String, "Alice")
        let animal3 = try XCTUnwrap(animalsCollection.objectWithID(ModelID(modelType: PersistenceTestObjects.Animal.modelType, uuidString: "6932FB60-6D49-4E15-AFD0-599D32CC5F94")!))
        XCTAssertEqual(animal3.plistRepresentation[ModelPlistKey(rawValue: "species")] as? String, "Possum")
        XCTAssertEqual(animal3.plistRepresentation[ModelPlistKey(rawValue: "lastMeal")] as? String, "Pilky")
        let modelFile = try XCTUnwrap(animal3.plistRepresentation[ModelPlistKey(rawValue: "image")] as? ModelFile)
        XCTAssertEqual(modelFile.type, "png")
        XCTAssertEqual(modelFile.filename, "photo.png")
        XCTAssertEqual(modelFile.metadata?["colour"] as? Bool, true)
        XCTAssertEqual(modelFile.data, self.testFileData)

        let robotsCollection = self.modelController.collection(for: PersistenceTestObjects.Robot.self)
        let robot1 = try XCTUnwrap(robotsCollection.objectWithID(ModelID(modelType: PersistenceTestObjects.Robot.modelType, uuidString: "4932FB60-6D49-4E15-AFD0-599D32CC5F94")!))
        XCTAssertEqual(robot1.plistRepresentation[ModelPlistKey(rawValue: "name")] as? String, "PilkyBot")

        let robot2 = try XCTUnwrap(robotsCollection.objectWithID(ModelID(modelType: PersistenceTestObjects.Robot.modelType, uuidString: "5932FB60-6D49-4E15-AFD0-599D32CC5F94")!))
        XCTAssertEqual(robot2.plistRepresentation[ModelPlistKey(rawValue: "name")] as? String, "SinisterBot")

        XCTAssertEqual(self.modelController.settings.integer(for: ModelSettings.Setting(rawValue: "zoo-efficiency")), 90)
    }
}
