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

public struct RelationshipMacro {}

extension RelationshipMacro: AccessorMacro {
	public static func expansion(of node: AttributeSyntax,
								 providingAccessorsOf declaration: some DeclSyntaxProtocol,
								 in context: some MacroExpansionContext) throws -> [AccessorDeclSyntax] {
		return [
   """
   get { return nil }
   """,
   """
set {}
"""
		]
	}
//		guard
//			let property = declaration.as(VariableDeclSyntax.self),
//			let identifier = property.bindingIdentifier?.identifier,
//			case .argumentList(let arguments) = node.arguments,
//			let inverseKeyPath = arguments.first?.expression.as(KeyPathExprSyntax.self)
//		else {
//			return []
//		}
//
//		switch self.relationshipType(for: property) {
//		case .unknown:
//			return []
//		case .toOne(let type):
//			return try self.toOneRelationship(identifier, inverseRelationship: inverseKeyPath, type: type)
//		case .toMany:
//			return try self.toManyRelationship(inverseRelationship: inverseKeyPath)
//		}
//	}
//
//	enum RelationshipType {
//		case unknown
//		case toOne(TokenSyntax)
//		case toMany(TokenSyntax)
//	}
//
//	private static func relationshipType(for property: VariableDeclSyntax) -> RelationshipType {
//		guard let bindingType = property.bindingType else {
//			return .unknown
//		}
//
//		if let binding = bindingType.as(IdentifierTypeSyntax.self),
//		   binding.name.tokenKind == .identifier("Set"),
//		   let arguments = binding.genericArgumentClause?.arguments,
//		   arguments.count == 1,
//		   let genericIdentifier = arguments.first?.argument.as(IdentifierTypeSyntax.self)
//		{
//			return .toMany(genericIdentifier.name)
//		}
//
//		if let binding = bindingType.as(OptionalTypeSyntax.self),
//		   let typeName = binding.wrappedType.as(IdentifierTypeSyntax.self)?.name {
//			return .toOne(typeName)
//		}
//
//
//		return .unknown
//	}
//
//	private static func toOneRelationship(_ variableName: TokenSyntax, inverseRelationship: KeyPathExprSyntax, type: TokenSyntax) throws -> [AccessorDeclSyntax] {
//		let get: AccessorDeclSyntax =
//		"""
//		get {
//			guard let objectID = self._\(raw: variableName) else {
//				return nil
//			}
//			return self.modelController?.collection(for: \(raw: type).self).objectWithID(objectID)
//		}
//		"""
//		let set: AccessorDeclSyntax =
//		"""
//		set {
//			let oldValue = self.\(raw: variableName)
//			self._\(raw: variableName) = newValue?.id
//			self.didChangeRelationship(\\.\(raw: variableName), inverseKeyPath: \(raw: inverseRelationship), oldValue: oldValue)
//		}
//		"""
//		return [get, set]
//	}
//
//	private static func toManyRelationship(inverseRelationship: KeyPathExprSyntax) throws -> [AccessorDeclSyntax] {
//		return [
//			"""
//			get {
//				return self.relationship(for: \(raw: inverseRelationship))
//			}
//			"""
//		]
//	}
}

extension RelationshipMacro: PeerMacro {
	public static func expansion(of node: AttributeSyntax,
								 providingPeersOf declaration: some DeclSyntaxProtocol,
								 in context: some MacroExpansionContext) throws -> [DeclSyntax] {
//		guard let property = declaration.as(VariableDeclSyntax.self) else {
//			return []
//		}
//
//		guard let name = property.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
//			return []
//		}
//		return ["private var _\(raw: name): ModelID?"]
		return []
	}
}




public struct Relationship2Macro {}

extension Relationship2Macro: AccessorMacro {
	public static func expansion(of node: AttributeSyntax,
								 providingAccessorsOf declaration: some DeclSyntaxProtocol,
								 in context: some MacroExpansionContext) throws -> [AccessorDeclSyntax] {
		return [
			"""
			get { return [] }
			"""
		]
//		guard
//			let property = declaration.as(VariableDeclSyntax.self),
//			let identifier = property.bindingIdentifier?.identifier,
//			case .argumentList(let arguments) = node.arguments,
//			let inverseKeyPath = arguments.first?.expression.as(KeyPathExprSyntax.self)
//		else {
//			return []
//		}
//
//		switch self.relationshipType(for: property) {
//		case .unknown:
//			return []
//		case .toOne(let type):
//			return try self.toOneRelationship(identifier, inverseRelationship: inverseKeyPath, type: type)
//		case .toMany:
//			return try self.toManyRelationship(inverseRelationship: inverseKeyPath)
//		}
//	}
//
//	enum Relationship2Type {
//		case unknown
//		case toOne(TokenSyntax)
//		case toMany(TokenSyntax)
//	}
//
//	private static func relationshipType(for property: VariableDeclSyntax) -> Relationship2Type {
//		guard let bindingType = property.bindingType else {
//			return .unknown
//		}
//
//		if let binding = bindingType.as(IdentifierTypeSyntax.self),
//		   binding.name.tokenKind == .identifier("Set"),
//		   let arguments = binding.genericArgumentClause?.arguments,
//		   arguments.count == 1,
//		   let genericIdentifier = arguments.first?.argument.as(IdentifierTypeSyntax.self)
//		{
//			return .toMany(genericIdentifier.name)
//		}
//
//		if let binding = bindingType.as(OptionalTypeSyntax.self),
//		   let typeName = binding.wrappedType.as(IdentifierTypeSyntax.self)?.name {
//			return .toOne(typeName)
//		}
//
//
//		return .unknown
//	}
//
//	private static func toOneRelationship(_ variableName: TokenSyntax, inverseRelationship: KeyPathExprSyntax, type: TokenSyntax) throws -> [AccessorDeclSyntax] {
//		let get: AccessorDeclSyntax =
//			"""
//			get {
//				guard let objectID = self._\(raw: variableName) else {
//					return nil
//				}
//				return self.modelController?.collection(for: \(raw: type).self).objectWithID(objectID)
//			}
//			"""
//		let set: AccessorDeclSyntax =
//			"""
//			set {
//				let oldValue = self.\(raw: variableName)
//				self._\(raw: variableName) = newValue.id
//				self.didChangeRelationship(\\.\(raw: variableName), inverseKeyPath: \(raw: inverseRelationship), oldValue: oldValue)
//			}
//			"""
//		return [get, set]
//	}
//
//	private static func toManyRelationship(inverseRelationship: KeyPathExprSyntax) throws -> [AccessorDeclSyntax] {
//		return [
//			"""
//			get {
//				return self.relationship(for: \(raw: inverseRelationship))
//			}
//			"""
//		]
	}
}

extension Relationship2Macro: PeerMacro {
	public static func expansion(of node: AttributeSyntax,
								 providingPeersOf declaration: some DeclSyntaxProtocol,
								 in context: some MacroExpansionContext) throws -> [DeclSyntax] {
		return []
//		guard let property = declaration.as(VariableDeclSyntax.self) else {
//			return []
//		}
//
//		guard let name = property.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
//			return []
//		}
//		return ["private var _\(raw: name): ModelID?"]
	}
}

