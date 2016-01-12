module mlfe.mapleparser.parser;

// Parser //
import mlfe.mapleparser.lexer;

/// Parser class
public final class Parser
{
	/// Input list
	private TokenList input;
	
	/// Construct with Token List
	public this(immutable(TokenList) list)
	{
		this.input = list.dup;
	}
	
	/// Run parser
	public void parse()
	{
		
	}
}

unittest
{
	immutable TokenList input_sample = 
	[
		new Token(Location.init, TokenType.Package),
		new Token(Location.init + 7, TokenType.Identifier, "maple"),
		new Token(Location.init + 7 + 6, TokenType.Period),
		new Token(Location.init + 7 + 6 + 1, TokenType.Identifier, "test"),
		new Token(Location.init + 7 + 6 + 1 + 4, TokenType.Semicolon),
		new Token(Location.init + 7 + 6 + 1 + 4 + 1, TokenType.EndOfToken)
	];
	
	scope auto parser = new Parser(input_sample);
	parser.parse();
}
