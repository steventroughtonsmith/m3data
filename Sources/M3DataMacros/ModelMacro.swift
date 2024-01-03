//
//  ModelMacro.swift
//
//
//  Created by Martin Pilkington on 21/12/2023.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum ModelMacroError: CustomStringConvertible, Error {
	case onlyApplicableToClass

	var description: String {
		switch self {
		case .onlyApplicableToClass:
			return "@Model can only be applied to a class"
		}
	}
}

public struct ModelMacro: MemberMacro {
	public static func expansion(of node: AttributeSyntax,
								 providingMembersOf declaration: some DeclGroupSyntax,
								 in context: some MacroExpansionContext) throws -> [DeclSyntax] {
		guard let classDeclaration = declaration as? ClassDeclSyntax else {
			return []
		}

		let className = classDeclaration.name.trimmed
		return (self.modelObjectDefinitions(forClassName: className) + [
			self.initDefinition(in: classDeclaration),
			self.modelFilePropertiesDefinition(in: classDeclaration),
			try self.plistRepresentationDefinition(in: classDeclaration),
			try self.updateFromPlistRepresentationDefinition(in: classDeclaration)
		]).compactMap { $0 }
	}

	private static func modelObjectDefinitions(forClassName className: TokenSyntax) -> [DeclSyntax] {
		return [
			"public static let modelType: ModelType = ModelType(rawValue: \"\(raw: className.text)\")",
			"public var id = ModelID(modelType: \(raw: className.text).modelType)",
			"public weak var collection: ModelCollection<\(raw: className.text)>?",
			"public var otherProperties: [ModelPlistKey: PlistValue] = [:]",
		]
	}

	private static func initDefinition(in classDecl: ClassDeclSyntax) -> DeclSyntax? {
		let initialisers = classDecl.memberBlock.members.compactMap { $0.decl.as(InitializerDeclSyntax.self) }
		for initialiser in initialisers {
			if initialiser.signature.parameterClause.parameters.count == 0 {
				return nil
			}
		}
		return "public init() {}"
	}

	private static func modelFilePropertiesDefinition(in classDecl: ClassDeclSyntax) -> DeclSyntax? {
		let modelFileAttributes = classDecl.attributes.filter(\.isModelFile)
		guard modelFileAttributes.isEmpty == false else {
			return nil
		}

		let attributesString = modelFileAttributes.map { $0.plistKey(for: classDecl) }.joined(separator: ", ")
		return """
			static public var modelFileProperties: [ModelPlistKey] {
				return [\(raw: attributesString)]
			}
			"""
	}

	private static func plistRepresentationDefinition(in classDecl: ClassDeclSyntax) throws -> DeclSyntax? {
		let attributes = classDecl.attributes.map {
			if $0.type.as(OptionalTypeSyntax.self) != nil {
				"plist[\($0.plistKey(for: classDecl))] = try self.\($0.name.text)?.toPlistValue()"
			} else {
				"plist[\($0.plistKey(for: classDecl))] = try self.\($0.name.text).toPlistValue()"
			}
		}

		let relationships = classDecl.relationships.map {
			"plist[\($0.plistKey(for: classDecl))] = try self.\(RelationshipMacro.modelIDProperty(forPropertyNamed: $0.name))?.toPlistValue()"
		}


		return """
		public var plistRepresentation: ModelObjectPlistRepresentation {
			get throws {
				var plist = self.otherProperties

				plist[.id] = try self.id.toPlistValue()
				\(raw: attributes.joined(separator: "\n"))
				\(raw: relationships.joined(separator: "\n"))

				return ModelObjectPlistRepresentation(id: self.id, plist: plist)
			}
		}
		"""
	}

