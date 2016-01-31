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
	
	/// Duplicate the object
	public SourceObject dup() immutable pure
	{
		return SourceObject(range.dup, current.dup);
	}
}

/+ utils +/
/// Drop one character and perform action to location by character
auto followOne(immutable SourceObject src) pure { return SourceObject(src.range.dropOne, src.current.follow(src.range.front)); }
/// Drop any characters and forwarding location
auto forward(immutable SourceObject src, size_t count) pure
{
	return SourceObject(src.range.drop(count), mlfe.mapleparser.utils.location.forward(src.current, count));
}
