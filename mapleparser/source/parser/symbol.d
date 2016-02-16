module mlfe.mapleparser.parser.symbol;

import mlfe.mapleparser.parser.base;
import mlfe.mapleparser.parser.exceptions;
import mlfe.mapleparser.parser.expression;
import mlfe.mapleparser.parser.type;
import mlfe.mapleparser.lexer.token;
import std.algorithm, std.range;

/// TemplateInstance = Identifier ["#" ("(" TemplateParameterList ")" / SingleTemplateParameter)]
public ParseResult matchTemplateInstance(ParseResult input)
{
	return input.matchToken!(TokenType.Identifier)
		.ignorable!(x => x.matchToken!(TokenType.Sharp).select!(
			x => x.matchToken!(TokenType.OpenParenthese).matchTemplateParameterList.matchToken!(TokenType.CloseParenthese),
			x => x.matchSingleTemplateParameter
		));
}
/// TemplateParameterList = TemplateParameter ("," TemplateParameter)*
public ParseResult matchTemplateParameterList(ParseResult input)
{
	return input.matchTemplateParameter
		.matchUntilFail!(x => x.matchToken!(TokenType.Comma).matchTemplateParameter);
}
/// TemplateParameter = InferableType | Expression
public ParseResult matchTemplateParameter(ParseResult input)
{
	return input.select!(matchInferableType, matchExpression);
}
/// SingleTemplateParameter = BuiltinType / Identifier / "auto" / Literal / SpecialLiteral
public ParseResult matchSingleTemplateParameter(ParseResult input)
{
	return input.select!(matchBuiltinType,
		matchToken!(TokenType.Identifier), matchToken!(TokenType.Auto),
		matchLiteral, matchSpecialLiteral);
}
