import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(M3DataMacros)
import M3DataMacros

let testMacros: [String: Macro.Type] = [
	"Model": ModelMacro.self,
	"Attribute": AttributeMacro.self,
	"Relationship": RelationshipMacro.self,
]
#endif

final class M3DataMacroTests: XCTestCase {
	func testModelMacro() throws {
#if canImport(M3DataMacros)
		assertMacroExpansion(
			"""
			@Model public class MyModel {
				public init() {}
				public init(test: String) {}
			}
			""",
			expandedSource: """
			public class MyModel {

				public static let modelType: ModelType = ModelType(rawValue: "MyModel")!
				public var id = ModelID(modelType: MyModel.modelType)
				public weak var collection: ModelCollection<MyModel>?
			}

			extension MyModel: CollectableModelObject {
			}
			""",
			macros: testMacros,
			indentationWidth: .tab
		)
#else
		throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
	}

	func testAttributeMacro_simple() throws {
		#if canImport(M3DataMacros)
		assertMacroExpansion(
			"""
			@Attribute var title: String = "Test"
			""",
			expandedSource: """
			var title: String = "Test" {
				didSet {
					self.didChange(\\.title, oldValue: oldValue)
				}
			}
			""",
			macros: testMacros,
			indentationWidth: .tab)
		#else
		throw XCTSkip("macros are only supported when running tests for the host platform")
		#endif
	}

	func testAttributeMacro_didSet() throws {
#if canImport(M3DataMacros)
		assertMacroExpansion(
	"""
	@Attribute var title: String = "Test" {
		didSet {
			print("oldValue: \\(oldValue)")
		}
	}
	""",
	expandedSource: """
	var title: String = "Test" {
		didSet {
			self.didChange(\\.title, oldValue: oldValue)
		}
	}
	""",
	macros: testMacros,
	indentationWidth: .tab)
#else
		throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
	}

	func testRelationshipMacro_toOne() throws {
#if canImport(M3DataMacros)
		assertMacroExpansion(
	"""
	@Relationship(\\MyModel.id) var title: MyModel?
	""",
	expandedSource: """
	var title: String = "Test" {
		didSet {
			self.didChange(\\.title, oldValue: oldValue)

			print("new value is \\(self.title)")
		}
	}
	""",
	macros: testMacros,
	indentationWidth: .tab)
#else
		throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
	}

	func testRelationshipMacro_toMany() throws {
#if canImport(M3DataMacros)
		assertMacroExpansion(
 """
 @Model class Foobar {
  @Relationship(inverse: \\MyModel.foobar) var myModels: Set<MyModel>
 }
 @Model class MyModel {
  @Relationship(inverse: \\MyModel.myModels) var foobar: Foobar?
 }
 """,
 expandedSource: """
 var title: String = "Test" {
  didSet {
   self.didChange(\\.title, oldValue: oldValue)

   print("new value is \\(self.title)")
  }
 }
 """,
 macros: testMacros,
 indentationWidth: .tab)
#else
		throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
	}
}
