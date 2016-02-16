module mlfe.mapleparser.parser.base;

import mlfe.mapleparser.lexer.token;
import mlfe.mapleparser.parser.exceptions;
import std.experimental.logger;
import std.range, std.conv;

/// Maybe monad
struct ParseResult
{
	/// Succeeded previous parsing
	bool succeeded;
	/// Tail of tokens
	TokenList tail;
	
	/+ Range Primitives Forwarding +/
	/// Returns if empty the range
	public @property empty() { return this.tail.empty; }
	/// Current pointing token
	public @property front() { return this.tail.front; }
	/// Pop front element
	public void popFront() { this.tail.popFront(); }
}
/// DataConstructor for ParseResult with succeeded
ParseResult Cont(TokenList list) pure { return ParseResult(true, list); }
/// DataConstructor for ParseResult with failed
ParseResult Fail(TokenList list) pure { return ParseResult(false, list); }
/// DataConstructor for ParseResult with succeeded
ParseResult Cont(ParseResult list) pure { return ParseResult(true, list.tail); }
/// DataConstructor for ParseResult with failed
ParseResult Fail(ParseResult list) pure { return ParseResult(false, list.tail); }

/// Consume specified token or raise exception
ParseResult consumeToken(TokenType TP)(ParseResult input)
{
	if(!input.succeeded) return input;
	return input.front.type == TP ? Cont(input.dropOne) : Fail(input);
}
/// Set "then" action with condition
ParseResult thenIf(alias CondF, alias ThenF)(ParseResult input)
{
	if(!input.succeeded) return input;
	return CondF(input) ? ThenF(input) : input;
}
/// Set "then" action with condition and looping
ParseResult thenLoop(alias Pred, alias Fun)(ParseResult input)
{
	if(!input.succeeded) return input;
	return Pred(input) ? Fun(input).thenLoop!(Pred, Fun) : input;
}
/// Set "then" action
ParseResult then(alias Fun)(ParseResult input)
{
	if(!input.succeeded) return input;
	return Fun(input);
}

/// Try matching any of types
ParseResult selectByType(Expressions...)(ParseResult input)
{
	if(!input.succeeded) return input;
	
	foreach(i, E; Expressions)
	{
		static if(i % 2 == 1)
		{
			if(input.front.type == Expressions[i - 1]) return Cont(E(input));
		}
	}
	return Fail(input);
}
/// Select matching from any of expressions
ParseResult select(Expressions...)(ParseResult input)
{
	if(!input.succeeded) return input;
	
	foreach(E; Expressions)
	{
		auto pr = E(input);
		if(pr.succeeded) return pr;
	}
	return Fail(input);
}
/// Try matching continuous until fail
ParseResult matchUntilFail(alias Expression)(ParseResult input)
{
	if(!input.succeeded) return input;
	
	auto pr = Expression(input);
	return pr.succeeded ? pr.matchUntilFail!Expression : input;
}
/// Try matching and return succeeded if fail
ParseResult ignorable(alias Expression)(ParseResult input)
{
	if(!input.succeeded) return input;
	
	auto pr = Expression(input);
	return pr.succeeded ? pr : input;
}
/// Try matching a token
ParseResult matchToken(TokenType TP)(ParseResult input)
{
	if(!input.succeeded) return input;
	return input.front.type == TP ? Cont(input.dropOne) : Fail(input);
}

/// Debug the next token
TokenList dbg(TokenList input)
{
	import std.stdio : writeln;
	input.front.type.writeln("  **DEBUGGED**");
	return input;
}
/// Debug the next token with name
TokenList dbg(TokenList input, string name)
{
	import std.stdio : writeln;
	input.front.type.writeln("  **DEBUGGED FROM ", name, "**");
	return input;
}
