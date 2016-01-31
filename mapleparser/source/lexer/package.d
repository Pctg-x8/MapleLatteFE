module mlfe.mapleparser.lexer;

public import mlfe.mapleparser.lexer.source;
public import mlfe.mapleparser.utils.location;
public import mlfe.mapleparser.lexer.exception;
public import mlfe.mapleparser.lexer.spaces;
public import mlfe.mapleparser.lexer.rules;
public import mlfe.mapleparser.lexer.token;
import std.file, std.range, std.typecons;

/// Parse a token
auto parseToken1(immutable SourceObject input)
{
	alias ReturnValue = Tuple!(SourceObject, Token);
	
	auto src2 = input.skipSpaces.skipComments;
	if(src2.range.empty) return ReturnValue(src2, Token(src2.current, TokenType.EndOfScript));
	auto ret = src2.getToken;
	return ReturnValue(ret.rest, ret.token);
}

unittest
{
	/*void test(string Name, alias Func)()
	{
		import std.datetime : StopWatch;
		import std.stdio : writeln;
		
		StopWatch sw;
		sw.start();
		scope(exit)
		{
			sw.stop();
			writeln("Test \"", Name, "\" finished. time = ", sw.peek.usecs, " us");
		}
		static if(is(typeof(Func()) == TokenList))
		{
			Func().dumpList();
		}
		else
		{
			Func();
		}
	}*/
	
	import std.range : isInputRange, take;
	import std.algorithm : equal, map;
	assert(isInputRange!TokenList);
	assert(TokenList(SourceObject("testにゃー", Location.init)).take(2).map!(a => a.type)
		.equal([TokenType.Identifier, TokenType.EndOfScript]));
	
	// test!("Input Sanitize Test", () => Lexer.fromString("testにゃー").parse());
	// test!("SkippingElementsTest", () => Lexer.fromString("/* blocked */\n\t	 // commend\n// comment with eof").parse());
	// test!("OperatorTokenScanningTest", () => Lexer.fromString("/* blocked */++->**/**/%=% =#").parse());
	// test!("LiteralScanningTest1", () => Lexer.fromString("\"string literal\"/* aa */'a' 'b' '\\\"'").parse());
	// test!("NumericLiteralScanningTest", () => Lexer.fromString("00123 34.567f 68.3d .4f 3.f 63D 0x13 0x244u").parse());
	// test!("IdentifierScanningTest", () => Lexer.fromString("var a = 0, b = 2.45f, c = \"Test Literal\";").parse());
}
