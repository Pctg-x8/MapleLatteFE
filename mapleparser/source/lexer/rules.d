module mlfe.mapleparser.lexer.rules;

import mlfe.mapleparser.lexer.source;
import mlfe.mapleparser.utils.location;
import mlfe.mapleparser.lexer.exception;
import mlfe.mapleparser.lexer.token;
import mlfe.mapleparser.lexer.spaces;
import std.range, std.algorithm, std.utf : toUTF8;
import std.functional, std.typecons;

/// Result of getToken
struct Get_TokenResult
{
	/// Retrieved token
	Token token;
	/// Rest sources
	SourceObject rest;
}
/// Token rules
auto getToken(immutable SourceObject src) pure
{
	auto TokenResult(size_t fwd, TokenType tp) pure
	{
		return Get_TokenResult(Token(src.current, tp), src.forward(fwd));
	}
	
	if(src.range.count >= 3)
	{
		alias Value = partial!(TokenResult, 3);
		
		switch(src.range[0 .. 3])
		{
		case "<<=": return Value(TokenType.LeftAngleBracket2_Equal);
		case ">>=": return Value(TokenType.RightAngleBracket2_Equal);
		default: break;
		}
	}
	if(src.range.count >= 2)
	{
		alias Value = partial!(TokenResult, 2);
		
		switch(src.range[0 .. 2])
		{
		case "0x": return parseHexadecimalLiteral(src);
		case "++": return Value(TokenType.Plus2);
		case "--": return Value(TokenType.Minus2);
		case "**": return Value(TokenType.Asterisk2);
		case "<<": return Value(TokenType.LeftAngleBracket2);
		case ">>": return Value(TokenType.RightAngleBracket2);
		case "&&": return Value(TokenType.Ampasand2);
		case "||": return Value(TokenType.VerticalLine2);
		case "==": return Value(TokenType.Equal2);
		case "+=": return Value(TokenType.Plus_Equal);
		case "-=": return Value(TokenType.Minus_Equal);
		case "*=": return Value(TokenType.Asterisk_Equal);
		case "/=": return Value(TokenType.Slash_Equal);
		case "%=": return Value(TokenType.Percent_Equal);
		case "&=": return Value(TokenType.Ampasand_Equal);
		case "|=": return Value(TokenType.VerticalLine_Equal);
		case "^=": return Value(TokenType.Accent_Equal);
		case "<=": return Value(TokenType.LeftAngleBracket_Equal);
		case ">=": return Value(TokenType.RightAngleBracket_Equal);
		case "!=": return Value(TokenType.Exclamation_Equal);
		case "<>": return Value(TokenType.Exclamation_Equal);
		case "->": return Value(TokenType.Minus_RightAngleBracket);
		case "<-": return Value(TokenType.LeftAngleBracket_Minus);
		default: break;
		}
	}
	
	alias Value = partial!(TokenResult, 1);
	switch(src.range.front)
	{
	case '0': .. case '9': return parseNumericLiteral(src);
	case '"': return parseStringToken(src);
	case '\'': return parseCharacterToken(src);
	case '+': return Value(TokenType.Plus);
	case '-': return Value(TokenType.Minus);
	case '*': return Value(TokenType.Asterisk);
	case '/': return Value(TokenType.Slash);
	case '%': return Value(TokenType.Percent);
	case '&': return Value(TokenType.Ampasand);
	case '|': return Value(TokenType.VerticalLine);
	case '^': return Value(TokenType.Accent);
	case '<': return Value(TokenType.LeftAngleBracket);
	case '>': return Value(TokenType.RightAngleBracket);
	case '=': return Value(TokenType.Equal);
	case '!': return Value(TokenType.Exclamation);
	case '~': return Value(TokenType.Tilda);
	case '?': return Value(TokenType.Hatena);
	case '#': return Value(TokenType.Sharp);
	case ':': return Value(TokenType.Colon);
	case ';': return Value(TokenType.Semicolon);
	case ',': return Value(TokenType.Comma);
	case '.': return parsePeriodOrNumericLiteral(src);
	case '(': return Value(TokenType.OpenParenthese);
	case ')': return Value(TokenType.CloseParenthese);
	case '{': return Value(TokenType.OpenBrace);
	case '}': return Value(TokenType.CloseBrace);
	case '[': return Value(TokenType.OpenBracket);
	case ']': return Value(TokenType.CloseBracket);
	default: break;
	}
	
	// Fallthroughed Characters: Identifier
	auto src2 = src.dup;
	string id_temp;
	while(!src2.range.empty)
	{
		if(src2.range.front.isSpaceChar) break;
		if(['"', '\'', '+', '-', '*', '/', '%', '&', '|', '^', '<', '>', '=', '!', '~', '?', '#',
		':', ';', '.', ',', '(', ')', '[', ']', '{', '}'].any!(a => a == src2.range.front)) break;
		id_temp ~= src2.range.front;
		src2 = src2.followOne;
	}
	if(!id_temp.empty)
	{
		auto makeToken(TokenType T)() { return Get_TokenResult(Token(src.current, T), src2); }
		
		switch(id_temp)
		{
		case "package": return makeToken!(TokenType.Package);
		case "this": return makeToken!(TokenType.This);
		case "super": return makeToken!(TokenType.Super);
		case "global": return makeToken!(TokenType.Global);
		case "if": return makeToken!(TokenType.If);
		case "else": return makeToken!(TokenType.Else);
		case "for": return makeToken!(TokenType.For);
		case "foreach": return makeToken!(TokenType.Foreach);
		case "while": return makeToken!(TokenType.While);
		case "do": return makeToken!(TokenType.Do);
		case "void": return makeToken!(TokenType.Void);
		case "char": return makeToken!(TokenType.Char);
		case "uchar": return makeToken!(TokenType.Uchar);
		case "byte": return makeToken!(TokenType.Byte);
		case "short": return makeToken!(TokenType.Short);
		case "ushort": return makeToken!(TokenType.Ushort);
		case "word": return makeToken!(TokenType.Word);
		case "int": return makeToken!(TokenType.Int);
		case "uint": return makeToken!(TokenType.Uint);
		case "dword": return makeToken!(TokenType.Dword);
		case "long": return makeToken!(TokenType.Long);
		case "ulong": return makeToken!(TokenType.Ulong);
		case "qword": return makeToken!(TokenType.Qword);
		case "float": return makeToken!(TokenType.Float);
		case "double": return makeToken!(TokenType.Double);
		case "auto": return makeToken!(TokenType.Auto);
		case "var": return makeToken!(TokenType.Var);
		case "val": return makeToken!(TokenType.Val);
		case "const": return makeToken!(TokenType.Const);
		default: return Get_TokenResult(Token(src.current, TokenType.Identifier, id_temp), src2);
		}
	}
	
	throw new LexicalizeError(src.current, "No match tokens found.");
}

