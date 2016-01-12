module mlfe.mapleparser.lexer;

public import mlfe.mapleparser.lexer.source;
public import mlfe.mapleparser.utils.location;
public import mlfe.mapleparser.lexer.exception;
public import mlfe.mapleparser.lexer.spaces;
public import mlfe.mapleparser.lexer.rules;
public import mlfe.mapleparser.lexer.token;
import std.file, std.range;

/// Thread-safe Lexicalizer(Scanner + Tokenizer)
public final class Lexer
{
	/// Input source
	private immutable(string) source;
	/// Private ctor
	private this(string t) { this.source = t.idup; }
	
	/// Create lexer from string
	public static auto fromString(string src) { return new Lexer(src); }
	/// Create lexer from file
	public static auto fromFile(string path) { return new Lexer(readText(path)); }
	
	/// Run parsing
	public auto parse()
	{
		auto src = SourceObject(this.source[], Location.init);
		auto tlist = TokenList();
		
		while(!src.range.empty)
		{
			src = src.skipSpaces.skipComments;
			if(src.range.empty) break;
			auto ret = src.getToken;
			tlist ~= ret.token;
			src = ret.rest;
		}
		return tlist ~ new Token(src.current, TokenType.EndOfScript);
	}
}

/// Dump all tokens in list
void dumpList(TokenList input)
{
	import std.stdio : writeln;
	foreach(t; input)
	{
		if(t.hasValue) writeln("-- ", t.type, "(", t.valueStr, ") found at ", t.at);
		else writeln("-- ", t.type, " found at ", t.at);
	}
}

unittest
{
	void test(string Name, alias Func)()
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
	}
	
	// test!("Input Sanitize Test", () => Lexer.fromString("testにゃー").parse());
	test!("SkippingElementsTest", () => Lexer.fromString("/* blocked */\n\t	 // commend\n// comment with eof").parse());
	test!("OperatorTokenScanningTest", () => Lexer.fromString("/* blocked */++->**/**/%=% =#").parse());
	test!("LiteralScanningTest1", () => Lexer.fromString("\"string literal\"/* aa */'a' 'b' '\\\"'").parse());
	test!("NumericLiteralScanningTest", () => Lexer.fromString("00123 34.567f 68.3d .4f 3.f 63D 0x13 0x244u").parse());
	test!("IdentifierScanningTest", () => Lexer.fromString("var a = 0, b = 2.45f, c = \"Test Literal\";").parse());
}
