module mlfe.mapleparser.lexer.token;

import mlfe.mapleparser.lexer : parseToken1;
import mlfe.mapleparser.utils.location;
import mlfe.mapleparser.lexer.source;
public import std.container;
import std.variant, std.conv, std.range;

/// A token
final struct Token
{
	private alias ValueType = Algebraic!(string, real, float, double, long, ulong);
	private Location _at;
	private TokenType _type;
	private ValueType _val;
	private bool has_value = false;
	
	/// Immutable Duplication
	public @property dup() immutable pure
	{
		return Token(this._at, this._type, this._val, this.has_value);
	}
	/// Duplication
	public @property dup() pure
	{
		return Token(this._at, this._type, this._val, this.has_value);
	}
	
	/// Private constructor for idup
	private this(Location l, TokenType t, ValueType v, bool hv) pure
	{
		this._at = l;
		this._type = t;
		this._val = v;
		this.has_value = hv;
	}
	
	/// Construct token
	public this(Location a, TokenType t) pure
	{
		this._at = a;
		this._type = t;
	}
	/// Construct token with string value
	public this(Location a, TokenType t, immutable(string) v) pure
	{
		this._at = a;
		this._type = t;
		this._val = v.idup;
		this.has_value = true;
	}
	/// Construct token with real value
	public this(Location a, TokenType t, real r) pure
	{
		this._at = a;
		this._type = t;
		this._val = r;
		this.has_value = true;
	}
	/// Construct token with float value
	public this(Location a, TokenType t, float f) pure
	{
		this._at = a;
		this._type = t;
		this._val = f;
		this.has_value = true;
	}
	/// Construct token with double value
	public this(Location a, TokenType t, double d) pure
	{
		this._at = a;
		this._type = t;
		this._val = d;
		this.has_value = true;
	}
	/// Construct token with long value
	public this(Location a, TokenType t, long l) pure
	{
		this._at = a;
		this._type = t;
		this._val = l;
		this.has_value = true;
	}
	
public @property:
	/// Location of token in the source
	auto at() const { return this._at; }
	/// Type of token
	auto type() const { return this._type; }
	/// Value of token
	auto value(T)() const { return this._val.get!T; }
	/// Has a value
	auto hasValue() const { return this.has_value; }
}
unittest
{
	assert(Token(Location.init, TokenType.Identifier, "test").dup == Token(Location.init, TokenType.Identifier, "test"));
}

/// List of token(Infinite lazy list)
public struct TokenList
{
	private SourceObject rest_source;
	private bool has_stock = false;
	private Token current_stock;
	private SourceObject rest_next;
	
	private @property pointer_at() { return this.rest_source.current; }
	
	/// Construct from source
	public this(SourceObject from)
	{
		this.rest_source = from;
		this.has_stock = false;
	}
	
	/// Range Primitive: Returns if range is empty(always false)
	immutable bool empty = false;
	/// Range Primitive: Front element
	public @property Token front()
	{
		if(this.rest_source.range.empty) return Token(this.pointer_at, TokenType.EndOfScript);
		if(!this.has_stock) this.parseToken();
		return this.current_stock;
	}
	/// Range Primitive: popFront
	public void popFront()
	{
		if(this.rest_source.range.empty) return;
		if(!this.has_stock) this.parseToken();
		this.rest_source = this.rest_next;
		this.has_stock = false;
	}
	
	private void parseToken()
	{
		auto values = this.rest_source.parseToken1();
		this.rest_next = values[0];
		this.current_stock = values[1];
		this.has_stock = true;
	}
}

/// Types of token
enum TokenType
{
	EndOfScript, StringLiteral, CharacterLiteral, NumericLiteral, FloatLiteral, DoubleLiteral, LongLiteral,
	UlongLiteral, HexadecimalLiteral, Identifier,
	
	LeftAngleBracket2_Equal, RightAngleBracket2_Equal,
	
	Plus_Equal, Minus_Equal, Asterisk_Equal, Slash_Equal, Percent_Equal, Ampasand_Equal, VerticalLine_Equal, Accent_Equal,
	LeftAngleBracket_Equal, RightAngleBracket_Equal, Exclamation_Equal,
	Plus2, Minus2, Asterisk2, LeftAngleBracket2, RightAngleBracket2, Equal2, Ampasand2, VerticalLine2,
	Minus_RightAngleBracket, LeftAngleBracket_Minus,
	
	Plus, Minus, Asterisk, Slash, Percent, Ampasand, VerticalLine, Accent, LeftAngleBracket, RightAngleBracket, Equal,
	Hatena, Sharp, Exclamation, Tilda,
	Comma, Colon, Semicolon, Period,
	OpenParenthese, CloseParenthese, OpenBracket, CloseBracket, OpenBrace, CloseBrace,
	
	Package, This, Super
}
