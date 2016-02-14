module mlfe.mapleparser.utils.location;

import std.conv;

/// Location object
struct Location
{
	/// Line number in source
	size_t line = 1;
	/// Character count in source
	size_t column = 1;
	
	/// Convert structure data to string
	public auto toString() const nothrow { return to!string(this.line) ~ ":" ~ to!string(this.column); }
	/// Duplicate object
	public auto dup() pure { return Location(this.line, this.column); }
	/// Duplicate object
	public auto dup() immutable pure { return Location(this.line, this.column); }
}
unittest
{
	assert(Location(3, 3).dup == Location(3, 3));
	assert(Location(3, 3).toString == "3:3");
	assert(Location(3, 1).follow('\t', 4) == Location(3, 5));
	assert(Location(3, 2).follow('\t', 4) == Location(3, 5));
}

/+ utility functions +/
/// Forward column(s)
auto forward(immutable Location loc, size_t count = 1) pure { return Location(loc.line, loc.column + count); }
/// Break a line
auto breakLine(immutable Location loc) pure { return Location(loc.line + 1, 1); }
/// Follow action by character
auto follow(immutable Location loc, dchar chr, uint tabSpace) pure
{
	switch(chr)
	{
	case '\n': return loc.breakLine;
	case '\t': return Location(loc.line, (((loc.column - 1) / tabSpace) + 1) * tabSpace + 1);
	default: return loc.forward;
	}
}
