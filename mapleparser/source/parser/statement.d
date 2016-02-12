module mlfe.mapleparser.parser.statement;

import mlfe.mapleparser.parser.expression;
import mlfe.mapleparser.parser.base;
import mlfe.mapleparser.parser.exceptions;
import mlfe.mapleparser.lexer.token;
import std.algorithm, std.range;

/// Statement = IfStatement | StatementBlock | Expression ";" | ";"
public static class Statement
{
	public static bool canParse(TokenList input)
	{
		return [TokenType.Semicolon, TokenType.OpenBrace, TokenType.If].any!(a => a == input.front.type)
			|| Expression.canParse(input);
	}
	public static TokenList parse(TokenList input)
	{
		switch(input.front.type)
		{
		case TokenType.If: return IfStatement.parse(input);
		case TokenType.OpenBrace: return StatementBlock.parse(input);
		case TokenType.Semicolon: return input.dropOne;
		default: return Expression.parse(input).consumeToken!(TokenType.Semicolon);
		}
	}
}

/// StatementBlock = "{" Statement* "}"
public static class StatementBlock
{
	public static bool canParse(TokenList input)
	{
		return input.front.type == TokenType.OpenBrace;
	}
	public static TokenList parse(TokenList input)
	{
		static TokenList loop(TokenList input)
		{
			return input.front.type != TokenType.CloseBrace ? loop(Statement.parse(input)) : input.dropOne;
		}
		return loop(input.consumeToken!(TokenType.OpenBrace));
	}
}

/// IfStatement = "if" "(" Expression ")" Statement ["else" Statement]
public static class IfStatement
{
	public static bool canParse(TokenList input)
	{
		return input.front.type == TokenType.If;
	}
	public static TokenList parse(TokenList input)
	{
		auto in2 = Statement.parse(Expression.parse(input.consumeToken!(TokenType.If).consumeToken!(TokenType.OpenParenthese))
			.consumeToken!(TokenType.CloseParenthese));
		if(in2.front.type == TokenType.Else)
		{
			return Statement.parse(in2.dropOne);
		}
		else return in2;
	}
}
