module mlfe.mapleparser.lexer.rules;

import mlfe.mapleparser.lexer.source;
import mlfe.mapleparser.utils.location;
import mlfe.mapleparser.lexer.exception;
import mlfe.mapleparser.lexer.token;
import mlfe.mapleparser.lexer.spaces;
import mlfe.mapleparser.lexer.fcon;
import std.range, std.algorithm, std.utf : toUTF8;
import std.functional, std.typecons;
import std.uni : toLower;

/// Returns true if character is part of hexadecimal literal
bool isHexCharacter(dchar c) pure
{
	return c.isInRange('0', '9') || c.toLower.isInRange('a', 'f');
}
/// Returns true if character is part of breaker of identifier
bool isIdentifierBreaker(dchar c) pure
{
	return c.isSpaceChar
		|| ['"', '\'', '+', '-', '*', '/', '%', '&', '|',
			'^', '<', '>', '=', '!', '~', '?', '#', ':', ';', '.', ',',
			'(', ')', '[', ']', '{', '}'].any!(a => a == c);
}

/// Result of getToken
struct Get_TokenResult
{
	/// Retrieved token
	Token token;
	/// Rest sources
	SourceObject rest;
}
/// Token rules
auto getToken(immutable SourceObject src)
{
	if(src.range.count >= 3)
	{
		auto Value3(TokenType TP)() pure
		{
			return Get_TokenResult(Token(src.current, TP, src.range[0 .. 3]), src.forward(3));
		}
		
		switch(src.range[0 .. 3])
		{
		case "<<=": return Value3!(TokenType.LeftAngleBracket2_Equal);
		case ">>=": return Value3!(TokenType.RightAngleBracket2_Equal);
		default: break;
		}
	}
	if(src.range.count >= 2)
	{
		auto Value2(TokenType TP)() pure
		{
			return Get_TokenResult(Token(src.current, TP, src.range[0 .. 2]), src.forward(2));
		}
		
		switch(src.range[0 .. 2])
		{
		case "0x": return parseHexadecimalLiteral(src);
		case "++": return Value2!(TokenType.Plus2);
		case "--": return Value2!(TokenType.Minus2);
		case "**": return Value2!(TokenType.Asterisk2);
		case "<<": return Value2!(TokenType.LeftAngleBracket2);
		case ">>": return Value2!(TokenType.RightAngleBracket2);
		case "&&": return Value2!(TokenType.Ampasand2);
		case "||": return Value2!(TokenType.VerticalLine2);
		case "==": return Value2!(TokenType.Equal2);
		case "+=": return Value2!(TokenType.Plus_Equal);
		case "-=": return Value2!(TokenType.Minus_Equal);
		case "*=": return Value2!(TokenType.Asterisk_Equal);
		case "/=": return Value2!(TokenType.Slash_Equal);
		case "%=": return Value2!(TokenType.Percent_Equal);
		case "&=": return Value2!(TokenType.Ampasand_Equal);
		case "|=": return Value2!(TokenType.VerticalLine_Equal);
		case "^=": return Value2!(TokenType.Accent_Equal);
		case "<=": return Value2!(TokenType.LeftAngleBracket_Equal);
		case ">=": return Value2!(TokenType.RightAngleBracket_Equal);
		case "!=": return Value2!(TokenType.Exclamation_Equal);
		case "<>": return Value2!(TokenType.Exclamation_Equal);
		case "->": return Value2!(TokenType.Minus_RightAngleBracket);
		case "<-": return Value2!(TokenType.LeftAngleBracket_Minus);
		case "=>": return Value2!(TokenType.Equal_RightAngleBracket);
		default: break;
		}
	}
	if(!src.range.empty)
	{
		auto Value(TokenType TP)() pure
		{
			return Get_TokenResult(Token(src.current, TP, src.range[0 .. 1]), src.forward(1));
		}
	
		switch(src.range.front)
		{
		case '0': .. case '9': return parseNumericLiteral(src);
		case '"': return parseStringToken(src);
		case '\'': return parseCharacterToken(src);
		case '+': return Value!(TokenType.Plus);
		case '-': return Value!(TokenType.Minus);
		case '*': return Value!(TokenType.Asterisk);
		case '/': return Value!(TokenType.Slash);
		case '%': return Value!(TokenType.Percent);
		case '&': return Value!(TokenType.Ampasand);
		case '|': return Value!(TokenType.VerticalLine);
		case '^': return Value!(TokenType.Accent);
		case '<': return Value!(TokenType.LeftAngleBracket);
		case '>': return Value!(TokenType.RightAngleBracket);
		case '=': return Value!(TokenType.Equal);
		case '!': return Value!(TokenType.Exclamation);
		case '~': return Value!(TokenType.Tilda);
		case '?': return Value!(TokenType.Hatena);
		case '#': return Value!(TokenType.Sharp);
		case ':': return Value!(TokenType.Colon);
		case ';': return Value!(TokenType.Semicolon);
		case ',': return Value!(TokenType.Comma);
		case '.': return parsePeriodOrNumericLiteral(src);
		case '(': return Value!(TokenType.OpenParenthese);
		case ')': return Value!(TokenType.CloseParenthese);
		case '{': return Value!(TokenType.OpenBrace);
		case '}': return Value!(TokenType.CloseBrace);
		case '[': return Value!(TokenType.OpenBracket);
		case ']': return Value!(TokenType.CloseBracket);
		default: break;
		}
	}
	
	// Fallthroughed Characters: Identifier
	string id_temp;
	immutable identifier_rest = src.thenLoop!(x => !x.range.empty && !x.range.front.isIdentifierBreaker, (x)
	{
		id_temp ~= x.range.front;
		return x.forward;
	});
	if(!id_temp.empty)
	{
		auto makeToken(TokenType T)() pure { return Get_TokenResult(Token(src.current, T, id_temp), identifier_rest); }
		
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
		case "in": return makeToken!(TokenType.In);
		case "break": return makeToken!(TokenType.Break);
		case "continue": return makeToken!(TokenType.Continue);
		case "return": return makeToken!(TokenType.Return);
		case "match": return makeToken!(TokenType.Match);
		case "throw": return makeToken!(TokenType.Throw);
		case "try": return makeToken!(TokenType.Try);
		case "catch": return makeToken!(TokenType.Catch);
		case "finally": return makeToken!(TokenType.Finally);
		case "switch": return makeToken!(TokenType.Switch);
		case "case": return makeToken!(TokenType.Case);
		case "default": return makeToken!(TokenType.Default);
		case "new": return makeToken!(TokenType.New);
		case "true": return makeToken!(TokenType.True);
		case "false": return makeToken!(TokenType.False);
		default: return Get_TokenResult(Token(src.current, TokenType.Identifier, id_temp), identifier_rest);
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
	default: return CharValue(input.range.dropOne.front, input.forward.followOne);
	}
}

