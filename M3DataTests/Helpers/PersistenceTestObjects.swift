//
//  PersistenceTestObjects.swift
//  M3DataTests
//
//  Created by Martin Pilkington on 25/07/2022.
//

import Foundation
import M3Data

enum PersistenceTestObjects {
    final class Person: NSObject, CollectableModelObject {
        static let modelType = ModelType("Person")!
        var id = ModelID(modelType: Person.modelType)
        var collection: ModelCollection<Person>?

        let otherProperties = [ModelPlistKey : Any]()
        var plistRepresentation = [ModelPlistKey : Any]()

        func update(fromPlistRepresentation plist: [ModelPlistKey : Any]) throws {
            self.plistRepresentation = plist
        }
    }

    final class Animal: NSObject, CollectableModelObject {
        static let modelType = ModelType("Animal")!
        var id = ModelID(modelType: Animal.modelType)
        var collection: ModelCollection<Animal>?

        let otherProperties = [ModelPlistKey : Any]()
        var plistRepresentation = [ModelPlistKey : Any]()

        func update(fromPlistRepresentation plist: [ModelPlistKey : Any]) throws {
            self.plistRepresentation = plist
        }

        static var modelFileProperties: [ModelPlistKey] {
            return [ModelPlistKey(rawValue: "image")!]
        }
    }

    final class Robot: NSObject, CollectableModelObject {
        static let modelType = ModelType("Robot")!
        var id = ModelID(modelType: Robot.modelType)
        var collection: ModelCollection<Robot>?

        let otherProperties = [ModelPlistKey : Any]()
        var plistRepresentation = [ModelPlistKey : Any]()

        func update(fromPlistRepresentation plist: [ModelPlistKey : Any]) throws {
            self.plistRepresentation = plist
        }
    }

    class PersistenceModelController: ModelController {
        let settings = ModelSettings()
        let undoManager = UndoManager()
        var allCollections = [ModelType: AnyModelCollection]()

        init() {
            self.addModelCollection(for: Animal.self)
            self.addModelCollection(for: Robot.self)
        }
    }

    class PlistV1: ModelPlist {
        override class var version: Int {
            return 1
        }

        override class var supportedTypes: [ModelPlist.PersistenceTypes] {
            return [
                .init(modelType: Person.modelType, persistenceName: "people"),
                .init(modelType: Robot.modelType, persistenceName: "robots")
            ]
        }

        override func migrateToNextVersion() throws -> [String : Any] {
            var plist = self.plist
            plist["animals"] = [
                ["id": "Animal_4932FB60-6D49-4E15-AFD0-599D32CC5F94", "species": "Birb"],
                ["id": "Animal_5932FB60-6D49-4E15-AFD0-599D32CC5F94", "species": "Bear"],
                ["id": "Animal_6932FB60-6D49-4E15-AFD0-599D32CC5F94", "species": "Possum", "image": ["type": "png", "filename": "photo.png", "metadata": ["colour": true]]]
            ]
            plist["settings"] = ["zoo-efficiency": 90]
            plist["version"] = 2
            return plist
        }

        static var samplePlist: [String: Any] {
            return [
                "version": 1,
                "settings": [String: Any](),
                "people": [
                    ["id": "Person_4932FB60-6D49-4E15-AFD0-599D32CC5F94", "name": "Bob"],
                    ["id": "Person_5932FB60-6D49-4E15-AFD0-599D32CC5F94", "name": "Alice"],
                    ["id": "Person_6932FB60-6D49-4E15-AFD0-599D32CC5F94", "name": "Pilky"]
                ],
                "robots": [
                    ["id": "Robot_4932FB60-6D49-4E15-AFD0-599D32CC5F94", "name": "PilkyBot"],
                    ["id": "Robot_5932FB60-6D49-4E15-AFD0-599D32CC5F94", "name": "SinisterBot"],
                ]
            ]
        }
    }

    class PlistV2: ModelPlist {
        override class var version: Int {
            return 2
        }

