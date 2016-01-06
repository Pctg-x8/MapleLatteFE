module mlfe.mapleparser.lexer.token;

import mlfe.mapleparser.utils.location;
public import std.container;
import std.variant;

/// A token
final class Token
{
	private alias ValueType = Algebraic!(string, real, float, double, long, ulong);
	private Location _at;
	private TokenType _type;
	private ValueType _val;
	
	/// Construct token
	public this(Location a, TokenType t)
	{
		this._at = a;
		this._type = t;
	}
	/// Construct token with string value
	public this(Location a, TokenType t, immutable(string) v)
	{
		this._at = a;
		this._type = t;
		this._val = v.idup;
	}
	/// Construct token with real value
	public this(Location a, TokenType t, real r)
	{
		this._at = a;
		this._type = t;
		this._val = r;
	}
	/// Construct token with float value
	public this(Location a, TokenType t, float f)
	{
		this._at = a;
		this._type = t;
		this._val = f;
	}
	/// Construct token with double value
	public this(Location a, TokenType t, double d)
	{
		this._at = a;
		this._type = t;
		this._val = d;
	}
	/// Construct token with long value
	public this(Location a, TokenType t, long l)
	{
		this._at = a;
		this._type = t;
		this._val = l;
	}
	
public @property:
	/// Location of token in the source
	auto at() const { return this._at; }
	/// Type of token
	auto type() const { return this._type; }
	/// Value of token
	auto value(T)() const { return this._val.get!T; }
}

/// TokenList(alias to std.container.DList!Token)
alias TokenList = DList!Token;

/// Types of token
enum TokenType
{
	EndOfScript, StringLiteral, CharacterLiteral, NumericLiteral, FloatLiteral, DoubleLiteral, LongLiteral,
	UlongLiteral, HexadecimalLiteral,
	Identifier,
	
	LeftAngleBracket2_Equal, RightAngleBracket2_Equal,
	
	Plus_Equal, Minus_Equal, Asterisk_Equal, Slash_Equal, Percent_Equal, Ampasand_Equal, VerticalLine_Equal, Accent_Equal,
	LeftAngleBracket_Equal, RightAngleBracket_Equal, Exclamation_Equal,
	Plus2, Minus2, Asterisk2, LeftAngleBracket2, RightAngleBracket2, Equal2, Ampasand2, VerticalLine2,
	Minus_RightAngleBracket, LeftAngleBracket_Minus,
	
	Plus, Minus, Asterisk, Slash, Percent, Ampasand, VerticalLine, Accent, LeftAngleBracket, RightAngleBracket, Equal,
	Hatena, Sharp, Exclamation, Tilda,
	Comma, Colon, Semicolon, Period,
	OpenParenthese, CloseParenthese, OpenBracket, CloseBracket, OpenBrace, CloseBrace
}