/// Parse characters as string literal
auto parseStringToken(immutable SourceObject input) pure
{
	string temp = "";
	immutable content_rest = input.forward.thenLoop!(x => !x.range.empty && x.range.front != '"', (x)
	{
		immutable val = x.parseAsCharacter;
		temp ~= val[0];
		return val[1];
	});
	if(content_rest.range.empty) throw new LexicalizeError(content_rest.current, "String literal is not enclosed");
	return Get_TokenResult(Token(input.current, TokenType.StringLiteral, temp), content_rest.forward);
}
/// Parse character literal
auto parseCharacterToken(immutable SourceObject input)
{
	immutable content_range = input.forward;
	void exception() pure { throw new LexicalizeError(content_range.current, "Invalid character literal"); }
	
	if(content_range.range.empty) exception();
	immutable chr = content_range.parseAsCharacter;
	if(chr[1].range.empty || chr[1].range.front != '\'') exception();
	return Get_TokenResult(Token(input.current, TokenType.CharacterLiteral, [chr[0]].toUTF8), chr[1].forward);
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
		return Get_TokenResult(Token(input.current, TokenType.Period, input.range[0 .. 1]), input.forward(1));
	}
	else return input.parseNumericLiteral();
}
/// Parse range as some numeric literals
auto parseNumericLiteral(immutable SourceObject input) pure
{
	size_t sourceCount = 0;
	ulong ipart = 0;
	immutable ipart_rest = input.thenLoop!(x => !x.range.empty && x.range.front.isInRange('0', '9'), (x)
	{
		ipart = ipart * 10 + (x.range.front - '0');
		sourceCount++;
		return x.forward;
	});
	if(!ipart_rest.range.empty && ['f', 'd', 'u'].any!(a => a == ipart_rest.range.front.toLower))
	{
		immutable sourceRange = input.range[0 .. sourceCount + 1];
		immutable restRange = ipart_rest.forward;
		immutable token = ipart_rest.range.front.toLower.predSwitch(
			'u', Token(input.current, TokenType.UlongLiteral, sourceRange, ipart),
			'f', Token(input.current, TokenType.FloatLiteral, sourceRange, cast(float)ipart),
			'd', Token(input.current, TokenType.DoubleLiteral, sourceRange, cast(double)ipart)
		);
		return Get_TokenResult(token, restRange);
	}
	immutable hasNext = ipart_rest.range.count >= 2;
	immutable isPeriodComing = hasNext && ipart_rest.range.front == '.';
	if(!isPeriodComing || !ipart_rest.range.dropOne.front.isInRange('0', '9'))
	{
		// as long
		return Get_TokenResult(Token(input.current, TokenType.LongLiteral, input.range[0 .. sourceCount], ipart),
			ipart_rest);
	}
	sourceCount++;
	real fpart = 0.0, divs = 10.0;
	immutable fpart_rest = ipart_rest.forward.thenLoop!(x => !x.range.empty && x.range.front.isInRange('0', '9'), (x)
	{
		fpart += (x.range.front - '0') / divs;
		divs *= 10.0;
		sourceCount++;
		return x.forward;
	});
	immutable value = ipart + fpart;
	immutable hasNextFpart = !fpart_rest.range.empty;
	if(hasNextFpart && ['f', 'd'].any!(a => a == fpart_rest.range.front.toLower))
	{
		immutable isDouble = fpart_rest.range.front.toLower == 'd';
		immutable sourceRange = input.range[0 .. sourceCount + 1];
		immutable token = isDouble ? Token(input.current, TokenType.DoubleLiteral, sourceRange, cast(double)value)
			: Token(input.current, TokenType.FloatLiteral, sourceRange, cast(float)value);
		
		return Get_TokenResult(token, fpart_rest.forward);
	}
	else return Get_TokenResult(Token(input.current, TokenType.NumericLiteral, input.range[0 .. sourceCount], value),
		fpart_rest);
}
/// Parse range as hexadecimal literal
auto parseHexadecimalLiteral(immutable SourceObject input) pure
{
	ulong ipart = 0;
	size_t sourceCount = 2;
	immutable rest = input.forward(2).thenLoop!(x => !x.range.empty && x.range.front.isHexCharacter, (x)
	{
		ipart <<= 4;
		switch(x.range.front.toLower)
		{
		case '0': .. case '9': ipart |= x.range.front - '0'; break;
		case 'a': .. case 'f': ipart |= 0x0a + (x.range.front - 'a'); break;
		default: assert(false);
		}
		sourceCount++;
		return x.forward;
	});
	immutable isUnsigned = !rest.range.empty && rest.range.front.toLower == 'u';
	immutable tokenType = isUnsigned ? TokenType.UlongLiteral : TokenType.LongLiteral;
	immutable sourceRange = input.range[0 .. sourceCount + isUnsigned];
	immutable restRange = isUnsigned ? rest.forward : rest;
	return Get_TokenResult(Token(input.current, tokenType, sourceRange, ipart), restRange);
}
