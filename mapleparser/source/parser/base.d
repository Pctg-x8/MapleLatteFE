module mlfe.mapleparser.parser.base;

import mlfe.mapleparser.lexer.token;
import mlfe.mapleparser.parser.exceptions;
import std.experimental.logger;
import std.range, std.conv;

/// Consume specified token or raise exception
TokenList consumeToken(TokenType TP)(TokenList input)
{
	if(input.front.type != TP) throw new ParseException("Expected " ~ to!string(TP), input.front.at);
	return input.dropOne;
}
/// Set "then" action with condition
TokenList thenIf(alias CondF, alias ThenF)(TokenList input)
{
	return CondF(input) ? ThenF(input) : input;
}
