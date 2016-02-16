module mlfe.mapleparser.parser.type;

import mlfe.mapleparser.parser.base;
import mlfe.mapleparser.parser.symbol;
import mlfe.mapleparser.parser.expression;
import mlfe.mapleparser.parser.exceptions;
import mlfe.mapleparser.lexer.token;
import std.algorithm, std.range;

/// BuiltinType(Set of tokens) = "void" | "char" | "uchar" | "byte" | "short" | "ushort" | "word"
///			| "int" | "uint" | "dword" | "long" | "ulong" | "qword" | "float" | "double"
public ParseResult matchBuiltinType(ParseResult input)
{
	return input.selectByType!(
		TokenType.Void, x => Cont(x.dropOne),
		TokenType.Char, x => Cont(x.dropOne),
		TokenType.Uchar, x => Cont(x.dropOne),
		TokenType.Byte, x => Cont(x.dropOne),
		TokenType.Short, x => Cont(x.dropOne),
		TokenType.Ushort, x => Cont(x.dropOne),
		TokenType.Word, x => Cont(x.dropOne),
		TokenType.Int, x => Cont(x.dropOne),
		TokenType.Uint, x => Cont(x.dropOne),
		TokenType.Dword, x => Cont(x.dropOne),
		TokenType.Long, x => Cont(x.dropOne),
		TokenType.Ulong, x => Cont(x.dropOne),
		TokenType.Qword, x => Cont(x.dropOne),
		TokenType.Float, x => Cont(x.dropOne),
		TokenType.Double, x => Cont(x.dropOne)
	);
}
/// BasicType = BuiltinType / TemplateInstance ("." TemplateInstance)*
///	/ "." TemplateInstance ("." TemplateInstance)*
/// / "global" "." TemplateInstance ("." TemplateInstance)*
public ParseResult matchBasicType(ParseResult input)
{
	return input.select!(
		x => x.matchBuiltinType,
		x => x.matchToken!(TokenType.Global).matchToken!(TokenType.Period)
			.matchTemplateInstance.matchUntilFail!(y => y.matchToken!(TokenType.Period).matchTemplateInstance),
		x => x.matchToken!(TokenType.Period).matchTemplateInstance
			.matchUntilFail!(y => y.matchToken!(TokenType.Period).matchTemplateInstance),
		x => x.matchTemplateInstance.matchUntilFail!(y => y.matchToken!(TokenType.Period).matchTemplateInstance)
	);
}

/// ConstructableType = "const" "(" Type ")" / "(" Type ")" / BasicType
public ParseResult matchConstructableType(ParseResult input)
{
	return input.select!(
		x => x.matchToken!(TokenType.Const).matchToken!(TokenType.OpenParenthese)
			.matchType.matchToken!(TokenType.CloseParenthese),
		x => x.matchToken!(TokenType.OpenParenthese).matchType.matchToken!(TokenType.CloseParenthese),
		x => x.matchBasicType
	);
}
/// Type = ConstructableType ("[" [Expression] "]")*
public ParseResult matchType(ParseResult input)
{
	return input.matchConstructableType
		.matchUntilFail!(x => x.matchToken!(TokenType.OpenBracket).ignorable!matchExpression
			.matchToken!(TokenType.CloseBracket));
}

/// InferableConstructableType = "const" "(" InferableType ")" / "(" InferableType ")" | "auto" | BasicType
public ParseResult matchInferableConstructableType(ParseResult input)
{
	return input.select!(
		x => x.matchToken!(TokenType.Const).matchToken!(TokenType.OpenParenthese)
			.matchType.matchToken!(TokenType.CloseParenthese),
		x => x.matchToken!(TokenType.OpenParenthese).matchType.matchToken!(TokenType.CloseParenthese),
		x => x.matchToken!(TokenType.Auto),
		x => x.matchBasicType
	);
}
/// InferableType = InferableConstructableType ("[" [Expression] "]")*
public ParseResult matchInferableType(ParseResult input)
{
	return input.matchInferableConstructableType
		.matchUntilFail!(x => x.matchToken!(TokenType.OpenBracket).ignorable!matchExpression
			.matchToken!(TokenType.CloseBracket));
}
unittest
{
	import mlfe.mapleparser.lexer : asTokenList;
	assert(Cont("float".asTokenList).matchInferableType.succeeded);
	assert(Cont("const(char)[]".asTokenList).matchInferableType.succeeded);
	assert(Cont("const(Tuple#auto[])[2]".asTokenList).matchInferableType.succeeded);
}
