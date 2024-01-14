//
//  RelationshipMacro.swift
//  
//
//  Created by Martin Pilkington on 21/12/2023.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct RelationshipMacro {
	static func modelIDProperty(forPropertyNamed propertyName: TokenSyntax) -> String {
		return "_\(propertyName.trimmed.text)ID"
	}
}

extension RelationshipMacro: AccessorMacro {
	public static func expansion(of node: AttributeSyntax,
								 providingAccessorsOf declaration: some DeclSyntaxProtocol,
								 in context: some MacroExpansionContext) throws -> [AccessorDeclSyntax] {
		guard
			let property = declaration.as(VariableDeclSyntax.self),
			let identifier = property.bindingIdentifier?.identifier,
			case .argumentList(let arguments) = node.arguments,
			let inverseKeyPath = arguments.first?.expression.as(KeyPathExprSyntax.self),
			let binding = property.bindingType?.as(OptionalTypeSyntax.self),
			let typeName = binding.wrappedType.as(IdentifierTypeSyntax.self)?.name
		else {
			return []
		}

		let get: AccessorDeclSyntax =
  """
get {
	guard let objectID = self.\(raw: self.modelIDProperty(forPropertyNamed: identifier)) else {
		return nil
	}
	return self.modelController?.collection(for: \(raw: typeName.trimmed).self).objectWithID(objectID)
}
"""
		let set = Self.generateSetter(for: identifier, inverseKeyPath: inverseKeyPath, property: property)
		return [get, set]
	}

	private static func generateSetter(for identifier: TokenSyntax, inverseKeyPath: KeyPathExprSyntax, property: VariableDeclSyntax) -> AccessorDeclSyntax {
		var baseCode: CodeBlockItemListSyntax = """
let oldValue = self.\(raw: identifier.trimmed)
self.\(raw: self.modelIDProperty(forPropertyNamed: identifier)) = newValue?.id
self.didChangeRelationship(\\.\(raw: identifier.trimmed), inverseKeyPath: \(raw: inverseKeyPath.trimmed), oldValue: oldValue)
"""
		if let willSet = property.willSetBody?.statements {
			baseCode.insert("""
\(raw: willSet)

""", at: baseCode.startIndex)
		}
		if let didSet = property.didSetBody?.statements {
			baseCode.append("""

\(raw: didSet)
""")
		}

		return """
set {
	\(raw: baseCode)
}
"""
	}
}

extension RelationshipMacro: PeerMacro {
	public static func expansion(of node: AttributeSyntax,
								 providingPeersOf declaration: some DeclSyntaxProtocol,
								 in context: some MacroExpansionContext) throws -> [DeclSyntax] {
		guard let property = declaration.as(VariableDeclSyntax.self) else {
			return []
		}

		guard let name = property.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier else {
			return []
		}
		return ["private var \(raw: self.modelIDProperty(forPropertyNamed: name)): ModelID?"]
	}
}
