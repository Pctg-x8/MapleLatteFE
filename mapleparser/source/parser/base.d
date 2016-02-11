module mlfe.mapleparser.parser.base;

import mlfe.mapleparser.lexer.token;
import mlfe.mapleparser.parser.exceptions;
import std.experimental.logger;
import std.range;

/// Consume specified token or raise exception
TokenList consumeToken(TokenType TP)(TokenList input)
{
	if(input.front.type != TP) throw new ParseException("Expected " ~ TP, input.front.at);
	return input.dropOne;
}
