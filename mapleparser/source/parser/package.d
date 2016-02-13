module mlfe.mapleparser.parser;

// Parser //
public import mlfe.mapleparser.parser.exceptions;
public import mlfe.mapleparser.parser.statement;
import mlfe.mapleparser.lexer;
import std.container, std.range;

/// Generates Abstract Syntax Tree from TokenList
void asSyntaxTree(TokenList input)
{
	if(input.front.type == TokenType.EndOfScript) return; // empty input
	scope auto rest = Statement.parse(input);
	if(rest.front.type != TokenType.EndOfScript) throw new ParseException("Script not terminated.", rest.front.at);
}

private auto asTestCase(bool ThrownException = false)(string testcase)
{
	import std.exception : assertThrown, assertNotThrown;
	
	static if(ThrownException) assertThrown!ParseException(testcase.asTokenList.asSyntaxTree);
	else assertNotThrown!ParseException(testcase.asTokenList.asSyntaxTree);
}

unittest
{
	"123456;".asTestCase;
	"\"test\";".asTestCase;
	"this;".asTestCase;
	"super.this;".asTestCase!true;
	"(122 );".asTestCase;
	"++(10.asPointer);".asTestCase;
	"+++2**--;".asTestCase;
	"3.toNormalized(2, 2).length;".asTestCase;
	"[3, 2].normalized.scale(2).length;".asTestCase;
	"[3, 2].asVector#float.normalized.scale(2).length;".asTestCase;
	"[3, 2, 2].asVector#(float, 2).scale(2.1f).length;".asTestCase;
	"([3, 2] + 4).asVector#(float).scale(2.2f).length / 4.0f;".asTestCase;
	"([3, 2] + 4).asVector#float + 2.0f.scale(2.2f).length / 4.0f;".asTestCase;
	"asVector#float([3, 2] + 4) + 2.0f.scale(2.2f).length / 4.0f;".asTestCase;
	"y + 2 == 5 || x + 4 == 2 ? x > 0 ? x : -x : y;".asTestCase;
	"y + 2 == 5 || x + 4 == 2 ? x > 0 ? x : -x;".asTestCase!true;
	"x = [2, 3];".asTestCase;
	"x = [2, 3]".asTestCase!true;
	"".asTestCase;
	";".asTestCase;
	"{}".asTestCase;
	"{ var a = 3.2f; }".asTestCase;
	"{ val a = 3.2f; const float b = a + 4.5f; }".asTestCase;
	"{ a = 3.2f; b = a + 4.5f }".asTestCase!true;
	"if(a % 4 == 3) { a++; } else a--;".asTestCase;
	"if(a % 4 == 3) a++;".asTestCase;
	"if(a % 4 == 3) a ++; else".asTestCase!true;
	"if(a % 4 == 3) a++ else a--;".asTestCase!true;
}
