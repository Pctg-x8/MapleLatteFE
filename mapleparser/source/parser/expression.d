module mlfe.mapleparser.parser.expression;

import mlfe.mapleparser.parser.base;
import mlfe.mapleparser.lexer.token;
import mlfe.mapleparser.parser.exceptions;
import std.algorithm, std.range;

/// Expression = PrefixExpression
public static class Expression
{
	public static immutable canParse = &PrefixExpression.canParse;
	public static TokenList parse(TokenList input)
	{
		return PrefixExpression.parse(input);
	}
}
/// ExpressionList = Expression ("," Expression)*
public static class ExpressionList
{
	public static immutable canParse = &Expression.canParse;
	public static TokenList parse(TokenList input)
	{
		static TokenList loop(TokenList input)
		{
			return input.front.type == TokenType.Comma ? loop(Expression.parse(input.dropOne)) : input;
		}
		
		return loop(Expression.parse(input));
	}
}

/// PrefixExpression = "++" PrefixExpression | "--" PrefixExpression | "**" PrefixExpression
///		| "+" PrefixExpression | "-" PrefixExpression | PostfixExpression
public static class PrefixExpression
{
	public static bool canParse(TokenList input)
	{
		return PostfixExpression.canParse(input) || 
			[TokenType.Plus2, TokenType.Plus, TokenType.Minus2, TokenType.Minus, TokenType.Asterisk2]
			.any!(a => a == input.front.type);
	}
	public static TokenList parse(TokenList input)
	{
		switch(input.front.type)
		{
		case TokenType.Plus2: return PrefixExpression.parse(input.dropOne);
		case TokenType.Minus2: return PrefixExpression.parse(input.dropOne);
		case TokenType.Asterisk2: return PrefixExpression.parse(input.dropOne);
		case TokenType.Plus: return PrefixExpression.parse(input.dropOne);
		case TokenType.Minus: return PrefixExpression.parse(input.dropOne);
		default: return PostfixExpression.parse(input);
		}
	}
}

/// PostfixExpression = PrimaryExpression ("++" | "--" | "**" | "(" [ExpressionList] ")" | "[" Expression "]" | "." Identifier)*
public static class PostfixExpression
{
	public static immutable canParse = &PrimaryExpression.canParse;
	public static TokenList parse(TokenList input)
	{
		static TokenList loop(TokenList input)
		{
			switch(input.front.type)
			{
			case TokenType.Plus2: return loop(input.dropOne);
			case TokenType.Minus2: return loop(input.dropOne);
			case TokenType.Asterisk2: return loop(input.dropOne);
			case TokenType.OpenParenthese:
				if(input.dropOne.front.type == TokenType.CloseParenthese)
				{
					return loop(input.drop(2));
				}
				else
				{
					return loop(ExpressionList.parse(input.dropOne).consumeToken!(TokenType.CloseParenthese));
				}
			case TokenType.OpenBracket:
				return loop(Expression.parse(input.dropOne).consumeToken!(TokenType.CloseBracket));
			case TokenType.Period:
				return loop(input.dropOne.consumeToken!(TokenType.Identifier));
			default: return input;
			}
		}
		
		return loop(PrimaryExpression.parse(input));
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
