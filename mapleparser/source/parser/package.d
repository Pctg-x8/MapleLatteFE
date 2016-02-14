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
	"{ float[] ary = [3, 4]; float[2] a2 = [4, 5]; const(float)[a] c; const(float[3]) b; }".asTestCase;
	"{ const auto[] e = [4.0, 5.0], b = [3]; }".asTestCase;
	"while(true) update();".asTestCase;
	"for(var i = 0; i < 10; i++) \"hello\".writeln;".asTestCase;
	"for(i = 0; ; i++) \"infinite!\".writeln;".asTestCase;
	"for(i = 0; ; i++;) \"infinite!\".writeln;".asTestCase!true;
	"for(i = 0; i++) \"infinite!\".writeln;".asTestCase!true;
	"do i = i + 1; while(true);".asTestCase;
	"do i = i + 1 while(true);".asTestCase!true;
	"do i = i + 1; j--; while(true);".asTestCase!true;
	"do i = j; for(var j = 0; j < 30; j++);".asTestCase!true;
	"foreach(var a in [3, 4, 5]) a.writeln;".asTestCase;
	"foreach(Tuple#(int, float) a in [4.0f, 5.0f, 6.0f].withIndex) { a.writeln; }".asTestCase;
	"loop1: while(true) for(var i = 0; i < 3; i++) if(i == 2) break loop1;".asTestCase;
	"while(true) continue;".asTestCase;
	"if(v == 3) return v + 1;".asTestCase;
	"return input.front.type == TokenType.Asterisk ? input.dropOne : input;".asTestCase;
	"try { if(a == 0) throw RuntimeError(\"assertion failure.\"); } catch(RuntimeError e) e.writeln; finally o.terminate();".asTestCase;
}
