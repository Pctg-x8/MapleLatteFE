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
	/// Spaces of tab
	uint tabSpace;
	
	/// Duplicate the object
	public SourceObject dup() immutable pure
	{
		return SourceObject(range.dup, current.dup, tabSpace);
	}
	
	/+ utils +/
	/// Drop one character and perform action to location by character
	auto followOne() immutable pure
	{
		return SourceObject(range.dropOne, current.follow(range.front, tabSpace), tabSpace);
	}
	/// Drop any characters and forwarding location
	auto forward(size_t count = 1) immutable pure
	{
		return immutable SourceObject(range.drop(count), current.forward(count), tabSpace);
	}
}
