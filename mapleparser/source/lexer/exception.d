module mlfe.mapleparser.lexer.exception;

import mlfe.mapleparser.utils.location;

/// Raised on error in scanning/tokenizing
final class LexicalizeError : Exception
{
	/// Construct with location
	public this(Location loc) pure { super("Lexicalize Error at " ~ loc.toString); }
	/// Construct with message
	public this(Location loc, string msg) pure { super(msg ~ " at " ~ loc.toString); }
}
