module mlfe.mapleparser.lexer;

public import mlfe.mapleparser.lexer.source;
public import mlfe.mapleparser.utils.location;
public import mlfe.mapleparser.lexer.exception;
public import mlfe.mapleparser.lexer.spaces;
public import mlfe.mapleparser.lexer.rules;
public import mlfe.mapleparser.lexer.token;
import std.file, std.range, std.typecons;

/// Parse a token
auto parseToken1(immutable SourceObject input)
{
	alias ReturnValue = Tuple!(SourceObject, Token);
	
	auto src2 = input.skipSpaces.skipComments;
	if(src2.range.empty) return ReturnValue(src2, Token(src2.current, TokenType.EndOfScript));
	auto ret = src2.getToken;
	return ReturnValue(ret.rest, ret.token);
}

/// Data constructor for single string parsing
TokenList asTokenList(string input) { return TokenList(SourceObject(input, Location.init)); }

unittest
{
	import std.range : isInputRange, take;
	import std.algorithm : equal, map;
	
	assert(isInputRange!TokenList);
	assert(TokenList(SourceObject("testにゃー", Location.init)).take(2).map!(a => a.type)
		.equal([TokenType.Identifier, TokenType.EndOfScript]));
	assert("/* blocked */\n\t	 // commend\n// comment with eof".asTokenList.front.type == TokenType.EndOfScript);
	assert("/* blocked */++->**/**/%=% =#".asTokenList.take(8).map!(a => a.type).equal([TokenType.Plus2, 
		TokenType.Minus_RightAngleBracket, TokenType.Asterisk2, TokenType.Percent_Equal, TokenType.Percent,
		TokenType.Equal, TokenType.Sharp, TokenType.EndOfScript]));
	assert("\"string literal\"/* aa */'a' 'b' '\\\"'".asTokenList.take(4).map!(a => tuple(a.type, a.value!string))
		.equal([
			tuple(TokenType.StringLiteral, "string literal"),
			tuple(TokenType.CharacterLiteral, "a"),
			tuple(TokenType.CharacterLiteral, "b"),
			tuple(TokenType.CharacterLiteral, "\"")
		]));
	assert("00123 34.567f 68.3d .4f 3.0 63D 0x13 0x244u".asTokenList.take(8).map!(a => a.type)
		.equal([TokenType.LongLiteral, TokenType.FloatLiteral, TokenType.DoubleLiteral, TokenType.FloatLiteral,
		TokenType.NumericLiteral, TokenType.DoubleLiteral, TokenType.LongLiteral, TokenType.UlongLiteral]));
	assert("var a = 0, b = 2.45f, c = \"Test Literal\";".asTokenList.take(14).map!(a => a.type)
		.equal([TokenType.Identifier, TokenType.Identifier, TokenType.Equal, TokenType.LongLiteral,
		TokenType.Comma, TokenType.Identifier, TokenType.Equal, TokenType.FloatLiteral, TokenType.Comma,
		TokenType.Identifier, TokenType.Equal, TokenType.StringLiteral, TokenType.Semicolon, TokenType.EndOfScript]));
}
