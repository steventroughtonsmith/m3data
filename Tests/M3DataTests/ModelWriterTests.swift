//
//  ModelWriterTests.swift
//  M3DataTests
//
//  Created by Martin Pilkington on 25/07/2022.
//

@testable import M3Data
import XCTest

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
        PersistenceTestObjects.Animal.modelFilePropertiesOverride = nil
    }

    func test_generateFileWrappers_dataPlistContainsAllModelObjects() throws {
        let animal1 = self.modelController.collection(for: PersistenceTestObjects.Animal.self).newObject() {
			$0.plistRepresentation = ModelObjectPlistRepresentation(id: $0.id, plist: [.id: try! $0.id.toPlistValue()])
        }
        let animal2 = self.modelController.collection(for: PersistenceTestObjects.Animal.self).newObject() {
			$0.plistRepresentation = ModelObjectPlistRepresentation(id: $0.id, plist: [.id: try! $0.id.toPlistValue()])
        }
        let robot1 = self.modelController.collection(for: PersistenceTestObjects.Robot.self).newObject() {
			$0.plistRepresentation = ModelObjectPlistRepresentation(id: $0.id, plist: [.id: try! $0.id.toPlistValue()])
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
			$0.plistRepresentation = .init(id: $0.id, plist: [
				.id: try! $0.id.toPlistValue(),
                ModelPlistKey(rawValue: "image"): ModelFile(type: "png", filename: "test.png", data: self.testFileData, metadata: [:]),
            ])
        }
        let (_, _, _, files) = try self.generateWrappers()
        XCTAssertEqual(files.fileWrappers?.count, 1)
        XCTAssertEqual(files.fileWrappers?["test.png"]?.regularFileContents, self.testFileData)
    }

    //MARK: - Conversions
    func test_generateFileWrappers_convertsModelIDToString() throws {
        let expectedUUID = UUID()
        self.modelController.collection(for: PersistenceTestObjects.Animal.self).newObject() {
			$0.plistRepresentation = .init(id: $0.id, plist: [
				.id: try! $0.id.toPlistValue(),
				ModelPlistKey(rawValue: "modelIDProperty"): try! ModelID(modelType: PersistenceTestObjects.Person.modelType, uuid: expectedUUID).toPlistValue(),
            ])
        }

        PersistenceTestObjects.Animal.propertyConversionsOverride = [ModelPlistKey(rawValue: "modelIDProperty"): .modelID]

        let (animals, _, _, _) = try self.generateWrappers()
        XCTAssertEqual(animals.first?["modelIDProperty"] as? String, "Person_\(expectedUUID.uuidString)")
    }

    func test_generateFileWrappers_convertsModelFileToDictionary() throws {
        self.modelController.collection(for: PersistenceTestObjects.Animal.self).newObject() {
			$0.plistRepresentation = .init(id: $0.id, plist: [
				.id: try! $0.id.toPlistValue(),
				ModelPlistKey(rawValue: "modelFileProperty"): ModelFile(type: "png", filename: "foobar.baz", data: Data(), metadata: ["hello": "world"]),
            ])
        }

        PersistenceTestObjects.Animal.modelFilePropertiesOverride = [ModelPlistKey(rawValue: "modelFileProperty")]

        let (animals, _, _, _) = try self.generateWrappers()
        let modelFile = try XCTUnwrap(animals.first?["modelFileProperty"] as? [String: Any])
        XCTAssertEqual(modelFile["filename"] as? String, "foobar.baz")
        XCTAssertEqual(modelFile["type"] as? String, "png")
        XCTAssertEqual(modelFile["metadata"] as? [String: String], ["hello": "world"])
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
