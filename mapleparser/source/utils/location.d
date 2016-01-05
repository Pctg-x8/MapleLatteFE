module mlfe.mapleparser.utils.location;

/// Location object
struct Location
{
	/// Line number in source
	size_t line = 1;
	/// Character count in source
	size_t column = 1;
}

/++ utility functions +/
/// Forward column(s)
auto forward(immutable(Location) loc, size_t count = 1) { return Location(loc.line, loc.column + count); }
/// Break a line
auto breakLine(immutable(Location) loc) { return Location(loc.line + 1, 1); }
/// Follow action by character
auto follow(immutable(Location) loc, dchar chr) { return chr == '\n' ? loc.breakLine : loc.forward; }
