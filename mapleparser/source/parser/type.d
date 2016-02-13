module mlfe.mapleparser.parser.type;

import mlfe.mapleparser.parser.base;
import mlfe.mapleparser.parser.symbol;
import mlfe.mapleparser.parser.exceptions;
import mlfe.mapleparser.lexer.token;
import std.algorithm, std.range;

/// BuiltinType(Set of tokens) = "void" | "char" | "uchar" | "byte" | "short" | "ushort" | "word"
///			| "int" | "uint" | "dword" | "long" | "ulong" | "qword" | "float" | "double"
public static class BuiltinType
{
	public static bool canParse(TokenList input)
	{
		return [TokenType.Void, TokenType.Char, TokenType.Uchar, TokenType.Byte,
			TokenType.Short, TokenType.Ushort, TokenType.Word, TokenType.Int, TokenType.Uint, TokenType.Dword,
			TokenType.Long, TokenType.Ulong, TokenType.Qword, TokenType.Float, TokenType.Double]
			.any!(a => a == input.front.type);
	}
	public static TokenList drops(TokenList input)
	{
		return canParse(input) ? input.dropOne : input;
	}
	public static TokenList parse(TokenList input)
	{
		switch(input.front.type)
		{
		case TokenType.Void: return input.dropOne;
		case TokenType.Char: return input.dropOne;
		case TokenType.Uchar: return input.dropOne;
		case TokenType.Byte: return input.dropOne;
		case TokenType.Short: return input.dropOne;
		case TokenType.Ushort: return input.dropOne;
		case TokenType.Word: return input.dropOne;
		case TokenType.Int: return input.dropOne;
		case TokenType.Uint: return input.dropOne;
		case TokenType.Dword: return input.dropOne;
		case TokenType.Long: return input.dropOne;
		case TokenType.Ulong: return input.dropOne;
		case TokenType.Qword: return input.dropOne;
		case TokenType.Float: return input.dropOne;
		case TokenType.Double: return input.dropOne;
		default: throw new ParseException("No match tokens found", input.front.at);
		}
	}
}

/// BasicType = BuiltinType
///	| TemplateInstance ("." TemplateInstance)*
///	| "." TemplateInstance ("." TemplateInstance)*
///	| "global" "." TemplateInstance ("." TemplateInstance)*
public static class BasicType
{
	public static bool canParse(TokenList input)
	{
		return [TokenType.Period, TokenType.Global].any!(a => a == input.front.type)
			|| TemplateInstance.canParse(input) || BuiltinType.canParse(input);
	}
	public static TokenList drops(TokenList input)
	{
		static TokenList loop(TokenList input)
		{
			return input.front.type == TokenType.Period ? loop(TemplateInstance.drops(input.dropOne)) : input;
		}
		
		switch(input.front.type)
		{
		case TokenType.Global:
			if(input.dropOne.front.type != TokenType.Period) return input;
			return loop(TemplateInstance.drops(input.dropOne));
		case TokenType.Period:
			return loop(TemplateInstance.drops(input.dropOne));
		default:
			if(TemplateInstance.canParse(input)) return loop(TemplateInstance.drops(input));
			else return BuiltinType.drops(input);
		}
	}
	public static TokenList parse(TokenList input)
	{
		static TokenList loop(TokenList input)
		{
			return input.front.type == TokenType.Period ? loop(TemplateInstance.parse(input.dropOne)) : input;
		}
		
		switch(input.front.type)
		{
		case TokenType.Global:
			return loop(TemplateInstance.parse(input.dropOne.consumeToken!(TokenType.Period)));
		case TokenType.Period:
			return loop(TemplateInstance.parse(input.dropOne));
		default:
			if(TemplateInstance.canParse(input)) return loop(TemplateInstance.parse(input));
			else return BuiltinType.parse(input);
		}
	}
}

/// Type = BasicType
public static class Type
{
	public static bool canParse(TokenList input) { return BasicType.canParse(input); }
	public static TokenList drops(TokenList input) { return BasicType.drops(input); }
	public static TokenList parse(TokenList input)
	{
		return BasicType.parse(input);
	}
}
