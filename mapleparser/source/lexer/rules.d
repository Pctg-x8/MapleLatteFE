module mlfe.mapleparser.lexer.rules;

import mlfe.mapleparser.lexer.source;
import mlfe.mapleparser.utils.location;
import mlfe.mapleparser.lexer.exception;
import mlfe.mapleparser.lexer.token;
import std.range, std.algorithm;

/// Result of getToken
struct Get_TokenResult
{
	/// Retrieved token
	Token token;
	/// Rest sources
	SourceObject rest;
}
/// Data constructor
/// Token rules
auto getToken(immutable(SourceObject) src)
{
	auto makeResult(size_t fwd, TokenType tp)()
	{
		return Get_TokenResult(new Token(src.current, tp), src.forward(fwd));
	}
	
	if(src.range.count >= 3) switch(src.range[0 .. 3])
	{
	case "<<=": return makeResult!(3, TokenType.LeftAngleBracket2_Equal);
	case ">>=": return makeResult!(3, TokenType.RightAngleBracket2_Equal);
	default: break;
	}
	if(src.range.count >= 2) switch(src.range[0 .. 2])
	{
	case "++": return makeResult!(2, TokenType.Plus2);
	case "--": return makeResult!(2, TokenType.Minus2);
	case "**": return makeResult!(2, TokenType.Asterisk2);
	case "<<": return makeResult!(2, TokenType.LeftAngleBracket2);
	case ">>": return makeResult!(2, TokenType.RightAngleBracket2);
	case "&&": return makeResult!(2, TokenType.Ampasand2);
	case "||": return makeResult!(2, TokenType.VerticalLine2);
	case "==": return makeResult!(2, TokenType.Equal2);
	case "+=": return makeResult!(2, TokenType.Plus_Equal);
	case "-=": return makeResult!(2, TokenType.Minus_Equal);
	case "*=": return makeResult!(2, TokenType.Asterisk_Equal);
	case "/=": return makeResult!(2, TokenType.Slash_Equal);
	case "%=": return makeResult!(2, TokenType.Percent_Equal);
	case "&=": return makeResult!(2, TokenType.Ampasand_Equal);
	case "|=": return makeResult!(2, TokenType.VerticalLine_Equal);
	case "^=": return makeResult!(2, TokenType.Accent_Equal);
	case "<=": return makeResult!(2, TokenType.LeftAngleBracket_Equal);
	case ">=": return makeResult!(2, TokenType.RightAngleBracket_Equal);
	case "!=": return makeResult!(2, TokenType.Exclamation_Equal);
	case "<>": return makeResult!(2, TokenType.Exclamation_Equal);
	case "->": return makeResult!(2, TokenType.Minus_RightAngleBracket);
	case "<-": return makeResult!(2, TokenType.LeftAngleBracket_Minus);
	default: break;
	}
	switch(src.range.front)
	{
	case '+': return makeResult!(1, TokenType.Plus);
	case '-': return makeResult!(1, TokenType.Minus);
	case '*': return makeResult!(1, TokenType.Asterisk);
	case '/': return makeResult!(1, TokenType.Slash);
	case '%': return makeResult!(1, TokenType.Percent);
	case '&': return makeResult!(1, TokenType.Ampasand);
	case '|': return makeResult!(1, TokenType.VerticalLine);
	case '^': return makeResult!(1, TokenType.Accent);
	case '<': return makeResult!(1, TokenType.LeftAngleBracket);
	case '>': return makeResult!(1, TokenType.RightAngleBracket);
	case '=': return makeResult!(1, TokenType.Equal);
	case '!': return makeResult!(1, TokenType.Exclamation);
	case '~': return makeResult!(1, TokenType.Tilda);
	case '?': return makeResult!(1, TokenType.Hatena);
	case '#': return makeResult!(1, TokenType.Sharp);
	case ':': return makeResult!(1, TokenType.Colon);
	case ';': return makeResult!(1, TokenType.Semicolon);
	case ',': return makeResult!(1, TokenType.Comma);
	case '.': return makeResult!(1, TokenType.Period);
	case '(': return makeResult!(1, TokenType.OpenParenthese);
	case ')': return makeResult!(1, TokenType.CloseParenthese);
	case '{': return makeResult!(1, TokenType.OpenBrace);
	case '}': return makeResult!(1, TokenType.CloseBrace);
	case '[': return makeResult!(1, TokenType.OpenBracket);
	case ']': return makeResult!(1, TokenType.CloseBracket);
	default: break;
	}
	
	throw new LexicalizeError(src.current, "No match tokens found.");
}
