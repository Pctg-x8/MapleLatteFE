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
auto skipSpaces(immutable(SourceObject) src) pure
{
	static SourceObject recursive(immutable(SourceObject) src)
	{
		return src.range.empty || !src.range.front.isSpaceChar ? src : recursive(src.followOne);
	}
	return recursive(src);
}
/// Skip comments
auto skipComments(immutable(SourceObject) src) pure
{
	static SourceObject recursive(immutable(SourceObject) src)
	{
		if(src.range.count < 2) return src;
		switch(src.range[0 .. 2])
		{
		case "//": return recursive(src.skipLineComment.skipSpaces);
		case "/*": return recursive(src.skipBlockedComment.skipSpaces);
		default: return src;
		}
	}
	return recursive(src);
}
/// Skip line commments
auto skipLineComment(immutable(SourceObject) src)
{
	auto r = src.range.drop(2);
	auto l = src.current.forward(2);
	
	while(!r.empty && !r.front.isLineBreaker) { r = r.dropOne; l = l.forward; }
	return SourceObject(r, l);
}
/// Skip blocked comments
auto skipBlockedComment(immutable(SourceObject) src)
{
	auto r = src.range.drop(2);
	auto l = src.current.forward(2);
	
	bool succeeded = false;
	while(r.count >= 2)
	{
		if(r[0 .. 2] == "*/") { succeeded = true; break; }
		l = l.follow(r.front);
		r = r.drop(1);
	}
	if(!succeeded) throw new LexicalizeError(l, "Invalid end of blocked comment");
	return SourceObject(r.drop(2), l.follow(2));
}
