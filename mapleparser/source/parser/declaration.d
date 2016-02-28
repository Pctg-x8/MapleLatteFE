module mlfe.mapleparser.parser.declaration;

// Parser Rule of declarations //

import mlfe.mapleparser.parser.base;
import mlfe.mapleparser.lexer;
import mlfe.mapleparser.parser.statement;
import mlfe.mapleparser.parser.symbol;
import mlfe.mapleparser.parser.type;
import mlfe.mapleparser.parser.expression;
import std.range;

/// Declarations = ClassDeclaration / TraitDeclaration / EnumDeclaration / TemplateDeclaration / AliasDeclaration
///		/ FieldDeclaration / MethodDeclaration / PropertyDeclaration
public ParseResult matchDeclarations(ParseResult input)
{
	return input.select!(matchClassDeclaration, matchTraitDeclaration, matchEnumDeclaration, matchTemplateDeclaration,
		matchAliasDeclaration, matchFieldDeclaration, matchMethodDeclaration, matchPropertyDeclaration);
}
unittest
{
	auto tester(string t)() { return Cont(t.asTokenList).matchDeclarations.succeeded; }

	assert(tester!"public class Main extends Application {}");
	assert(tester!"public partial class Main extends Application with IStream { public static void main() return; }");
	assert(tester!"class test[T] { private val cval = 0 -> T; }");
	assert(tester!"public class ID { public template(string T) void write() io.writeln(T); }");
	assert(tester!"public trait ID3D12DeviceChild with IUnknown {}");
	assert(tester!"public alias T = int;");
	assert(tester!"public template Identification(string ID) { public val name = ID; }");
}

/// ClassDeclaration = Qualifier* "class" DeclarationName [ExtendsClause] WithClause* ClassBody
public ParseResult matchClassDeclaration(ParseResult input)
{
	return input.matchUntilFail!matchQualifier.matchToken!(TokenType.Class).matchDeclarationName
		.ignorable!matchExtendsClause.matchUntilFail!matchWithClause.matchClassBody;
}
/// ExtendsClause = "extends" Type
public ParseResult matchExtendsClause(ParseResult input)
{
	return input.matchToken!(TokenType.Extends).matchType;
}
/// WithClause = "with" Type
public ParseResult matchWithClause(ParseResult input)
{
	return input.matchToken!(TokenType.With).matchType;
}
/// ClassBody = "{" Declarations* "}"
public ParseResult matchClassBody(ParseResult input)
{
	return input.matchToken!(TokenType.OpenBrace).matchUntilFail!matchDeclarations
		.matchToken!(TokenType.CloseBrace);
}
/// TraitDeclaration = Qualifier* "trait" DeclarationName WithClause* TraitBody
public ParseResult matchTraitDeclaration(ParseResult input)
{
	return input.matchUntilFail!matchQualifier.matchToken!(TokenType.Trait).matchDeclarationName
		.matchUntilFail!matchWithClause.matchTraitBody;
}
/// TraitBody = "{" (FieldDeclaration / MethodDeclaration / PropertyDeclaration)* "}"
public ParseResult matchTraitBody(ParseResult input)
{
	return input.matchToken!(TokenType.OpenBrace)
		.matchUntilFail!(select!(matchFieldDeclaration, matchMethodDeclaration, matchPropertyDeclaration))
		.matchToken!(TokenType.CloseBrace);
}

/// EnumDeclaration = Qualifier* "enum" Identifier "{" [EnumItemDeclaration ("," EnumItemDeclaration)*] [","] "}"
public ParseResult matchEnumDeclaration(ParseResult input)
{
	return input.matchUntilFail!matchQualifier.matchToken!(TokenType.Enum).matchToken!(TokenType.Identifier)
		.matchToken!(TokenType.OpenBrace).ignorable!(
			x => x.matchEnumItemDeclaration.matchUntilFail!(y => y.matchToken!(TokenType.Comma).matchEnumItemDeclaration)
		).ignorable!(matchToken!(TokenType.Comma)).matchToken!(TokenType.CloseBrace);
}
/// EnumItemDeclaration = Identifier ["=" Expression]
public ParseResult matchEnumItemDeclaration(ParseResult input)
{
	return input.matchToken!(TokenType.Identifier).ignorable!(x => x.matchToken!(TokenType.Equal).matchExpression);
}

