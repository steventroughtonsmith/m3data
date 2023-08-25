//
//  ModelPlistTests.swift
//  M3DataTests
//
//  Created by Martin Pilkington on 24/07/2022.
//

import XCTest

@testable import M3Data

final class ModelPlistTests: XCTestCase {
    var testPlist: [String: Any]!

    override func setUp() async throws {
        self.testPlist = [
            "version": 4,
            "settings": ["name": "Bob", "isPro": true] as [String: Any],
            "pages": [
                [
                    "id": "Page_26F8CA72-4EAA-4120-BBAD-2688B47E6C6C",
                    "title": "My Awesome Page",
                    "content": "To be written…",
                ],
                [
                    "id": "Page_96F8CA72-4EAA-4120-BBAD-2688B47E6C6C",
                    "title": "All About Possums",
                    "content": "They are awesome",
                ],
            ],
            "canvases": [
                [
                    "id": "Canvas_AAAACA72-4EAA-4120-BBAD-2688B47E6C6C",
                    "name": "First Canvas",
                    "meaningOfLife": 42,
                ] as [String: Any],
            ],
        ]
    }

    //MARK: - init(plist:)
    func test_initWithPlist_throwsErrorIfVersionsDontMatch() throws {
        self.testPlist["version"] = 3

        XCTAssertThrowsError(try TestModelPlist(plist: self.testPlist)) { error in
            guard
                let plistError = error as? ModelPlist.Errors,
                case .invalidVersion(let received, let expected) = plistError
            else {
                XCTFail("Incorrect error, got \(error)")
                return
            }
            XCTAssertEqual(received, 3)
            XCTAssertEqual(expected, 4)
        }
    }

    func test_initWithPlist_setsSettings() throws {
        let modelPlist = try TestModelPlist(plist: self.testPlist)
        XCTAssertEqual(modelPlist.settings.count, 2)
        XCTAssertEqual(modelPlist.settings["name"] as? String, "Bob")
        XCTAssertEqual(modelPlist.settings["isPro"] as? Bool, true)
    }

    func test_initWithPlist_ignoresValuesNotInSupportedModelTypes() throws {
        self.testPlist["bugs"] = [
            ["id": 1234, "colour": "red"],
            ["id": 5678, "colour": "blue"],
            ["id": 90, "colour": "green"],
        ] as [[String: Any]]

        let modelPlist = try TestModelPlist(plist: self.testPlist)
        XCTAssertEqual(modelPlist.plistRepresentations(of: ModelType(rawValue: "bugs")!).count, 0)
    }

    func test_initWithPlist_throwsErrorIfSupportedModelTypeIsMissing() throws {
        self.testPlist["canvases"] = nil

        XCTAssertThrowsError(try TestModelPlist(plist: self.testPlist)) { error in
            guard
                let plistError = error as? ModelPlist.Errors,
                case .missingCollection(let collectionName) = plistError
            else {
                XCTFail("Incorrect error, got \(error)")
                return
            }
            XCTAssertEqual(collectionName, "canvases")
        }
    }

    func test_initWithPlist_loadsSupportedModelTypes() throws {
        let modelPlist = try TestModelPlist(plist: self.testPlist)

        let pages = modelPlist.plistRepresentations(of: Self.pageModelType)
        XCTAssertEqual(pages.count, 2)
        XCTAssertEqual(pages[safe: 0]?[.id] as? ModelID, ModelID(modelType: Self.pageModelType, uuidString: "26F8CA72-4EAA-4120-BBAD-2688B47E6C6C"))
        XCTAssertEqual(pages[safe: 0]?[ModelPlistKey(rawValue: "title")] as? String, "My Awesome Page")
        XCTAssertEqual(pages[safe: 0]?[ModelPlistKey(rawValue: "content")] as? String, "To be written…")
        XCTAssertEqual(pages[safe: 1]?[.id] as? ModelID, ModelID(modelType: Self.pageModelType, uuidString: "96F8CA72-4EAA-4120-BBAD-2688B47E6C6C"))
        XCTAssertEqual(pages[safe: 1]?[ModelPlistKey(rawValue: "title")] as? String, "All About Possums")
        XCTAssertEqual(pages[safe: 1]?[ModelPlistKey(rawValue: "content")] as? String, "They are awesome")
    }


    //MARK: - .plist
    func test_plist_includesVersion() throws {
        let modelPlist = TestModelPlist()
        XCTAssertEqual(modelPlist.plist["version"] as? Int, 4)
    }

    func test_plist_includesSettings() throws {
        let modelPlist = TestModelPlist()
        modelPlist.settings = ["hello": "world", "foo": "bar", "baz": 42]
        let settingsPlist = try XCTUnwrap(modelPlist.plist["settings"] as? [String: Any])
        XCTAssertEqual(settingsPlist["hello"] as? String, "world")
        XCTAssertEqual(settingsPlist["foo"] as? String, "bar")
        XCTAssertEqual(settingsPlist["baz"] as? Int, 42)
    }

