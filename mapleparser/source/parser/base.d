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
/// Set "then" action with condition and looping
TokenList thenLoop(alias Pred, alias Fun)(TokenList input)
{
	return Pred(input) ? Fun(input).thenLoop!(Pred, Fun) : input;
}
/// Set "then" action
TokenList then(alias Fun)(TokenList input)
{
	return Fun(input);
}
