module mlfe.mapleparser.parser.symbol;

import mlfe.mapleparser.parser.base;
import mlfe.mapleparser.parser.exceptions;
import mlfe.mapleparser.parser.expression;
import mlfe.mapleparser.parser.type;
import mlfe.mapleparser.lexer.token;
import std.algorithm, std.range;

/// TemplateInstance = Identifier ["#" (SingleTemplateParameter | "(" TemplateParameterList ")")]
public static class TemplateInstance
{
	public static bool canParse(TokenList input) { return input.front.type == TokenType.Identifier; }
	public static TokenList drops(TokenList input)
	{
		if(input.front.type != TokenType.Identifier) return input;
		if(input.dropOne.front.type != TokenType.Sharp) return input.dropOne;
		if(input.drop(2).front.type != TokenType.OpenParenthese) return SingleTemplateParameter.drops(input.drop(2));
		else
		{
			auto in2 = TemplateParameterList.drops(input.drop(3));
			if(in2.front.type != TokenType.CloseParenthese) return input;
			return in2.dropOne;
		}
	}
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
	public static TokenList drops(TokenList input)
	{
		static TokenList loop(TokenList input)
		{
			return input.front.type == TokenType.Comma ? loop(TemplateParameter.drops(input.dropOne)) : input;
		}
		return loop(TemplateParameter.drops(input));
	}
	public static TokenList parse(TokenList input)
	{
		static TokenList loop(TokenList input)
		{
			return input.front.type == TokenType.Comma ? loop(TemplateParameter.parse(input.dropOne)) : input;
		}
		return loop(TemplateParameter.parse(input));
	}
}

/// TemplateParameter = InferableType | Expression
public static class TemplateParameter
{
	public static bool canParse(TokenList input)
	{
		return InferableType.canParse(input) || Expression.canParse(input);
	}
	public static TokenList drops(TokenList input)
	{
		if(Type.canParse(input)) return InferableType.drops(input);
		else return Expression.drops(input);
	}
	public static TokenList parse(TokenList input)
	{
		if(Type.canParse(input)) return InferableType.parse(input);
		else return Expression.parse(input);
	}
}
/// SingleTemplateParameter = BuiltinType | Identifier | Literal | SpecialLiteral
public static class SingleTemplateParameter
{
	public static bool canParse(TokenList input)
	{
		return input.front.type == TokenType.Identifier ||
			BuiltinType.canParse(input) || Literal.canParse(input) || SpecialLiteral.canParse(input);
	}
	public static TokenList drops(TokenList input)
	{
		if(input.front.type == TokenType.Identifier) return input.dropOne;
		if(BuiltinType.canParse(input)) return BuiltinType.drops(input);
		if(Literal.canParse(input)) return Literal.drops(input);
		if(SpecialLiteral.canParse(input)) return SpecialLiteral.drops(input);
		return input;
	}
	public static TokenList parse(TokenList input)
	{
		if(input.front.type == TokenType.Identifier) return input.dropOne;
		if(BuiltinType.canParse(input)) return BuiltinType.parse(input);
		if(Literal.canParse(input)) return Literal.parse(input);
		if(SpecialLiteral.canParse(input)) return SpecialLiteral.parse(input);
		throw new ParseException("No match rules found", input.front.at);
	}
}