    func test_plist_includesAllSupportedTypes() throws {
        let modelPlist = TestModelPlist()
        try modelPlist.setPlistRepresentations([
            [.id: ModelID(modelType: Self.pageModelType, uuidString: "26F8CA72-4EAA-4120-BBAD-2688B47E6C6C")!, ModelPlistKey(rawValue: "title"): "Page 1"],
            [.id: ModelID(modelType: Self.pageModelType, uuidString: "96F8CA72-4EAA-4120-BBAD-2688B47E6C6C")!, ModelPlistKey(rawValue: "title"): "Page 2"],
        ], for: Self.pageModelType)

        try modelPlist.setPlistRepresentations([
            [.id: ModelID(modelType: Self.canvasModelType, uuidString: "AAAACA72-4EAA-4120-BBAD-2688B47E6C6C")!, ModelPlistKey(rawValue: "title"): "My Canvas"],
        ], for: Self.canvasModelType)


        let pagesPlist = try XCTUnwrap(modelPlist.plist["pages"] as? [[String: Any]])
        XCTAssertEqual(pagesPlist.count, 2)
        XCTAssertEqual(pagesPlist[safe: 0]?["id"] as? String, "Page_26F8CA72-4EAA-4120-BBAD-2688B47E6C6C")
        XCTAssertEqual(pagesPlist[safe: 0]?["title"] as? String, "Page 1")
        XCTAssertEqual(pagesPlist[safe: 1]?["id"] as? String, "Page_96F8CA72-4EAA-4120-BBAD-2688B47E6C6C")
        XCTAssertEqual(pagesPlist[safe: 1]?["title"] as? String, "Page 2")

        let canvasesPlist = try XCTUnwrap(modelPlist.plist["canvases"] as? [[String: Any]])
        XCTAssertEqual(canvasesPlist.count, 1)
        XCTAssertEqual(canvasesPlist[safe: 0]?["id"] as? String, "Canvas_AAAACA72-4EAA-4120-BBAD-2688B47E6C6C")
        XCTAssertEqual(canvasesPlist[safe: 0]?["title"] as? String, "My Canvas")
    }

    func test_plist_sortsObjectsByID() throws {
        let modelPlist = TestModelPlist()
        try modelPlist.setPlistRepresentations([
            [.id: ModelID(modelType: Self.pageModelType, uuidString: "96F8CA72-4EAA-4120-BBAD-2688B47E6C6C")!, ModelPlistKey(rawValue: "title"): "Page 2"],
            [.id: ModelID(modelType: Self.pageModelType, uuidString: "26F8CA72-4EAA-4120-BBAD-2688B47E6C6C")!, ModelPlistKey(rawValue: "title"): "Page 1"],
        ], for: Self.pageModelType)

        try modelPlist.setPlistRepresentations([
            [.id: ModelID(modelType: Self.canvasModelType, uuidString: "AAAACA72-4EAA-4120-BBAD-2688B47E6C6C")!, ModelPlistKey(rawValue: "title"): "My Canvas"],
        ], for: Self.canvasModelType)


        let pagesPlist = try XCTUnwrap(modelPlist.plist["pages"] as? [[String: Any]])
        XCTAssertEqual(pagesPlist.count, 2)
        XCTAssertEqual(pagesPlist[safe: 0]?["id"] as? String, "Page_26F8CA72-4EAA-4120-BBAD-2688B47E6C6C")
        XCTAssertEqual(pagesPlist[safe: 0]?["title"] as? String, "Page 1")
        XCTAssertEqual(pagesPlist[safe: 1]?["id"] as? String, "Page_96F8CA72-4EAA-4120-BBAD-2688B47E6C6C")
        XCTAssertEqual(pagesPlist[safe: 1]?["title"] as? String, "Page 2")
    }

    func test_plist_includesSupportedTypeEvenIfEmpty() throws {
        let modelPlist = TestModelPlist()
        try modelPlist.setPlistRepresentations([
            [.id: ModelID(modelType: Self.pageModelType, uuidString: "26F8CA72-4EAA-4120-BBAD-2688B47E6C6C")!, ModelPlistKey(rawValue: "title"): "Page 1"],
            [.id: ModelID(modelType: Self.pageModelType, uuidString: "96F8CA72-4EAA-4120-BBAD-2688B47E6C6C")!, ModelPlistKey(rawValue: "title"): "Page 2"],
        ], for: Self.pageModelType)

        XCTAssertNotNil(modelPlist.plist["canvases"])
    }
}


//MARK: - Helpers
extension ModelPlistTests {
    static let pageModelType = ModelType(rawValue: "Page")!
    static let canvasModelType = ModelType(rawValue: "Canvas")!

    class TestModelPlist: ModelPlist {
        override class var version: Int {
            return 4
        }

        override class var supportedTypes: [PersistenceTypes] {
            return [.init(modelType: ModelPlistTests.pageModelType, persistenceName: "pages"),
                    .init(modelType: ModelPlistTests.canvasModelType, persistenceName: "canvases")]
        }
    }
}


