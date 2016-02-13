module mlfe.mapleparser.parser.type;

import mlfe.mapleparser.parser.base;
import mlfe.mapleparser.parser.symbol;
import mlfe.mapleparser.parser.expression;
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

/// ConstructableType = "const" "(" Type ")" | "(" Type ")" | BasicType
public static class ConstructableType
{
	public static bool canParse(TokenList input)
	{
		return [TokenType.Const, TokenType.OpenParenthese].any!(a => a == input.front.type)
			|| BasicType.canParse(input);
	}
	public static TokenList drops(TokenList input)
	{
		if(input.front.type == TokenType.OpenParenthese)
		{
			auto in2 = Type.drops(input.dropOne);
			if(in2.front.type == TokenType.CloseParenthese) return in2.dropOne;
			else return input;
		}
		else if(input.front.type == TokenType.Const && input.dropOne.front.type == TokenType.OpenParenthese)
		{
			auto in2 = Type.drops(input.drop(2));
			if(in2.front.type == TokenType.CloseParenthese) return in2.dropOne;
			else return input;
		}
		else return BasicType.drops(input);
	}
	public static TokenList parse(TokenList input)
	{
		switch(input.front.type)
		{
		case TokenType.Const:
			return Type.parse(input.dropOne.consumeToken!(TokenType.OpenParenthese)).consumeToken!(TokenType.CloseParenthese);
		case TokenType.OpenParenthese:
			return Type.parse(input.dropOne).consumeToken!(TokenType.CloseParenthese);
		default: return BasicType.parse(input);
		}
	}
}

/// Type = ConstructableType ("[" [Expression] "]")*
public static class Type
{
	public static bool canParse(TokenList input) { return ConstructableType.canParse(input); }
	public static TokenList drops(TokenList input)
	{
		static TokenList loop(TokenList input)
		{
			if(input.front.type == TokenType.OpenBracket)
			{
				if(input.dropOne.front.type == TokenType.CloseBracket) return loop(input.drop(2));
				auto in2 = Expression.drops(input.dropOne);
				if(in2.dropOne.front.type == TokenType.CloseBracket) return loop(in2.dropOne);
				return input;
			}
			else return input;
		}
		return loop(ConstructableType.drops(input));
	}
	public static TokenList parse(TokenList input)
	{
		static TokenList loop(TokenList input)
		{
			if(input.front.type == TokenType.OpenBracket)
			{
				if(input.dropOne.front.type == TokenType.CloseBracket) return loop(input.drop(2));
				return loop(Expression.parse(input.dropOne).consumeToken!(TokenType.CloseBracket));
			}
			else return input;
		}
		return loop(ConstructableType.parse(input));
	}
}
