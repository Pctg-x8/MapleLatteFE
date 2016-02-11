module mlfe.mapleparser.parser.expression;

import mlfe.mapleparser.parser.base;
import mlfe.mapleparser.parser.symbol;
import mlfe.mapleparser.lexer.token;
import mlfe.mapleparser.parser.exceptions;
import std.algorithm, std.range;

/// Expression = AddExpression
public static class Expression
{
	public static immutable canParse = AddExpression.canParse;
	public static TokenList parse(TokenList input)
	{
		return AddExpression.parse(input);
	}
}
/// ExpressionList = Expression ("," Expression)*
public static class ExpressionList
{
	public static immutable canParse = Expression.canParse;
	public static TokenList parse(TokenList input)
	{
		static TokenList loop(TokenList input)
		{
			return input.front.type == TokenType.Comma ? loop(Expression.parse(input.dropOne)) : input;
		}
		
		return loop(Expression.parse(input));
	}
}

/// AddExpression = MultiExpression ("+" MultiExpression | "-" MultiExpression)*
public static class AddExpression
{
	public static immutable canParse = MultiExpression.canParse;
	public static TokenList parse(TokenList input)
	{
		static TokenList loop(TokenList input)
		{
			switch(input.front.type)
			{
			case TokenType.Plus: return loop(MultiExpression.parse(input.dropOne));
			case TokenType.Minus: return loop(MultiExpression.parse(input.dropOne));
			default: return input;
			}
		}
		
		return loop(MultiExpression.parse(input));
	}
}

/// MultiExpression = PrefixExpression ("*" PrefixExpression | "/" PrefixExpression | "%" PrefixExpression)*
public static class MultiExpression
{
	public static immutable canParse = &PrefixExpression.canParse;
	public static TokenList parse(TokenList input)
	{
		static TokenList loop(TokenList input)
		{
			switch(input.front.type)
			{
			case TokenType.Asterisk: return loop(PrefixExpression.parse(input.dropOne));
			case TokenType.Slash: return loop(PrefixExpression.parse(input.dropOne));
			case TokenType.Percent: return loop(PrefixExpression.parse(input.dropOne));
			default: return input;
			}
		}
		
		return loop(PrefixExpression.parse(input));
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

/// PostfixExpression = PrimaryExpression ("++" | "--" | "**" | "(" [ExpressionList] ")" | "[" Expression "]" | "." TemplateInstance)*
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
				return loop(TemplateInstance.parse(input.dropOne));
			default: return input;
			}
		}
		
		return loop(PrimaryExpression.parse(input));
	}
}

/// PrimaryExpression = Literal | SpecialLiteral | ComplexLiteral
///		| TemplateInstance | "." TemplateInstance | "global" "." TemplateInstance" | "(" Expression ")"
public static class PrimaryExpression
{
	public static bool canParse(TokenList input)
	{
		return input.front.type == TokenType.OpenParenthese || input.front.type == TokenType.Period
			|| input.front.type == TokenType.Global
			|| Literal.canParse(input) || SpecialLiteral.canParse(input) || TemplateInstance.canParse(input)
			|| ComplexLiteral.canParse(input);
	}
	public static TokenList parse(TokenList input)
	{
		switch(input.front.type)
		{
		case TokenType.OpenParenthese: return Expression.parse(input.dropOne).consumeToken!(TokenType.CloseParenthese);
		case TokenType.Period: return TemplateInstance.parse(input.dropOne);
		case TokenType.Global: return TemplateInstance.parse(input.dropOne.consumeToken!(TokenType.Period));
		default: break;
		}
		if(TemplateInstance.canParse(input)) return TemplateInstance.parse(input);
		if(Literal.canParse(input)) return Literal.parse(input);
		if(SpecialLiteral.canParse(input)) return SpecialLiteral.parse(input);
		if(ComplexLiteral.canParse(input)) return ComplexLiteral.parse(input);
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

/// ComplexLiteral = "[" [ExpressionList] "]"
public static class ComplexLiteral
{
	public static bool canParse(TokenList input)
	{
		return input.front.type == TokenType.OpenBracket;
	}
	public static TokenList parse(TokenList input)
	{
		auto in2 = input.consumeToken!(TokenType.OpenBracket);
		if(in2.front.type == TokenType.CloseBracket) return in2.dropOne;
		else return ExpressionList.parse(in2).consumeToken!(TokenType.CloseBracket);
	}
}
