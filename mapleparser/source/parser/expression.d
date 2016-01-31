module mlfe.mapleparser.parser.expression;

import mlfe.mapleparser.parser.base;
import mlfe.mapleparser.lexer.token;
import mlfe.mapleparser.parser.exceptions;
import std.algorithm, std.range;

/// Expression = PrimaryExpression
public static class Expression
{
	public static bool canParse(TokenList input)
	{
		return PrimaryExpression.canParse(input);
	}
	public static TokenList parse(TokenList input)
	{
		return PrimaryExpression.parse(input);
	}
}

/// PrimaryExpression = Literal | SpecialLiteral | "(" Expression ")"
public static class PrimaryExpression
{
	public static bool canParse(TokenList input)
	{
		return input.front.type == TokenType.OpenParenthese || Literal.canParse(input) || SpecialLiteral.canParse(input);
	}
	public static TokenList parse(TokenList input)
	{
		if(input.front.type == TokenType.OpenParenthese)
		{
			return Expression.parse(input.dropOne).consumeToken!(TokenType.CloseParenthese);
		}
		if(Literal.canParse(input)) return Literal.parse(input);
		if(SpecialLiteral.canParse(input)) return SpecialLiteral.parse(input);
		throw new ParseException("No match rules found", input.front.at);
	}
}

/// Literal(Set of Tokens) = [NumericLiteral] | [FloatLiteral] | [DoubleLiteral] | [StringLiteral] | [CharacterLiteral]
///			| [LongLiteral] | [UlongLiteral]
public static class Literal
{
	public static bool canParse(TokenList input)
	{
		return [TokenType.NumericLiteral, TokenType.FloatLiteral, TokenType.DoubleLiteral,
			TokenType.StringLiteral, TokenType.CharacterLiteral, TokenType.LongLiteral, TokenType.UlongLiteral]
			.any!(a => a == input.front.type);
	}
	public static TokenList parse(TokenList input)
	{
		switch(input.front.type)
		{
		case TokenType.NumericLiteral: return input.dropOne;
		case TokenType.FloatLiteral: return input.dropOne;
		case TokenType.DoubleLiteral: return input.dropOne;
		case TokenType.StringLiteral: return input.dropOne;
		case TokenType.CharacterLiteral: return input.dropOne;
		case TokenType.LongLiteral: return input.dropOne;
		case TokenType.UlongLiteral: return input.dropOne;
		default: throw new ParseException("No match tokens found", input.front.at);
		}
	}
}

/// SpecialLiteral = "this" | "super"
public static class SpecialLiteral
{
	public static bool canParse(TokenList input)
	{
		return [TokenType.This, TokenType.Super].any!(a => a == input.front.type);
	}
	public static TokenList parse(TokenList input)
	{
		switch(input.front.type)
		{
		case TokenType.This: return input.dropOne;
		case TokenType.Super: return input.dropOne;
		default: throw new ParseException("No match tokens found", input.front.at);
		}
	}
}
