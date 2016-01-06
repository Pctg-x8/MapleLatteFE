module mlfe.mapleparser.lexer;

import mlfe.mapleparser.lexer.source;
import mlfe.mapleparser.utils.location;
import mlfe.mapleparser.lexer.exception;
import mlfe.mapleparser.lexer.spaces;
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
	public void parse()
	{
		auto src = SourceObject(this.source[], Location.init);
		
		while(!src.range.empty)
		{
			src = src.skipSpaces.skipComments;
			if(src.range.empty) break;
			throw new LexicalizeError(src.current);
		}
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
		Func();
	}
	
	// test!("Input Sanitize Test", () => Lexer.fromString("testにゃー").parse());
	test!("SkippingElementsTest", () => Lexer.fromString("/* blocked */\n\t	 // commend\n// comment with eof").parse());
}
