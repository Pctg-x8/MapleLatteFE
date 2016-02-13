module mlfe.mapleparser.parser.statement;

import mlfe.mapleparser.parser.expression;
import mlfe.mapleparser.parser.base;
import mlfe.mapleparser.parser.exceptions;
import mlfe.mapleparser.parser.type;
import mlfe.mapleparser.lexer.token;
import std.algorithm, std.range;

/// Statement = IfStatement | StatementBlock | Expression ";" | ";"
public static class Statement
{
	public static bool canParse(TokenList input)
	{
		return [TokenType.Semicolon, TokenType.OpenBrace, TokenType.If].any!(a => a == input.front.type)
			|| Expression.canParse(input);
	}
	public static TokenList parse(TokenList input)
	{
		switch(input.front.type)
		{
		case TokenType.If: return IfStatement.parse(input);
		case TokenType.OpenBrace: return StatementBlock.parse(input);
		case TokenType.Semicolon: return input.dropOne;
		default: return Expression.parse(input).consumeToken!(TokenType.Semicolon);
		}
	}
}

/// StatementBlock = "{" (LocalVariableDeclarator | Statement)* "}"
public static class StatementBlock
{
	public static bool canParse(TokenList input)
	{
		return input.front.type == TokenType.OpenBrace;
	}
	public static TokenList parse(TokenList input)
	{
		static TokenList loop(TokenList input)
		{
			if(input.front.type == TokenType.CloseBrace) return input.dropOne;
			
			if([TokenType.Var, TokenType.Val, TokenType.Const].any!(a => input.front.type == a))
				return loop(LocalVariableDeclarator.parse(input));
			auto vdd = VariableDeclarator.drops(Type.drops(input));
			if([TokenType.Semicolon, TokenType.Comma].any!(a => a == vdd.front.type))
				return loop(LocalVariableDeclarator.parse(input));
			
			return loop(Statement.parse(input));
		}
		return loop(input.consumeToken!(TokenType.OpenBrace));
	}
}

/// LocalVariableDeclarator = ("var" | "val" | "const" [Type]) VariableDeclarator ("," VariableDeclarator)* ";"
///		| Type VariableDeclarator ("," VariableDeclarator)* ";"
public static class LocalVariableDeclarator
{
	public static bool canParse(TokenList input)
	{
		return [TokenType.Var, TokenType.Val, TokenType.Const].any!(a => a == input.front.type)
			|| Type.canParse(input);
	}
	public static TokenList parse(TokenList input)
	{
		static TokenList loop(TokenList input)
		{
			return input.front.type == TokenType.Comma ? loop(VariableDeclarator.parse(input.dropOne)) : input;
		}
		
		switch(input.front.type)
		{
		case TokenType.Var: case TokenType.Val:
			return loop(VariableDeclarator.parse(input.dropOne)).consumeToken!(TokenType.Semicolon);
		case TokenType.Const:
		{
			auto in2_vd = VariableDeclarator.drops(Type.drops(input.dropOne));
			if([TokenType.Semicolon, TokenType.Comma].any!(a => a == in2_vd.front.type))
			{
				return loop(VariableDeclarator.parse(Type.parse(input.dropOne))).consumeToken!(TokenType.Semicolon);
			}
			else
			{
				return loop(VariableDeclarator.parse(input.dropOne)).consumeToken!(TokenType.Semicolon);
			}
		}
		default: return loop(VariableDeclarator.parse(Type.parse(input))).consumeToken!(TokenType.Semicolon);
		}
	}
}
/// VariableDeclarator = Identifier ["=" TriExpression]
public static class VariableDeclarator
{
	public static bool canParse(TokenList input)
	{
		return input.front.type == TokenType.Identifier;
	}
	public static TokenList drops(TokenList input)
	{
		if(input.front.type != TokenType.Identifier) return input;
		if(input.dropOne.front.type == TokenType.Equal) return TriExpression.drops(input.drop(2));
		else return input.dropOne;
	}
	public static TokenList parse(TokenList input)
	{
		auto in2 = input.consumeToken!(TokenType.Identifier);
		if(in2.front.type == TokenType.Equal)
		{
			return TriExpression.parse(in2.dropOne);
		}
		else return in2;
	}
}

/// IfStatement = "if" "(" Expression ")" Statement ["else" Statement]
public static class IfStatement
{
	public static bool canParse(TokenList input)
	{
		return input.front.type == TokenType.If;
	}
	public static TokenList parse(TokenList input)
	{
		auto in2 = Statement.parse(Expression.parse(input.consumeToken!(TokenType.If).consumeToken!(TokenType.OpenParenthese))
			.consumeToken!(TokenType.CloseParenthese));
		if(in2.front.type == TokenType.Else)
		{
			return Statement.parse(in2.dropOne);
		}
		else return in2;
	}
}
