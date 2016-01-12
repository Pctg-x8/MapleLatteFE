module mlfe.mapleparser.lexer.rules;

import mlfe.mapleparser.lexer.source;
import mlfe.mapleparser.utils.location;
import mlfe.mapleparser.lexer.exception;
import mlfe.mapleparser.lexer.token;
import mlfe.mapleparser.lexer.spaces;
import std.range, std.algorithm, std.utf : toUTF8;

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
	case "0x": return parseHexadecimalLiteral(src);
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
	case '0': .. case '9': return parseNumericLiteral(src);
	case '"': return parseStringToken(src);
	case '\'': return parseCharacterToken(src);
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
	case '.': return parsePeriodOrNumericLiteral(src);
	case '(': return makeResult!(1, TokenType.OpenParenthese);
	case ')': return makeResult!(1, TokenType.CloseParenthese);
	case '{': return makeResult!(1, TokenType.OpenBrace);
	case '}': return makeResult!(1, TokenType.CloseBrace);
	case '[': return makeResult!(1, TokenType.OpenBracket);
	case ']': return makeResult!(1, TokenType.CloseBracket);
	default: break;
	}
	
	// Fallthroughed Characters: Identifier
	SourceObject src2 = src;
	string id_temp;
	while(!src2.range.empty)
	{
		if(src2.range.front.isSpaceChar) break;
		if('0' <= src2.range.front && src2.range.front <= '9') break;
		if(['"', '\'', '+', '-', '*', '/', '%', '&', '|', '^', '<', '>', '=', '!', '~', '?', '#',
		':', ';', '.', ',', '(', ')', '[', ']', '{', '}'].any!(a => a == src2.range.front)) break;
		id_temp ~= src2.range.front;
		src2 = src2.followOne;
	}
	if(!id_temp.empty) return Get_TokenResult(new Token(src2.current, TokenType.Identifier, id_temp), src2);
	
	throw new LexicalizeError(src.current, "No match tokens found.");
}

/// Parse characters as string literal
auto parseStringToken(immutable(SourceObject) src)
{
	auto src2 = src.forward(1);
	string temp;
	
	bool succeeded = false;
	while(!src2.range.empty)
	{
		if(src2.range.front == '"') { succeeded = true; break; }
		auto ret = src2.parseAsCharacter();
		temp ~= ret.chr;
		src2 = ret.rest;
	}
	if(!succeeded) throw new LexicalizeError(src.current, "String literal is not enclosed");
	return Get_TokenResult(new Token(src.current, TokenType.StringLiteral, temp), src2.forward(1));
}
/// Parse character literal
auto parseCharacterToken(immutable(SourceObject) src)
{
	auto src2 = src.forward(1);
	if(src2.range.front == '\'') throw new LexicalizeError(src.current, "Empty character literal is not allowed");
	auto ret = src2.parseAsCharacter();
	if(ret.rest.range.empty || ret.rest.range.front != '\'')
	{
		throw new LexicalizeError(src.current, "Character literal is not enclosed");
	}
	return Get_TokenResult(new Token(src.current, TokenType.CharacterLiteral, toUTF8([ret.chr])), ret.rest.forward(1));
}

/// Result of parsing character
struct CharParseResult
{
	/// Retrieved character
	dchar chr;
	/// Rest source
	SourceObject rest;	
}
/// Parse a characters
auto parseAsCharacter(immutable(SourceObject) src)
{
	return src.range.front != '\\' ? CharParseResult(src.range.front, src.followOne) : parseAsEscapedCharacter(src);
}
/// Parse a escaped characters
auto parseAsEscapedCharacter(immutable(SourceObject) src)
{
	auto r = src.range.dropOne, l = src.current.forward;
	switch(r.front)
	{
	case 'n': return CharParseResult('\n', SourceObject(r.dropOne, l.forward));
	case 't': return CharParseResult('\t', SourceObject(r.dropOne, l.forward));
	case 'r': return CharParseResult('\r', SourceObject(r.dropOne, l.forward));
	default: return CharParseResult(r.front, SourceObject(r.dropOne, l.forward));
	}
}

