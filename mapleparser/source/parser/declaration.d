module mlfe.mapleparser.parser.declaration;

// Parser Rule of declarations //

import mlfe.mapleparser.parser.base;
import mlfe.mapleparser.lexer;
import mlfe.mapleparser.parser.statement;
import mlfe.mapleparser.parser.symbol;
import mlfe.mapleparser.parser.type;
import mlfe.mapleparser.parser.expression;
import std.range;

/// FieldDeclaration = FieldDeclarationSameAsLocalVar / FieldDeclarationNormal
public ParseResult matchFieldDeclaration(ParseResult input)
{
	return input.select!(matchFieldDeclarationSameAsLocalVar, matchFieldDeclarationNormal);
}
unittest
{
	auto tester(string input)() { return Cont(input.asTokenList).matchFieldDeclaration.succeeded; }

	assert(tester!"public int flag = 0;");
	assert(tester!"public T value[T];");
	assert(tester!"public float x, y, w, h;");
	assert(tester!"private val Width = 640;");
	assert(tester!"private const int valT = 10;");
}
/// FieldDeclarationSameAsLocalVar = FieldQualifierWithoutConst*
///		("var" / "val" / "const" [InferableType] / InferableType) FieldDeclarationList ";"
public ParseResult matchFieldDeclarationSameAsLocalVar(ParseResult input)
{
	return input.matchUntilFail!matchFieldQualifierWithoutConst.
		select!(matchToken!(TokenType.Var), matchToken!(TokenType.Val),
			x => x.matchToken!(TokenType.Const).ignorable!matchInferableType, matchInferableType)
		.matchFieldDeclarationList.matchToken!(TokenType.Semicolon);
}
/// FieldDeclarationNormal = (FieldQualifier FieldQualifier* InferableType / FieldQualifier FieldQualifier*
///		/ InferableType) FieldDeclarationList ";"
public ParseResult matchFieldDeclarationNormal(ParseResult input)
{
	return input.select!(
		x => x.matchFieldQualifier.matchUntilFail!matchFieldQualifier.matchInferableType,
		x => x.matchFieldQualifier.matchUntilFail!matchFieldQualifier,
		x => x.matchInferableType
	).matchFieldDeclarationList.matchToken!(TokenType.Semicolon);
}
/// FieldDeclarationList = FieldDeclarationBody ("," FieldDeclarationBody)*
public ParseResult matchFieldDeclarationList(ParseResult input)
{
	return input.matchFieldDeclarationBody.matchUntilFail!(x => x.matchToken!(TokenType.Comma).matchFieldDeclarationBody);
}
/// FieldDeclarationBody = DeclarationName ["=" Expression]
public ParseResult matchFieldDeclarationBody(ParseResult input)
{
	return input.matchDeclarationName.ignorable!(x => x.matchToken!(TokenType.Equal).matchExpression);
}

/// MethodDeclaration = (MethodQualifier MethodQualifier* InferableType DeclarationName
///		/ MethodQualifier MethodQualifier* DeclarationName / InferableType DeclarationName)
///		"(" [VirtualArgList] ")" (Statement / "=" Expression ";")
public ParseResult matchMethodDeclaration(ParseResult input)
{
	return input.select!(
		x => x.matchMethodQualifier.matchUntilFail!matchMethodQualifier.matchInferableType.matchDeclarationName,
		x => x.matchMethodQualifier.matchUntilFail!matchMethodQualifier.matchDeclarationName,
		x => x.matchInferableType.matchDeclarationName
	).matchToken!(TokenType.OpenParenthese).ignorable!matchVirtualArgList.matchToken!(TokenType.CloseParenthese)
	.select!(matchStatement, x => x.matchToken!(TokenType.Equal).matchExpression.matchToken!(TokenType.Semicolon));
}
unittest
{
	auto tester(string input)()
	{
		return Cont(input.asTokenList).matchMethodDeclaration.succeeded;
	}

	assert(tester!"public auto main(String[] args) { return 0; }");
	assert(tester!"private static main(String[] args) System.out.writeln(args.length);");
	assert(tester!"auto add[T](T a, T b) = a + b;");
}
/// PropertyDeclaration = MethodQualifier* "property" (InferableType DeclarationName / DeclarationName)
///	["(" [VirtualArgList] ")"] (Statement / "=" Expression ";")
public ParseResult matchPropertyDeclaration(ParseResult input)
{
	return input.matchUntilFail!matchMethodQualifier.matchToken!(TokenType.Property)
		.select!(x => x.matchInferableType.matchDeclarationName, x => x.matchDeclarationName)
		.ignorable!(x => x.matchToken!(TokenType.OpenParenthese).ignorable!matchVirtualArgList
				.matchToken!(TokenType.CloseParenthese))
		.select!(matchStatement, x => x.matchToken!(TokenType.Equal).matchExpression.matchToken!(TokenType.Semicolon));
}
unittest
{
	auto tester(string input)()
	{
		return Cont(input.asTokenList).matchPropertyDeclaration.succeeded;
	}
	assert(tester!"public property isEmpty = this.array.length <= 0;");
	assert(tester!"public property bool isEmpty { return this.array.isEmpty; }");
	assert(tester!"private property arraySize(int i) this.array.length = i;");
	assert(tester!"private property arraySizeAs[T]() = this.array.length -> T;");
}
/// FieldQualifier = "public" / "private" / "protected" / "static" / "const"
public ParseResult matchFieldQualifier(ParseResult input)
{
	return input.selectByType!(
		TokenType.Public, x => Cont(x.dropOne),
		TokenType.Private, x => Cont(x.dropOne),
		TokenType.Protected, x => Cont(x.dropOne),
		TokenType.Static, x => Cont(x.dropOne),
		TokenType.Const, x => Cont(x.dropOne)
	);
}
/// FieldQualifierWithoutConst = "public" / "private" / "protected" / "static"
public ParseResult matchFieldQualifierWithoutConst(ParseResult input)
{
	return input.selectByType!(
		TokenType.Public, x => Cont(x.dropOne),
		TokenType.Private, x => Cont(x.dropOne),
		TokenType.Protected, x => Cont(x.dropOne),
		TokenType.Static, x => Cont(x.dropOne)
	);
}
/// MethodQualifier = "public" / "private" / "protected" / "static" / "override" / "const" / "final"
public ParseResult matchMethodQualifier(ParseResult input)
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
	auto tester(string t)() { return Cont(t.asTokenList).matchStaticBlock.succeeded; }

	assert(tester!"static { System.out.writeln(\"Hello, World.\"); }");
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
		.ignorable!(x => x.matchToken!(TokenType.OpenBracket).matchGenericsParameterList
			.matchToken!(TokenType.CloseBracket));
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

