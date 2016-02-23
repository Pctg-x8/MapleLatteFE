module mlfe.mapleparser.parser.declaration;

// Parser Rule of declarations //

import mlfe.mapleparser.parser.base;
import mlfe.mapleparser.lexer;
import mlfe.mapleparser.parser.statement;
import mlfe.mapleparser.parser.symbol;
import mlfe.mapleparser.parser.type;
import mlfe.mapleparser.parser.expression;
import std.range;

/// PropertyDeclaration = PropertyQualifier* "property" [InferableType] DeclarationName ["(" [VirtualArgList] ")"] (Statement / "=" Expression ";")
public ParseResult matchPropertyDeclaration(ParseResult input)
{
	return input.matchUntilFail!matchPropertyQualifier.matchToken!(TokenType.Property).ignorable!matchInferableType.matchDeclarationName
		.ignorable!(x => x.matchToken!(TokenType.OpenParenthese).ignorable!matchVirtualArgList.matchToken!(TokenType.CloseParenthese))
		.select!(matchStatement, x => x.matchToken!(TokenType.Equal).matchExpression.matchToken!(TokenType.Semicolon));
}
unittest
{
	assert(Cont("public property isEmpty = this.array.length <= 0;".asTokenList).matchPropertyDeclaration.succeeded);
	assert(Cont("public property bool isEmpty { return this.array.isEmpty; }".asTokenList).matchPropertyDeclaration.succeeded);
	assert(Cont("private property arraySize(int i) this.array.length = i;".asTokenList).matchPropertyDeclaration.succeeded);
	assert(Cont("private property arraySizeAs[T]() = this.array.length -> T;".asTokenList).matchPropertyDeclaration.succeeded);
}
/// PropertyQualifier = "public" / "private" / "protected" / "static" / "override" / "const" / "final"
public ParseResult matchPropertyQualifier(ParseResult input)
{
	return input.selectByType!(
		TokenType.Public, x => Cont(x.dropOne),
		TokenType.Private, x => Cont(x.dropOne),
		TokenType.Protected, x => Cont(x.dropOne),
		TokenType.Static, x => Cont(x.dropOne),
		TokenType.Override, x => Cont(x.dropOne),
		TokenType.Const, x => Cont(x.dropOne),
		TokenType.Final, x => Cont(x.dropOne)
	);
}

/// StaticBlock = "static" StatementBlock
public ParseResult matchStaticBlock(ParseResult input)
{
	return input.matchToken!(TokenType.Static).matchStatementBlock;
}
unittest
{
	import mlfe.mapleparser.lexer : asTokenList;

	assert(Cont("static { System.out.writeln(\"Hello, World.\"); }".asTokenList).matchStaticBlock.succeeded);
}

/// VirtualArgList = VirtualArg ("," VirtualArg)*
public ParseResult matchVirtualArgList(ParseResult input)
{
	return input.matchVirtualArg.matchUntilFail!(x => x.matchToken!(TokenType.Comma).matchVirtualArg);
}
/// VirtualArg = Type [Identifier]
public ParseResult matchVirtualArg(ParseResult input)
{
	return input.matchType.ignorable!(matchToken!(TokenType.Identifier));
}

/// DeclarationName = Identifier ["[" GenericsParameterList "]"]
public ParseResult matchDeclarationName(ParseResult input)
{
	return input.matchToken!(TokenType.Identifier)
		.ignorable!(x => x.matchToken!(TokenType.OpenBracket).matchGenericsParameterList.matchToken!(TokenType.CloseParenthese));
}
/// GenericsParameterList = GenericsParameter ("," GenericsParameter)*
public ParseResult matchGenericsParameterList(ParseResult input)
{
	return input.matchGenericsParameter.matchUntilFail!(x => x.matchToken!(TokenType.Comma).matchGenericsParameter);
}
/// GenericsParameter = Identifier [":" Type] ["=" Type]
public ParseResult matchGenericsParameter(ParseResult input)
{
	return input.matchToken!(TokenType.Identifier).ignorable!(x => x.matchToken!(TokenType.Colon).matchType)
		.ignorable!(x => x.matchToken!(TokenType.Equal).matchType);
}

