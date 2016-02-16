module mlfe.mapleparser.lexer.spaces;

import mlfe.mapleparser.lexer.source;
import mlfe.mapleparser.utils.location;
import mlfe.mapleparser.lexer.exception;
import mlfe.mapleparser.lexer.fcon;
import std.range, std.algorithm;

/*/// Parsing Rules ///*/

/// Returns true if character is breaker of line
pure auto isLineBreaker(dchar ch) { return ch == '\n' || ch == '\r'; }
/// Returns true if character is space or breaker of line
pure auto isSpaceChar(dchar ch) { return ch == ' ' || ch == '\t' || ch.isLineBreaker; }

/// Skip any spaces
auto skipSpaces(immutable SourceObject src)
{
	return src.thenLoop!(x => !x.range.empty && x.range.front.isSpaceChar, x => x.followOne);
}
/// Skip comments
auto skipComments(immutable SourceObject src)
{
	return src.thenLoop!(x => x.range.count >= 2 && (x.range[0 .. 2] == "//" || x.range[0 .. 2] == "/*"), (x)
	{
		switch(x.range[0 .. 2])
		{
		case "//": return x.skipLineComment.skipSpaces;
		case "/*": return x.skipBlockedComment.skipSpaces;
		default: assert(false);
		}
	});
}
/// Skip line commments
auto skipLineComment(immutable SourceObject src)
{
	return src.forward(2).thenLoop!(x => !x.range.empty && !x.range.front.isLineBreaker, x => x.followOne);
}
/// Skip blocked comments
auto skipBlockedComment(immutable SourceObject src)
{
	return src.forward(2).thenLoop!(x => x.range.count >= 2 && x.range[0 .. 2] != "*/", x => x.followOne)
		.then!((x)
		{
			if(x.range.count < 2 || x.range[0 .. 2] == "*/") return x.forward(2);
			else throw new LexicalizeError(x.current, "Invalid end of blocked comment");
		});
}
