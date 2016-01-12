module mlfe.mapleparser.parser;

// Parser //
import mlfe.mapleparser.lexer;
import std.container;

/// Parser class
public final class Parser
{
	/// Input list
	private TokenList input;
	
	/// Construct with Token List
	public this(TokenList list)
	{
		foreach(d; list) this.input ~= d.idup;
	}
	
	/// Run parser
	public void parse()
	{
		
	}
}

unittest
{
	TokenList input_sample;
	input_sample ~= new Token(Location.init, TokenType.Package);
	input_sample ~= new Token(Location(1, 8), TokenType.Identifier, "maple");
	input_sample ~= new Token(Location(1, 14), TokenType.Period);
	input_sample ~= new Token(Location(1, 15), TokenType.Identifier, "test");
	input_sample ~= new Token(Location(1, 19), TokenType.Semicolon);
	input_sample ~= new Token(Location(1, 20), TokenType.EndOfScript);
	
	scope auto parser = new Parser(input_sample);
	parser.parse();
}