/// TemplateDeclaration = ualifier* "template" [Identifier] "(" [TemplateVirtualParams] ")"
///		(Declarations / "{" Declarations* "}")
public ParseResult matchTemplateDeclaration(ParseResult input)
{
	return input.matchUntilFail!matchQualifier.matchToken!(TokenType.Template)
		.ignorable!(matchToken!(TokenType.Identifier))
		.matchToken!(TokenType.OpenParenthese).ignorable!matchTemplateVirtualParams
		.matchToken!(TokenType.CloseParenthese).select!(
			matchDeclarations,
			x => x.matchToken!(TokenType.OpenBrace).matchUntilFail!matchDeclarations.matchToken!(TokenType.CloseBrace)
		);
}
/// TemplateVirtualParams = TemplateVirtualParam ("," TemplateVirtualParam)
public ParseResult matchTemplateVirtualParams(ParseResult input)
{
	return input.matchTemplateVirtualParam.matchUntilFail!(x => x.matchToken!(TokenType.Comma).matchTemplateVirtualParam);
}
/// TemplateVirtualParam = ["alias" / Type] Identifier ["=" (Expression / Type)]
public ParseResult matchTemplateVirtualParam(ParseResult input)
{
	return input.ignorable!(select!(matchToken!(TokenType.Alias), matchType)).matchToken!(TokenType.Identifier)
		.ignorable!(x => x.matchToken!(TokenType.Equal).select!(matchExpression, matchType));
}

/// AliasDeclaration = Qualifier* "alias" DeclarationName "=" (Expression / Type) ";"
public ParseResult matchAliasDeclaration(ParseResult input)
{
	return input.matchUntilFail!matchQualifier.matchToken!(TokenType.Alias).matchDeclarationName
		.matchToken!(TokenType.Equal).select!(matchExpression, matchType).matchToken!(TokenType.Semicolon);
}

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
/// FieldDeclarationSameAsLocalVar = QualifierWithoutConst*
///		("var" / "val" / "const" [InferableType] / InferableType) FieldDeclarationList ";"
public ParseResult matchFieldDeclarationSameAsLocalVar(ParseResult input)
{
	return input.matchUntilFail!matchQualifierWithoutConst.
		select!(matchToken!(TokenType.Var), matchToken!(TokenType.Val),
			x => x.matchToken!(TokenType.Const).ignorable!matchInferableType, matchInferableType)
		.matchFieldDeclarationList.matchToken!(TokenType.Semicolon);
}
/// FieldDeclarationNormal = (Qualifier Qualifier* InferableType / Qualifier Qualifier*
///		/ InferableType) FieldDeclarationList ";"
public ParseResult matchFieldDeclarationNormal(ParseResult input)
{
	return input.select!(
		x => x.matchQualifier.matchUntilFail!matchQualifier.matchInferableType,
		x => x.matchQualifier.matchUntilFail!matchQualifier,
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

/// MethodDeclaration = (Qualifier Qualifier* InferableType DeclarationName
///		/ Qualifier Qualifier* DeclarationName / InferableType DeclarationName)
///		"(" [VirtualArgList] ")" (Statement / "=" Expression ";")
public ParseResult matchMethodDeclaration(ParseResult input)
{
	return input.select!(
		x => x.matchQualifier.matchUntilFail!matchQualifier.matchInferableType.matchDeclarationName,
		x => x.matchQualifier.matchUntilFail!matchQualifier.matchDeclarationName,
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
/// PropertyDeclaration = Qualifier* "property" (InferableType DeclarationName / DeclarationName)
///	["(" [VirtualArgList] ")"] (Statement / "=" Expression ";")
public ParseResult matchPropertyDeclaration(ParseResult input)
{
	return input.matchUntilFail!matchQualifier.matchToken!(TokenType.Property)
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
/// Qualifier = "public" / "private" / "protected" / "static" / "partial" / "override" / "const" / "final"
public ParseResult matchQualifier(ParseResult input)
{
	return input.selectByType!(
		TokenType.Public, x => Cont(x.dropOne),
		TokenType.Private, x => Cont(x.dropOne),
		TokenType.Protected, x => Cont(x.dropOne),
		TokenType.Static, x => Cont(x.dropOne),
		TokenType.Partial, x => Cont(x.dropOne),
		TokenType.Override, x => Cont(x.dropOne),
		TokenType.Const, x => Cont(x.dropOne),
		TokenType.Final, x => Cont(x.dropOne)
	);
}
/// QualifierWithoutConst = "public" / "private" / "protected" / "static" / "partial" / "override" / "final"
public ParseResult matchQualifierWithoutConst(ParseResult input)
{	
	return input.selectByType!(
		TokenType.Public, x => Cont(x.dropOne),
		TokenType.Private, x => Cont(x.dropOne),
		TokenType.Protected, x => Cont(x.dropOne),
		TokenType.Static, x => Cont(x.dropOne),
		TokenType.Partial, x => Cont(x.dropOne),
		TokenType.Override, x => Cont(x.dropOne),
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

