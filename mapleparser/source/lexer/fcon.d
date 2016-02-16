module mlfe.mapleparser.lexer.fcon;

import mlfe.mapleparser.lexer.source;

// Function Concatenate Utils //
/// Concatenate function
pure SourceObject then(alias Func)(immutable SourceObject src)
{
	return Func(src);
}
/// Concatenate function applied if Pred(x) returns true
pure SourceObject thenIf(alias Pred, alias Func)(immutable SourceObject src)
{
	return Pred(src) ? Func(src) : src;
}
/// Concatenate function applied recursively
pure SourceObject thenLoop(alias Pred, alias Func)(immutable SourceObject src)
{
	return Pred(src) ? Func(src).thenLoop!(Pred, Func) : src;
}