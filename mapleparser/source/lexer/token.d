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
	private string sourceText;
	
	/// Duplication
	public @property dup() pure
	{
		return Token(this._at, this._type, this._val, this.sourceText);
	}
	
	/// Private constructor for idup
	private this(Location l, TokenType t, ValueType v, immutable string st) pure
	{
		this._at = l;
		this._type = t;
		this._val = v;
		this.sourceText = st.dup;
	}
	
	/// Construct token with string value
	public this(Location a, TokenType t, immutable string v) pure
	{
		this._at = a;
		this._type = t;
		this._val = v.idup;
		this.sourceText = v;
	}
	/// Construct token with real value
	public this(Location a, TokenType t, immutable string st, real r) pure
	{
		this._at = a;
		this._type = t;
		this._val = r;
		this.sourceText = st.dup;
	}
	/// Construct token with float value
	public this(Location a, TokenType t, immutable string st, float f) pure
	{
		this._at = a;
		this._type = t;
		this._val = f;
		this.sourceText = st.dup;
	}
	/// Construct token with double value
	public this(Location a, TokenType t, immutable string st, double d) pure
	{
		this._at = a;
		this._type = t;
		this._val = d;
		this.sourceText = st.dup;
	}
	/// Construct token with long value
	public this(Location a, TokenType t, immutable string st, long l) pure
	{
		this._at = a;
		this._type = t;
		this._val = l;
		this.sourceText = st.dup;
	}
	
public @property:
	/// Location of token in the source
	auto at() const { return this._at; }
	/// Type of token
	auto type() const { return this._type; }
	/// Value of token
	auto value(T)() const { return this._val.get!T; }
	/// Has a value of specified type
	auto hasValue(T)() const { return this._val.peek!T !is null; }
	/// Source text
	auto source() const { return this.sourceText; }
}
unittest
{
	assert(Token(Location.init, TokenType.Identifier, "test").dup == Token(Location.init, TokenType.Identifier, "test"));
	assert(Token(Location(4, 3), TokenType.Identifier, "test").at == Location(4, 3));
}

/// List of token(Infinite lazy list)
public struct TokenList
{
	private string sourceRest;
	private Location locationRest;
	private Token[] parsedTokens;
	private size_t currentPointer;
	
	// Editor Settings //
	/// Spaces of tab(Default is 4)
	private uint tabSpace = 4;
	
	/// Construct from source
	public this(immutable string source, uint tabSpace = 4)
	{
		this.sourceRest = source.idup;
		this.locationRest = Location(1, 1);
		this.parsedTokens = null;
		this.currentPointer = 0;
		this.tabSpace = tabSpace;
	}
	
	/// Range Primitive: Returns true if range is empty(always false)
	immutable bool empty = false;
	/// Range Primitive: Front element
	public @property Token front()
	{
		if(this.parsedTokens.length > this.currentPointer) return this.parsedTokens[this.currentPointer];
		
		if(this.sourceRest.empty) return Token(this.locationRest, TokenType.EndOfScript, "");
		while(this.parsedTokens.length <= this.currentPointer)
		{
			if(this.sourceRest.empty) return Token(this.locationRest, TokenType.EndOfScript, "");
			this.addToken();
		}
		return this.parsedTokens[this.currentPointer];
	}
	/// Range Primitive: popFront
	public void popFront()
	{
		this.currentPointer++;
	}
	
	private void addToken()
	{
		auto values = SourceObject(this.sourceRest, this.locationRest, this.tabSpace).parseToken1;
		import std.stdio : writeln;
		this.sourceRest = values[0].range;
		this.locationRest = values[0].current;
		this.parsedTokens ~= values[1];
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
	Minus_RightAngleBracket, LeftAngleBracket_Minus, Equal_RightAngleBracket,
	
	Plus, Minus, Asterisk, Slash, Percent, Ampasand, VerticalLine, Accent, LeftAngleBracket, RightAngleBracket, Equal,
	Hatena, Sharp, Exclamation, Tilda,
	Comma, Colon, Semicolon, Period,
	OpenParenthese, CloseParenthese, OpenBracket, CloseBracket, OpenBrace, CloseBrace,
	
	Package, This, Super, Global, If, Else, For, Foreach, While, Do, Break, Continue, Return, Match,
	Void, Char, Uchar, Byte, Short, Ushort, Word, Int, Uint, Dword, Long, Ulong, Qword, Float, Double, Auto,
	Var, Val, Const, In, Throw, Try, Catch, Finally, Switch, Case, Default, New, True, False,
	Static, Property, Public, Private, Protected, Override, Final, Partial,
	Class, Extends, With, Trait, Enum, Template, Alias, Import
}
bool isControlKeyword(TokenType t)
{
	import std.algorithm : any;
	
	return [TokenType.Package,
		TokenType.If, TokenType.Else, TokenType.For, TokenType.Foreach, TokenType.While, TokenType.Do,
		TokenType.Break, TokenType.Continue, TokenType.Return, TokenType.Throw,
		TokenType.Try, TokenType.Catch, TokenType.Finally, TokenType.Switch, TokenType.Case, TokenType.Default,
		TokenType.In]
		.any!(a => a == t);
}
bool isExpressionKeyword(TokenType t)
{
	import std.algorithm : any;
	
	return [TokenType.This, TokenType.Super, TokenType.Global,
		TokenType.New, TokenType.True, TokenType.False]
		.any!(a => a == t);
}
bool isTypeKeyword(TokenType t)
{
	import std.algorithm : any;
	
	return [TokenType.Void, TokenType.Char, TokenType.Uchar, TokenType.Byte, TokenType.Short, TokenType.Ushort,
		TokenType.Word, TokenType.Int, TokenType.Uint, TokenType.Dword, TokenType.Long, TokenType.Ulong,
		TokenType.Qword, TokenType.Float, TokenType.Double, TokenType.Auto, TokenType.Var, TokenType.Val, TokenType.Const]
		.any!(a => a == t);
}