	private static func updateFromPlistRepresentationDefinition(in classDecl: ClassDeclSyntax) throws -> DeclSyntax? {
		return try FunctionDeclSyntax("public func update(fromPlistRepresentation plist: ModelObjectPlistRepresentation) throws") {
			CodeBlockItemSyntax("""
guard self.id == plist.id else {
	throw ModelObjectUpdateErrors.idsDontMatch
}
""")
			for attribute in classDecl.attributes {
				attribute.variableDefinition(with: classDecl)
			}
			for relationship in classDecl.relationships {
				relationship.variableDefinition(with: classDecl)
			}
			for attribute in classDecl.attributes {
				"self.\(raw: attribute.name) = \(raw: attribute.name)"
			}
			for relationship in classDecl.relationships {
				"self.\(raw: RelationshipMacro.modelIDProperty(forPropertyNamed: relationship.name)) = \(raw: relationship.name)"
			}
			CodeBlockItemSyntax("let plistKeys = \(raw: classDecl.name.trimmed).PlistKeys.all")
			CodeBlockItemSyntax("""
self.otherProperties = plist.plist.filter { (key, _) -> Bool in
	return plistKeys.contains(key) == false
}
""")
		}.as(DeclSyntax.self)
	}
}

extension ModelMacro: ExtensionMacro {
	public static func expansion(of node: AttributeSyntax,
								 attachedTo declaration: some DeclGroupSyntax,
								 providingExtensionsOf type: some TypeSyntaxProtocol,
								 conformingTo protocols: [TypeSyntax],
								 in context: some MacroExpansionContext) throws -> [ExtensionDeclSyntax] {
		let collectableModelObject = try ExtensionDeclSyntax("extension \(type): CollectableModelObject {}")

		let hashable = try ExtensionDeclSyntax("extension \(type): Hashable") {
			try FunctionDeclSyntax("public func hash(into hasher: inout Hasher)") {
				CodeBlockItemSyntax("hasher.combine(self.id)")
			}
		}

		let equatable = try ExtensionDeclSyntax("extension \(type): Equatable") {
			try FunctionDeclSyntax("public static func ==(lhs: \(type), rhs: \(type)) -> Bool") {
				CodeBlockItemSyntax(
					"""
					return lhs.id == rhs.id
					"""
				)
			}
		}
		var extensions = [collectableModelObject, hashable, equatable]

		if let classDecl = declaration.as(ClassDeclSyntax.self) {
			extensions.append(try self.plistKeyExtension(for: classDecl))
		}
		return extensions
	}

	private static func plistKeyExtension(for classDecl: ClassDeclSyntax) throws -> ExtensionDeclSyntax {
		let attributes = classDecl.attributes
		let relationships = classDecl.relationships

		var allKeysArray: [String] = []
		allKeysArray.append(contentsOf: attributes.map { $0.plistKey(for: classDecl) })
		allKeysArray.append(contentsOf: relationships.map { $0.plistKey(for: classDecl) })

		let modelPlistKeyExtension = try ExtensionDeclSyntax("extension \(raw: classDecl.name.trimmed)") {
			try EnumDeclSyntax("enum PlistKeys") {
				for attribute in attributes {
					if let persistenceName = attribute.persistenceName {
						try VariableDeclSyntax("static let \(raw: attribute.name.trimmed) = ModelPlistKey(rawValue: \(raw: persistenceName.trimmed))")
					} else {
						try VariableDeclSyntax("static let \(raw: attribute.name.trimmed) = ModelPlistKey(rawValue: \"\(raw: attribute.name.trimmed)\")")
					}
				}
				for relationship in relationships {
					if let persistenceName = relationship.persistenceName {
						try VariableDeclSyntax("static let \(raw: relationship.name.trimmed) = ModelPlistKey(rawValue: \(raw: persistenceName.trimmed))")
					} else {
						try VariableDeclSyntax("static let \(raw: relationship.name.trimmed) = ModelPlistKey(rawValue: \"\(raw: relationship.name.trimmed)\")")
					}
				}
				try VariableDeclSyntax("static var all: [ModelPlistKey]") {
					"return [.id, \(raw: allKeysArray.joined(separator: ","))]"
				}
			}
		}
		return modelPlistKeyExtension
	}
}


