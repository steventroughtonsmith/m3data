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
			self.initDefinition(in: classDeclaration)
		]).compactMap { $0 }
	}

	private static func modelObjectDefinitions(forClassName className: TokenSyntax) -> [DeclSyntax] {
		return [
			"public static let modelType: ModelType = ModelType(rawValue: \"\(raw: className.text)\")!",
			"public var id = ModelID(modelType: \(raw: className.text).modelType)",
			"public weak var collection: ModelCollection<\(raw: className.text)>?",
			"public var otherProperties: [ModelPlistKey: Any] = [:]",
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
				CodeBlockItemSyntax("hasher.combine(Self.modelType)")
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
		return [collectableModelObject, hashable, equatable]
	}
}
