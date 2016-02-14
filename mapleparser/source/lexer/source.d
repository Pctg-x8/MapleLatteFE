module mlfe.mapleparser.lexer.source;

import mlfe.mapleparser.utils.location;
import std.range;

/// Count of spaces of tab character(Default is 4)
__gshared uint tabSpace = 4;
/// Overrides global configures(Configuration is shared by threads.)
public void overrideGlobalConfigure(uint tabSpace = 4)
{
	.tabSpace = tabSpace;
}

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
auto followOne(immutable SourceObject src)
{
	return SourceObject(src.range.dropOne, src.current.follow(src.range.front, tabSpace));
}
/// Drop any characters and forwarding location
auto forward(immutable SourceObject src, size_t count) pure
{
	return SourceObject(src.range.drop(count), mlfe.mapleparser.utils.location.forward(src.current, count));
}
