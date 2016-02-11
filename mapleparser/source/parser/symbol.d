module mlfe.mapleparser.parser.symbol;

import mlfe.mapleparser.parser.base;
import mlfe.mapleparser.parser.exceptions;
import mlfe.mapleparser.parser.expression;
import mlfe.mapleparser.lexer.token;
import std.algorithm, std.range;

/// TemplateInstance = Identifier ["#" (SingleTemplateParameter | "(" TemplateParameterList ")")]
public static class TemplateInstance
{
	public static bool canParse(TokenList input) { return input.front.type == TokenType.Identifier; }
	public static TokenList parse(TokenList input)
	{
		auto in2 = input.consumeToken!(TokenType.Identifier);
		if(in2.front.type != TokenType.Sharp) return in2;
		if(in2.dropOne.front.type == TokenType.OpenParenthese)
		{
			return TemplateParameterList.parse(in2.drop(2)).consumeToken!(TokenType.CloseParenthese);
		}
		else return SingleTemplateParameter.parse(in2.dropOne);
	}
}

/// TemplateParameterList = TemplateParameter ("," TemplateParameter)*
public static class TemplateParameterList
{
	public static bool canParse(TokenList input) { return input.front.type == TokenType.Identifier; }
	public static TokenList parse(TokenList input)
	{
		static TokenList loop(TokenList input)
		{
			return input.front.type == TokenType.Comma ? loop(TemplateParameter.parse(input.dropOne)) : input;
		}
		return loop(TemplateParameter.parse(input));
	}
}

/// TemplateParameter = Expression
public static class TemplateParameter
{
	public static bool canParse(TokenList input)
	{
		return Expression.canParse(input);
	}
	public static TokenList parse(TokenList input)
	{
		return Expression.parse(input);
	}
}
/// SingleTemplateParameter = Identifier | Literal | SpecialLiteral | ComplexLiteral
public static class SingleTemplateParameter
{
	public static bool canParse(TokenList input)
	{
		return input.front.type == TokenType.Identifier ||
			Literal.canParse(input) || SpecialLiteral.canParse(input) || ComplexLiteral.canParse(input);
	}
	public static TokenList parse(TokenList input)
	{
		if(input.front.type == TokenType.Identifier) return input.dropOne;
		if(Literal.canParse(input)) return Literal.parse(input);
		if(SpecialLiteral.canParse(input)) return SpecialLiteral.parse(input);
		if(ComplexLiteral.canParse(input)) return ComplexLiteral.parse(input);
		throw new ParseException("No match rules found", input.front.at);
	}
}
