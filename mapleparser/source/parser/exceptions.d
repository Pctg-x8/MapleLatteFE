module mlfe.mapleparser.parser.exceptions;

import std.exception;
import mlfe.mapleparser.utils.location;

/// Raised in rule
public class ParseException : Exception
{
	public this(string msg, Location at) { super(msg ~ " at " ~ at.toString()); }
}