alias CharValue = Tuple!(dchar, SourceObject);
/// Parse character in literal
auto parseAsCharacter(immutable SourceObject input) pure
{
	return input.range.front == '\\' ? input.parseAsEscapedCharacter() : CharValue(input.range.front, input.followOne);
}
/// Parse escaped character in literal
auto parseAsEscapedCharacter(immutable SourceObject input) pure
{
	if(input.range.count <= 1) throw new LexicalizeError(input.current, "Invalid escape sequence");
	switch(input.range.dropOne.front)
	{
	case 'n': return CharValue('\n', input.forward(2));
	case 't': return CharValue('\t', input.forward(2));
	case 'r': return CharValue('\r', input.forward(2));
	default: return CharValue(input.range.dropOne.front, input.forward(1).followOne);
	}
}

/// Parse characters as string literal
auto parseStringToken(immutable SourceObject input) pure
{
	auto content_range = input.forward(1);
	string temp = "";
	while(true)
	{
		if(content_range.range.empty) throw new LexicalizeError(content_range.current, "String literal is not enclosed");
		if(content_range.range.front == '"') break;
		auto ret = content_range.parseAsCharacter();
		temp ~= ret[0];
		content_range = ret[1];
	}
	return Get_TokenResult(Token(input.current, TokenType.StringLiteral, temp), content_range.forward(1));
}
/// Parse character literal
auto parseCharacterToken(immutable SourceObject input) pure
{
	auto content_range = input.forward(1);
	void exception() pure { throw new LexicalizeError(content_range.current, "Invalid character literal"); }
	
	if(content_range.range.empty) exception();
	auto chr = content_range.parseAsCharacter();
	if(chr[1].range.empty || chr[1].range.front != '\'') exception();
	return Get_TokenResult(Token(input.current, TokenType.CharacterLiteral, [chr[0]].toUTF8), chr[1].forward(1));
}

