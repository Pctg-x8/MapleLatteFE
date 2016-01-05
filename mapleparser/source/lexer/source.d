module mlfe.mapleparser.lexer.source;

import mlfe.mapleparser.utils.location;
import std.range;

/// Pair of Range and Location
struct SourceObject
{
	/// Range of source text
	string range;
	/// Location pointed in source
	Location current;
}

/+ utils +/
/// Drop one character and perform action to location by character
auto followOne(immutable(SourceObject) src) { return SourceObject(src.range.dropOne, src.current.follow(src.range.front)); }