        override class var supportedTypes: [ModelPlist.PersistenceTypes] {
            return [
                .init(modelType: Person.modelType, persistenceName: "people"),
                .init(modelType: Robot.modelType, persistenceName: "robots"),
                .init(modelType: Animal.modelType, persistenceName: "animals"),
            ]
        }

        override func migrateToNextVersion() throws -> [String : Any] {
            var plist = self.plist

            var finalAnimals = [[String: Any]]()
            for animalPlist in self.plistRepresentations(of: Animal.modelType) {
                var animal = animalPlist
                if (animal[.id] as? ModelID)?.uuid.uuidString == "4932FB60-6D49-4E15-AFD0-599D32CC5F94" {
                    animal[ModelPlistKey(rawValue: "lastMeal")!] = "Bob"
                } else if (animal[.id] as? ModelID)?.uuid.uuidString == "5932FB60-6D49-4E15-AFD0-599D32CC5F94" {
                    animal[ModelPlistKey(rawValue: "lastMeal")!] = "Alice"
                } else if (animal[.id] as? ModelID)?.uuid.uuidString == "6932FB60-6D49-4E15-AFD0-599D32CC5F94" {
                    animal[ModelPlistKey(rawValue: "lastMeal")!] = "Pilky"
                }
                finalAnimals.append(animal.toPersistanceRepresentation)
            }
            plist["animals"] = finalAnimals
            plist["people"] = nil
            plist["version"] = 3
            return plist
        }

        static var samplePlist: [String: Any] {
            return [
                "version": 2,
                "settings": ["zoo-efficiency": 90],
                "people": [
                    ["id": "Person_4932FB60-6D49-4E15-AFD0-599D32CC5F94", "name": "Bob"],
                    ["id": "Person_5932FB60-6D49-4E15-AFD0-599D32CC5F94", "name": "Alice"],
                    ["id": "Person_6932FB60-6D49-4E15-AFD0-599D32CC5F94", "name": "Pilky"]
                ],
                "animals": [
                    ["id": "Animal_4932FB60-6D49-4E15-AFD0-599D32CC5F94", "species": "Birb"],
                    ["id": "Animal_5932FB60-6D49-4E15-AFD0-599D32CC5F94", "species": "Bear"],
                    ["id": "Animal_6932FB60-6D49-4E15-AFD0-599D32CC5F94", "species": "Possum", "image": ["type": "png", "filename": "photo.png", "metadata": ["colour": true]]]
                ],
                "robots": [
                    ["id": "Robot_4932FB60-6D49-4E15-AFD0-599D32CC5F94", "name": "PilkyBot"],
                    ["id": "Robot_5932FB60-6D49-4E15-AFD0-599D32CC5F94", "name": "SinisterBot"],
                ]
            ]
        }
    }

    class PlistV3: ModelPlist {
        override class var version: Int {
            return 3
        }

        override class var supportedTypes: [ModelPlist.PersistenceTypes] {
            return [
                .init(modelType: Robot.modelType, persistenceName: "robots"),
                .init(modelType: Animal.modelType, persistenceName: "animals"),
            ]
        }

        static var samplePlist: [String: Any] {
            return [
                "version": 3,
                "settings": ["zoo-efficiency": 90],
                "animals": [
                    ["id": "Animal_4932FB60-6D49-4E15-AFD0-599D32CC5F94", "species": "Birb", "lastMeal": "Bob"],
                    ["id": "Animal_5932FB60-6D49-4E15-AFD0-599D32CC5F94", "species": "Bear", "lastMeal": "Alice"],
                    ["id": "Animal_6932FB60-6D49-4E15-AFD0-599D32CC5F94", "species": "Possum", "lastMeal": "Pilky", "image": ["type": "png", "filename": "photo.png", "metadata": ["colour": true]]]
                ],
                "robots": [
                    ["id": "Robot_4932FB60-6D49-4E15-AFD0-599D32CC5F94", "name": "PilkyBot"],
                    ["id": "Robot_5932FB60-6D49-4E15-AFD0-599D32CC5F94", "name": "SinisterBot"],
                ]
            ]
        }
    }
}
