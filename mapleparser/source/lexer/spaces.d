module mlfe.mapleparser.lexer.spaces;

import mlfe.mapleparser.lexer.source;
import mlfe.mapleparser.utils.location;
import mlfe.mapleparser.lexer.exception;
import std.range, std.algorithm;

/*/// Parsing Rules ///*/

/// Returns true if character is breaker of line
pure auto isLineBreaker(dchar ch) { return ch == '\n' || ch == '\r'; }
/// Returns true if character is space or breaker of line
pure auto isSpaceChar(dchar ch) { return ch == ' ' || ch == '\t' || ch.isLineBreaker; }

/// Skip any spaces
auto skipSpaces(immutable SourceObject src)
{
	SourceObject recursive(immutable SourceObject src)
	{
		return src.range.empty || !src.range.front.isSpaceChar ? src : recursive(src.followOne);
	}
	return recursive(src);
}
/// Skip comments
auto skipComments(immutable SourceObject src)
{
	SourceObject recursive(immutable SourceObject src)
	{
		if(src.range.count < 2) return src;
		switch(src.range[0 .. 2])
		{
		case "//": return recursive(src.forward(2).skipLineComment.skipSpaces);
		case "/*": return recursive(src.forward(2).skipBlockedComment.skipSpaces);
		default: return src;
		}
	}
	return recursive(src);
}
/// Skip line commments
auto skipLineComment(immutable SourceObject src)
{
	SourceObject loop(immutable SourceObject src)
	{
		if(src.range.empty || src.range.front.isLineBreaker) return src;
		return loop(src.followOne);
	}
	return loop(src);
}
/// Skip blocked comments
auto skipBlockedComment(immutable SourceObject src)
{
	SourceObject src2 = src;
	
	bool succeeded = false;
	while(src2.range.count >= 2)
	{
		if(src2.range[0 .. 2] == "*/") { succeeded = true; break; }
		src2 = src2.followOne;
	}
	if(!succeeded) throw new LexicalizeError(src2.current, "Invalid end of blocked comment");
	return src2.forward(2);
}
