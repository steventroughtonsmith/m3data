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
        try super.setUpWithError()
        self.modelController = PersistenceTestObjects.PersistenceModelController()
        self.modelWriter = ModelWriter(modelController: self.modelController, plist: PersistenceTestObjects.PlistV3.self)

        self.testFileData = try XCTUnwrap(NSImage(named: "NSAddTemplate")?.tiffRepresentation)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        PersistenceTestObjects.Animal.propertyConversionsOverride = nil
    }

    func test_generateFileWrappers_dataPlistContainsAllModelObjects() throws {
        let animal1 = self.modelController.collection(for: PersistenceTestObjects.Animal.self).newObject() {
            $0.plistRepresentation = [ModelPlistKey(rawValue: "id"): $0.id]
        }
        let animal2 = self.modelController.collection(for: PersistenceTestObjects.Animal.self).newObject() {
            $0.plistRepresentation = [ModelPlistKey(rawValue: "id"): $0.id]
        }
        let robot1 = self.modelController.collection(for: PersistenceTestObjects.Robot.self).newObject() {
            $0.plistRepresentation = [ModelPlistKey(rawValue: "id"): $0.id]
        }

        let (animals, robots, _, _) = try self.generateWrappers()
        XCTAssertEqual(animals.count, 2)
        let animalIDs = animals.compactMap { $0["id"] as? String }
        XCTAssertTrue(animalIDs.contains(animal1.id.stringRepresentation))
        XCTAssertTrue(animalIDs.contains(animal2.id.stringRepresentation))
        XCTAssertEqual(robots.count, 1)
        XCTAssertEqual(robots[safe: 0]?["id"] as? String, robot1.id.stringRepresentation)
    }

    func test_generateFileWrappers_includesSettings() throws {
        self.modelController.settings.set("Foo", for: ModelSettings.Setting(rawValue: "bar"))
        self.modelController.settings.set(42, for: ModelSettings.Setting(rawValue: "baz"))
        let (_, _, settings, _) = try self.generateWrappers()
        XCTAssertEqual(settings["bar"] as? String, "Foo")
        XCTAssertEqual(settings["baz"] as? Int, 42)
    }

    func test_generateFileWrappers_includesDataFilesInContent() throws {
        self.modelController.collection(for: PersistenceTestObjects.Animal.self).newObject() {
            $0.plistRepresentation = [
                ModelPlistKey(rawValue: "id"): $0.id,
                ModelPlistKey(rawValue: "image"): ModelFile(type: "png", filename: "test.png", data: self.testFileData, metadata: [:])
            ]
        }
        let (_, _, _, files) = try self.generateWrappers()
        XCTAssertEqual(files.fileWrappers?.count, 1)
        XCTAssertEqual(files.fileWrappers?["test.png"]?.regularFileContents, self.testFileData)
    }

    //MARK: - Conversions
    func test_generateFileWrappers_convertsModelIDToString() throws {
        let expectedUUID = UUID()
        self.modelController.collection(for: PersistenceTestObjects.Animal.self).newObject() {
            $0.plistRepresentation = [
                ModelPlistKey(rawValue: "id"): $0.id,
                ModelPlistKey(rawValue: "modelIDProperty"): ModelID(modelType: PersistenceTestObjects.Person.modelType, uuid: expectedUUID)
            ]
        }

        PersistenceTestObjects.Animal.propertyConversionsOverride = [ModelPlistKey(rawValue: "modelIDProperty"): .modelID]

        let (animals, _, _, _) = try self.generateWrappers()
        XCTAssertEqual(animals.first?["modelIDProperty"] as? String, "Person_\(expectedUUID.uuidString)")
    }

    func test_generateFileWrappers_convertsModelFileToDictionary() throws {
        self.modelController.collection(for: PersistenceTestObjects.Animal.self).newObject() {
            $0.plistRepresentation = [
                ModelPlistKey(rawValue: "id"): $0.id,
                ModelPlistKey(rawValue: "modelFileProperty"): ModelFile(type: "png", filename: "foobar.baz", data: Data(), metadata: ["hello": "world"])
            ]
        }

        PersistenceTestObjects.Animal.propertyConversionsOverride = [ModelPlistKey(rawValue: "modelFileProperty"): .modelFile]

        let (animals, _, _, _) = try self.generateWrappers()
        let modelFile = try XCTUnwrap(animals.first?["modelFileProperty"] as? [String: Any])
        XCTAssertEqual(modelFile["filename"] as? String, "foobar.baz")
        XCTAssertEqual(modelFile["type"] as? String, "png")
        XCTAssertEqual(modelFile["metadata"] as? [String: String], ["hello": "world"])
    }

    func test_generateFileWrappers_convertsArrayOfModelIDsToArrayOfStrings() throws {
        let expectedUUID1 = UUID()
        let expectedUUID2 = UUID()
        self.modelController.collection(for: PersistenceTestObjects.Animal.self).newObject() {
            $0.plistRepresentation = [
                ModelPlistKey(rawValue: "id"): $0.id,
                ModelPlistKey(rawValue: "modelIDProperty"): [
                    ModelID(modelType: PersistenceTestObjects.Person.modelType, uuid: expectedUUID1),
                    ModelID(modelType: PersistenceTestObjects.Robot.modelType, uuid: expectedUUID2)
                ]
            ]
        }

        PersistenceTestObjects.Animal.propertyConversionsOverride = [ModelPlistKey(rawValue: "modelIDProperty"): .array(.modelID)]

        let (animals, _, _, _) = try self.generateWrappers()
        let modelIDs = try XCTUnwrap(animals.first?["modelIDProperty"] as? [String])
        XCTAssertEqual(modelIDs[safe: 0], "Person_\(expectedUUID1.uuidString)")
        XCTAssertEqual(modelIDs[safe: 1], "Robot_\(expectedUUID2.uuidString)")
    }

    func test_generateFileWrappers_convertsArrayOfModelFilesToArrayOfDictionaries() throws {
        self.modelController.collection(for: PersistenceTestObjects.Animal.self).newObject() {
            $0.plistRepresentation = [
                ModelPlistKey(rawValue: "id"): $0.id,
                ModelPlistKey(rawValue: "modelFileProperty"): [
                    ModelFile(type: "png", filename: "foobar.baz", data: Data(), metadata: ["hello": "world"]),
                    ModelFile(type: "jpeg", filename: "possum.jpeg", data: Data(), metadata: ["goodbye": "void"]),
                ]
            ]
        }

        PersistenceTestObjects.Animal.propertyConversionsOverride = [ModelPlistKey(rawValue: "modelFileProperty"): .array(.modelFile)]

        let (animals, _, _, _) = try self.generateWrappers()
        let modelFiles = try XCTUnwrap(animals.first?["modelFileProperty"] as? [[String: Any]])
        XCTAssertEqual(modelFiles[safe: 0]?["filename"] as? String, "foobar.baz")
        XCTAssertEqual(modelFiles[safe: 0]?["type"] as? String, "png")
        XCTAssertEqual(modelFiles[safe: 0]?["metadata"] as? [String: String], ["hello": "world"])

        XCTAssertEqual(modelFiles[safe: 1]?["filename"] as? String, "possum.jpeg")
        XCTAssertEqual(modelFiles[safe: 1]?["type"] as? String, "jpeg")
        XCTAssertEqual(modelFiles[safe: 1]?["metadata"] as? [String: String], ["goodbye": "void"])
    }

    func test_generateFileWrappers_convertsPropertiesInDictionary() throws {
        let expectedUUID = UUID()
        self.modelController.collection(for: PersistenceTestObjects.Animal.self).newObject() {
            $0.plistRepresentation = [
                ModelPlistKey(rawValue: "id"): $0.id,
                ModelPlistKey(rawValue: "dictionaryProperty"): [
                    ModelPlistKey(rawValue: "modelID"): ModelID(modelType: PersistenceTestObjects.Person.modelType, uuid: expectedUUID),
                    ModelPlistKey(rawValue: "modelFile"): ModelFile(type: "png", filename: "foobar.baz", data: Data(), metadata: ["hello": "world"]),
                ]
            ]
        }

        PersistenceTestObjects.Animal.propertyConversionsOverride = [ModelPlistKey(rawValue: "dictionaryProperty"): .dictionary([
            ModelPlistKey(rawValue: "modelID"): .modelID,
            ModelPlistKey(rawValue: "modelFile"): .modelFile
        ])]

        let (animals, _, _, _) = try self.generateWrappers()
        let dictionary = try XCTUnwrap(animals.first?["dictionaryProperty"] as? [String: Any])
        XCTAssertEqual(dictionary["modelID"] as? String, "Person_\(expectedUUID.uuidString)")
        let modelFile = try XCTUnwrap(dictionary["modelFile"] as? [String: Any])
        XCTAssertEqual(modelFile["filename"] as? String, "foobar.baz")
        XCTAssertEqual(modelFile["type"] as? String, "png")
        XCTAssertEqual(modelFile["metadata"] as? [String: String], ["hello": "world"])
    }

    func test_generateFileWrappers_doesntConvertDictionaryPropertiesNotListed() throws {
        let expectedUUID = UUID()
        self.modelController.collection(for: PersistenceTestObjects.Animal.self).newObject() {
            $0.plistRepresentation = [
                ModelPlistKey(rawValue: "id"): $0.id,
                ModelPlistKey(rawValue: "dictionaryProperty"): [
                    ModelPlistKey(rawValue: "modelID"): ModelID(modelType: PersistenceTestObjects.Person.modelType, uuid: expectedUUID),
                    ModelPlistKey(rawValue: "doNotConvert"): 42,
                    ModelPlistKey(rawValue: "modelFile"): ModelFile(type: "png", filename: "foobar.baz", data: Data(), metadata: ["hello": "world"]),
                ]
            ]
        }

        PersistenceTestObjects.Animal.propertyConversionsOverride = [ModelPlistKey(rawValue: "dictionaryProperty"): .dictionary([
            ModelPlistKey(rawValue: "modelID"): .modelID,
            ModelPlistKey(rawValue: "modelFile"): .modelFile
        ])]

        let (animals, _, _, _) = try self.generateWrappers()
        let dictionary = try XCTUnwrap(animals.first?["dictionaryProperty"] as? [String: Any])
        XCTAssertEqual(dictionary["doNotConvert"] as? Int, 42)
    }

    private func generateWrappers() throws -> (animals: [[String: Any]], robots: [[String: Any]], settings: [String: Any], files: FileWrapper) {
        let (dataWrapper, files) = try self.modelWriter.generateFileWrappers()
        let data = try XCTUnwrap(dataWrapper.regularFileContents)
        let plist = try XCTUnwrap(try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])
        let animals = try XCTUnwrap(plist["animals"] as? [[String: Any]])
        let robots = try XCTUnwrap(plist["robots"] as? [[String: Any]])
        let settings = try XCTUnwrap(plist["settings"] as? [String: Any])

        return (animals, robots, settings, files)
    }
}