extension ClassDeclSyntax {
	var attributes: [ModelAttribute] {
		var attributes = [ModelAttribute]()
		for member in memberBlock.members {
			guard
				let variable = member.decl.as(VariableDeclSyntax.self),
				let name = variable.bindingIdentifier?.identifier,
				let type = variable.bindingType,
				let attribute = variable.attributes.first(where: { $0.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "Attribute" })?.as(AttributeSyntax.self)
			else {
				continue
			}

			var optional: Bool = false
			var defaultValue: ExprSyntax? = nil
			var persistenceName: ExprSyntax? = nil
			var requiresTransform: Bool = false
			var isModelFile: Bool = false
			if let labelledExpr = attribute.arguments?.as(LabeledExprListSyntax.self) {
				optional = labelledExpr.bool(withName: "optional")
				defaultValue = labelledExpr.expression(withName: "default")
				persistenceName = labelledExpr.expression(withName: "persistenceName")
				requiresTransform = labelledExpr.bool(withName: "requiresTransform")
				isModelFile = labelledExpr.bool(withName: "isModelFile")
			}
			attributes.append(ModelAttribute(name: name, type: type, optional: optional, defaultValue: defaultValue, persistenceName: persistenceName, requiresTransform: requiresTransform, isModelFile: isModelFile))
		}
		return attributes
	}

	var relationships: [ModelRelationship] {
		var relationships = [ModelRelationship]()
		for member in memberBlock.members {
			guard
				let variable = member.decl.as(VariableDeclSyntax.self),
				let name = variable.bindingIdentifier?.identifier,
				let type = variable.bindingType,
				let attribute = variable.attributes.first(where: { $0.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "Relationship" })?.as(AttributeSyntax.self),
				let labelledExpr = attribute.arguments?.as(LabeledExprListSyntax.self),
				let inverse = labelledExpr.expression(withName: "inverse")
			else {
				continue
			}

			let persistenceName = labelledExpr.expression(withName: "persistenceName")

			relationships.append(ModelRelationship(name: name, type: type, inverse: inverse, persistenceName: persistenceName))
		}
		return relationships
	}


	struct ModelAttribute {
		var name: TokenSyntax
		var type: TypeSyntax
		var optional: Bool = false
		var defaultValue: ExprSyntax? = nil
		var persistenceName: ExprSyntax? = nil
		var requiresTransform: Bool = false
		var isModelFile: Bool = false

		func plistKey(for classDecl: ClassDeclSyntax) -> String {
			return "\(classDecl.name.text).PlistKeys.\(self.name.text)"
		}

		private var isOptional: Bool {
			return self.optional || self.type.is(OptionalTypeSyntax.self)
		}

		func variableDefinition(with classDecl: ClassDeclSyntax) -> CodeBlockItemSyntax {
			let required = self.isOptional ? "" : "required: "
			if let defaultValue = self.defaultValue {
				return "let \(raw: name.trimmed): \(raw: type.trimmed) = try plist[\(raw: required)\(raw: plistKey(for: classDecl)), default:\(raw: defaultValue)]"
			}
			return "let \(raw: name.trimmed): \(raw: type.trimmed) = try plist[\(raw: required)\(raw: plistKey(for: classDecl))]"
		}
	}

	struct ModelRelationship {
		var name: TokenSyntax
		var type: TypeSyntax
		var inverse: ExprSyntax
		var persistenceName: ExprSyntax? = nil

		func plistKey(for classDecl: ClassDeclSyntax) -> String {
			return "\(classDecl.name.text).PlistKeys.\(self.name.text)"
		}

		func variableDefinition(with classDecl: ClassDeclSyntax) -> CodeBlockItemSyntax {
			return "let \(raw: name.trimmed): ModelID? = try plist[\(raw: plistKey(for: classDecl))]"
		}
	}
}

extension LabeledExprListSyntax {
	func expression(withName name: String) -> ExprSyntax? {
		for syntax in self {
			guard 
				let labelledExpr = syntax.as(LabeledExprSyntax.self),
				labelledExpr.label?.text == name
			else {
				continue
			}
			return labelledExpr.expression
		}
		return nil
	}

	func bool(withName name: String) -> Bool {
		guard let expression = self.expression(withName: name)?.as(BooleanLiteralExprSyntax.self) else {
			return false
		}
		return expression.literal.text == "true"
	}
}