/// Character is in range(a <= v <= b)
auto isInRange(dchar v, dchar a, dchar b) pure in { assert(a < b); } body
{
	return a <= v && v <= b;
} 

/// Parse range as single period or ipart-omitted numeric literal
auto parsePeriodOrNumericLiteral(immutable SourceObject input) pure
{
	if(input.range.dropOne.empty || !input.range.dropOne.front.isInRange('0', '9'))
	{
		return Get_TokenResult(Token(input.current, TokenType.Period), input.forward(1));
	}
	else return input.parseNumericLiteral();
}
/// Parse range as some numeric literals
auto parseNumericLiteral(immutable SourceObject input) pure
{
	auto current_range = input.dup;
	ulong ipart = 0;
	while(!current_range.range.empty && current_range.range.front.isInRange('0', '9'))
	{
		ipart = ipart * 10 + (current_range.range.front - '0');
		current_range = current_range.forward(1);
	}
	
	if(!current_range.range.empty)
	{
		// Following action by post-literal
		switch(current_range.range.front)
		{
		case 'u': case 'U':
			return Get_TokenResult(Token(input.current, TokenType.UlongLiteral, ipart), current_range.forward(1));
		case 'f': case 'F':
			return Get_TokenResult(Token(input.current, TokenType.FloatLiteral, cast(float)ipart), current_range.forward(1));
		case 'd': case 'D':
			return Get_TokenResult(Token(input.current, TokenType.DoubleLiteral, cast(double)ipart), current_range.forward(1));
		default: break;
		}
	}
	if(current_range.range.empty || current_range.range.front != '.')
	{
		// as long
		return Get_TokenResult(Token(input.current, TokenType.LongLiteral, ipart), current_range);
	}
	
	// process following period
	auto period_ptr = current_range;
	current_range = current_range.forward(1);
	if(current_range.range.empty || !current_range.range.front.isInRange('0', '9'))
	{
		// unread period(passing to next)
		return Get_TokenResult(Token(input.current, TokenType.LongLiteral, ipart), period_ptr);
	}
	real fpart = 0.0, divs = 10.0;
	while(!current_range.range.empty && current_range.range.front.isInRange('0', '9'))
	{
		fpart += (current_range.range.front - '0') / divs;
		divs *= 10.0;
		current_range = current_range.forward(1);
	}
	if(!current_range.range.empty)
	{
		switch(current_range.range.front)
		{
		case 'f': case 'F':
			return Get_TokenResult(Token(input.current, TokenType.FloatLiteral, cast(float)(ipart + fpart)),
				current_range.forward(1));
		case 'd': case 'D':
			return Get_TokenResult(Token(input.current, TokenType.DoubleLiteral, cast(double)(ipart + fpart)),
				current_range.forward(1));
		default: break;
		}
	}
	return Get_TokenResult(Token(input.current, TokenType.NumericLiteral, ipart + fpart), current_range);
}
/// Parse range as hexadecimal literal
auto parseHexadecimalLiteral(immutable SourceObject input) pure
{
	import std.uni : toLower;
	
	static bool isHexCharacter(dchar c) pure
	{
		return c.isInRange('0', '9') || c.toLower.isInRange('a', 'f');
	}
	
	auto body_range = input.forward(2);
	ulong ipart = 0;
	while(!body_range.range.empty && isHexCharacter(body_range.range.front))
	{
		ipart <<= 4;
		switch(body_range.range.front.toLower)
		{
		case '0': .. case '9': ipart |= body_range.range.front - '0'; break;
		case 'a': .. case 'f': ipart |= 0x0a + (body_range.range.front - 'a'); break;
		default: assert(false);
		}
		body_range = body_range.forward(1);
	}
	if(!body_range.range.empty && body_range.range.front.toLower == 'u')
	{
		return Get_TokenResult(Token(input.current, TokenType.UlongLiteral, ipart), body_range.forward(1));
	}
	return Get_TokenResult(Token(input.current, TokenType.LongLiteral, ipart), body_range);
}
