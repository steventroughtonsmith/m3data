//
//  SwiftSyntaxExtensions.swift
//
//
//  Created by Martin Pilkington on 24/12/2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension TokenKind {
	func isKeyword(_ keywords: Keyword...) -> Bool {
		guard case .keyword(let keyword) = self else {
			return false
		}
		return keywords.contains(keyword)
	}
}

extension VariableDeclSyntax {
	var bindingIdentifier: IdentifierPatternSyntax? {
		return self.bindings.first?.pattern.as(IdentifierPatternSyntax.self)
	}

	var bindingType: TypeSyntax? {
		guard let binding = self.bindings.first else {
			return nil
		}

		if let type = binding.typeAnnotation?.type {
			return type
		}

		guard let initializer = binding.initializer?.value else {
			return nil
		}

		if let function = initializer.as(FunctionCallExprSyntax.self) {
			guard let identifier = function.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName else {
				return nil
			}
			return IdentifierTypeSyntax(name: identifier).as(TypeSyntax.self)
		}

		if initializer.as(IntegerLiteralExprSyntax.self) != nil {
			let token: TokenSyntax = "Int"
			return IdentifierTypeSyntax(name: token).as(TypeSyntax.self)
		}

		if initializer.as(FloatLiteralExprSyntax.self) != nil {
			let token: TokenSyntax = "Float"
			return IdentifierTypeSyntax(name: token).as(TypeSyntax.self)
		}

		if initializer.as(BooleanLiteralExprSyntax.self) != nil {
			let token: TokenSyntax = "Bool"
			return IdentifierTypeSyntax(name: token).as(TypeSyntax.self)
		}

		return nil
	}

	func withAccess(_ access: String) -> VariableDeclSyntax {
		var variable = self
		let newAccess = DeclModifierSyntax(name: "private", trailingTrivia: .space)
		variable.modifiers = [newAccess] + variable.modifiers.filter {
			$0.name.tokenKind.isKeyword(.fileprivate, .private, .internal, .public) == false
		}
		return variable
	}

	func withName(_ name: String) -> VariableDeclSyntax {
		guard
			var privateBinding = bindings.first,
			var privateIdentifier = privateBinding.pattern.as(IdentifierPatternSyntax.self)
		else {
			return self
		}

		privateIdentifier.identifier = TokenSyntax(stringLiteral: name)
		privateBinding.pattern = privateIdentifier.as(PatternSyntax.self)!

		var variable = self
		variable.bindings = PatternBindingListSyntax([privateBinding])
		return variable
	}
}
