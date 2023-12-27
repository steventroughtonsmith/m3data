//
//  AttributeMacro.swift
//  
//
//  Created by Martin Pilkington on 21/12/2023.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct AttributeMacro {}

extension AttributeMacro: AccessorMacro {
	public static func expansion(of node: AttributeSyntax,
								 providingAccessorsOf declaration: some DeclSyntaxProtocol,
								 in context: some MacroExpansionContext) throws -> [AccessorDeclSyntax] {
		guard
			let property = declaration.as(VariableDeclSyntax.self),
			let identifier = property.bindingIdentifier?.identifier
		else {
			return []
		}

		let get: AccessorDeclSyntax = """
get { return self._\(raw: identifier) }
"""

		let set: AccessorDeclSyntax = """
set {
	let oldValue = self._\(raw: identifier)
	self._\(raw: identifier) = newValue
	self.didChange(\\.\(raw: identifier), oldValue: oldValue)
}
"""

		return [get, set]
	}
}

extension AttributeMacro: PeerMacro {
	public static func expansion(of node: AttributeSyntax,
								 providingPeersOf declaration: some DeclSyntaxProtocol,
								 in context: some MacroExpansionContext) throws -> [DeclSyntax] {
		guard let property = declaration.as(VariableDeclSyntax.self) else {
			return []
		}

		guard let name = property.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
			return []
		}
		var privateProperty = property.withAccess("private").withName("_\(name)")
		privateProperty.attributes = AttributeListSyntax()
		return [DeclSyntax(privateProperty)]
	}

}