/// Parse range as single period or numeric omitted int-part.
auto parsePeriodOrNumericLiteral(immutable(SourceObject) src)
{
	auto r = src.range.dropOne, l = src.current.forward;
	
	if(r.empty || '0' > r.front || r.front > '9')
	{
		return Get_TokenResult(new Token(src.current, TokenType.Period), SourceObject(r, l));
	}
	real frac_part = 0.0, divs = 10.0;
	while(!r.empty && ('0' <= r.front && r.front <= '9'))
	{
		frac_part += (r.front - '0') / divs;
		divs *= 10.0;
		r = r.dropOne;
		l = l.forward;
	}
	if(!r.empty)
	{
		switch(r.front)
		{
		case 'f': case 'F':
			return Get_TokenResult(new Token(src.current, TokenType.FloatLiteral,
				cast(float)frac_part), SourceObject(r.dropOne, l.forward));
		case 'd': case 'D':
			return Get_TokenResult(new Token(src.current, TokenType.DoubleLiteral,
				cast(double)frac_part), SourceObject(r.dropOne, l.forward));
		default: break;
		}
	}
	return Get_TokenResult(new Token(src.current, TokenType.NumericLiteral, frac_part), SourceObject(r, l));
}
/// Parse range as some numeric literal
auto parseNumericLiteral(SourceObject src)
{
	auto r = src.range, l = src.current;
	ulong int_part = 0;
	while(!r.empty && ('0' <= r.front && r.front <= '9'))
	{
		int_part = int_part * 10 + (r.front - '0');
		r = r.dropOne; l = l.forward;
	}
	if(!r.empty)
	{
		switch(r.front)
		{
		case 'f': case 'F':
			return Get_TokenResult(new Token(src.current, TokenType.FloatLiteral, cast(float)int_part),
				SourceObject(r.dropOne, l.forward));
		case 'd': case 'D':
			return Get_TokenResult(new Token(src.current, TokenType.DoubleLiteral, cast(double)int_part),
				SourceObject(r.dropOne, l.forward));
		case 'u': case 'U':
			return Get_TokenResult(new Token(src.current, TokenType.UlongLiteral, int_part),
				SourceObject(r.dropOne, l.forward));
		default: break;
		}
	}
	if(r.empty || r.front != '.')
	{
		return Get_TokenResult(new Token(src.current, TokenType.LongLiteral, cast(long)int_part), SourceObject(r, l));
	}
	r = r.dropOne; l = l.forward;
	real frac_part = 0.0, divs = 10.0;
	while(!r.empty && ('0' <= r.front && r.front <= '9'))
	{
		frac_part += (r.front - '0') / divs;
		divs *= 10.0;
		r = r.dropOne;
		l = l.forward;
	}
	if(!r.empty)
	{
		switch(r.front)
		{
		case 'f': case 'F':
			return Get_TokenResult(new Token(src.current, TokenType.FloatLiteral,
				cast(float)int_part + cast(float)frac_part), SourceObject(r.dropOne, l.forward));
		case 'd': case 'D':
			return Get_TokenResult(new Token(src.current, TokenType.DoubleLiteral,
				cast(double)int_part + cast(float)frac_part), SourceObject(r.dropOne, l.forward));
		default: break;
		}
	}
	return Get_TokenResult(new Token(src.current, TokenType.NumericLiteral, cast(real)int_part + frac_part),
		SourceObject(r, l));
}
/// Parse range as hexadecimal literal
auto parseHexadecimalLiteral(immutable(SourceObject) src)
{
	pure static auto isHexdCharacter(dchar c)
	{
		return ('0' <= c && c < '9') || ('a' <= c && c <= 'f') || ('A' <= c && c <= 'F');
	}
	
	auto r = src.range.drop(2), l = src.current.forward(2);
	ulong int_part = 0;
	while(!r.empty && isHexdCharacter(r.front))
	{
		int_part <<= 4;
		if('0' <= r.front && r.front <= '9') int_part |= (r.front - '0') & 0x0f;
		else if('a' <= r.front && r.front <= 'f') int_part |= (r.front - 'a') & 0x0f + 0x0a;
		else int_part |= (r.front - 'A') & 0x0f + 0x0a;
		r = r.dropOne; l = l.forward;
	}
	if(!r.empty)
	{
		switch(r.front)
		{
		case 'u': case 'U':
			return Get_TokenResult(new Token(src.current, TokenType.UlongLiteral, int_part),
				SourceObject(r.dropOne, l.forward));
		default: break;
		}
	}
	return Get_TokenResult(new Token(src.current, TokenType.LongLiteral, cast(long)int_part), SourceObject(r, l));
}
