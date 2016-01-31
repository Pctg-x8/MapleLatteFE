module mlfe.mapleparser.parser;

// Parser //
public import mlfe.mapleparser.parser.expression;
import mlfe.mapleparser.lexer;
import std.container, std.range;

/// Parser class
public final class Parser
{
	/// Input list
	private TokenList input;
	
	/// Construct with Token List
	public this(TokenList list)
	{
		this.input = list;
	}
	
	/// Run parser
	public void parse()
	{
		scope auto rest = PrimaryExpression.parse(this.input);
		if(rest.front.type != TokenType.EndOfScript) assert(false);
	}
}

unittest
{
	/*auto tester(string str)() { new Parser(Lexer.fromString(str).parse()).parse(); }
	
	tester!"123456";
	tester!"\"test\"";
	tester!"this";*/
}
