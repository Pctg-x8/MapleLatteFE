module mlfe.mapleparser.parser;

// Parser //
public import mlfe.mapleparser.parser.exceptions;
public import mlfe.mapleparser.parser.expression;
import mlfe.mapleparser.lexer;
import std.container, std.range;

/// Generates Abstract Syntax Tree from TokenList
void asSyntaxTree(TokenList input)
{
	scope auto rest = Expression.parse(input);
	if(rest.front.type != TokenType.EndOfScript) throw new ParseException("Script not terminated.", rest.front.at);
}

unittest
{
	import std.exception : assertThrown, assertNotThrown;
	
	assertNotThrown!ParseException("123456".asTokenList.asSyntaxTree);
	assertNotThrown!ParseException("\"test\"".asTokenList.asSyntaxTree);
	assertNotThrown!ParseException("this".asTokenList.asSyntaxTree);
	assertThrown!ParseException("super.this".asTokenList.asSyntaxTree);
	assertNotThrown!ParseException("(122 )".asTokenList.asSyntaxTree);
	assertNotThrown!ParseException("++(10.asPointer)".asTokenList.asSyntaxTree);
	assertNotThrown!ParseException("+++2**--".asTokenList.asSyntaxTree);
	assertNotThrown!ParseException("3.toNormalized(2, 2).length".asTokenList.asSyntaxTree);
	assertNotThrown!ParseException("[3, 2].normalized.scale(2).length".asTokenList.asSyntaxTree);
}
