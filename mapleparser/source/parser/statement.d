module mlfe.mapleparser.parser.statement;

import mlfe.mapleparser.parser.expression;
import mlfe.mapleparser.parser.base;
import mlfe.mapleparser.parser.exceptions;
import mlfe.mapleparser.lexer.token;
import std.algorithm, std.range;

/// Statement = Expression ";" | ";"
public static class Statement
{
	public static bool canParse(TokenList input)
	{
		return input.front.type == TokenType.Semicolon
			|| Expression.canParse(input);
	}
	public static TokenList parse(TokenList input)
	{
		switch(input.front.type)
		{
		case TokenType.Semicolon: return input.dropOne;
		default: return Expression.parse(input).consumeToken!(TokenType.Semicolon);
		}
	}
}
