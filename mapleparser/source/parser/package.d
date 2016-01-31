module mlfe.mapleparser.parser;

// Parser //
public import mlfe.mapleparser.parser.expression;
import mlfe.mapleparser.lexer;
import std.container, std.range;

/// Generates Abstract Syntax Tree from TokenList
void asSyntaxTree(TokenList input)
{
	scope auto rest = PrimaryExpression.parse(input);
	if(rest.front.type != TokenType.EndOfScript) assert(false);
}

unittest
{
	"123456".asTokenList.asSyntaxTree;
	"\"test\"".asTokenList.asSyntaxTree;
	"this".asTokenList.asSyntaxTree;
}
