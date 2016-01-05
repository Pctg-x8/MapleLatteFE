module mlfe.mapleparser.lexer.source;

import mlfe.mapleparser.utils.location;

/// Pair of Range and Location
struct SourceObject
{
	/// Range of source text
	string range;
	/// Location pointed in source
	Location current;
}
