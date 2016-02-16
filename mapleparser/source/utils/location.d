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
	
	/+ utils +/
	/// Forward column(s)
	auto forward(size_t count = 1) immutable pure
	{
		return Location(line, column + count);
	}
	/// Break a line
	auto breakLine() immutable pure
	{
		return Location(line + 1, 1);
	}
	/// Process a tab
	auto forwardTab(uint tabSpace) immutable pure
	{
		return Location(line, (((column - 1) / tabSpace) + 1) * tabSpace + 1);
	}
	/// Follow by character
	auto follow(dchar chr, uint tabSpace) immutable pure
	{
		switch(chr)
		{
		case '\n': return this.breakLine;
		case '\t': return this.forwardTab(tabSpace);
		default: return this.forward;
		}
	}
}

unittest
{
	assert(Location(3, 3).dup == Location(3, 3));
	assert(Location(3, 3).toString == "3:3");
	assert((immutable Location(3, 1)).follow('\t', 4) == Location(3, 5));
	assert((immutable Location(3, 2)).follow('\t', 4) == Location(3, 5));
}
