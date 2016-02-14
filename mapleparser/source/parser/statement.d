module mlfe.mapleparser.parser.statement;

import mlfe.mapleparser.parser.expression;
import mlfe.mapleparser.parser.base;
import mlfe.mapleparser.parser.exceptions;
import mlfe.mapleparser.parser.type;
import mlfe.mapleparser.lexer.token;
import std.algorithm, std.range;

/// Statement = IfStatement | WhileStatement | DoStatement | ForStatement | ForeachStatement
///	| NamedStatements | "break" [Identifier] ";" | "continue" [Identifier] ";" | "return" [Expression] ";"
/// | "throw" Expression ";" | TryStatement
///	| StatementBlock | Expression ";" | ";"
public static class Statement
{
	public static bool canParse(TokenList input)
	{
		return [TokenType.Semicolon, TokenType.OpenBrace,
			TokenType.If, TokenType.While, TokenType.Do, TokenType.For, TokenType.Foreach,
			TokenType.Identifier, TokenType.Break, TokenType.Continue, TokenType.Return,
			TokenType.Throw, TokenType.Try]
			.any!(a => a == input.front.type)
			|| Expression.canParse(input);
	}
	public static TokenList parse(TokenList input)
	{
		switch(input.front.type)
		{
		case TokenType.If: return IfStatement.parse(input);
		case TokenType.While: return WhileStatement.parse(input);
		case TokenType.Do: return DoStatement.parse(input);
		case TokenType.For: return ForStatement.parse(input);
		case TokenType.Foreach: return ForeachStatement.parse(input);
		case TokenType.Break:
			if(input.dropOne.front.type == TokenType.Semicolon) return input.drop(2);
			return input.dropOne.consumeToken!(TokenType.Identifier).consumeToken!(TokenType.Semicolon);
		case TokenType.Continue:
			if(input.dropOne.front.type == TokenType.Semicolon) return input.drop(2);
			return input.dropOne.consumeToken!(TokenType.Identifier).consumeToken!(TokenType.Semicolon);
		case TokenType.Return:
			if(input.dropOne.front.type == TokenType.Semicolon) return input.drop(2);
			return Expression.parse(input.dropOne).consumeToken!(TokenType.Semicolon);
		case TokenType.Identifier:
			if(input.dropOne.front.type == TokenType.Colon)
			{
				return NamedStatements.parse(input);
			}
			else goto default;
		case TokenType.Throw:
			return Expression.parse(input.dropOne).consumeToken!(TokenType.Semicolon);
		case TokenType.Try: return TryStatement.parse(input);
		case TokenType.OpenBrace: return StatementBlock.parse(input);
		case TokenType.Semicolon: return input.dropOne;
		default: return Expression.parse(input).consumeToken!(TokenType.Semicolon);
		}
	}
}
/// NamedStatements = Identifier ":" (WhileStatement | DoStatement | ForStatement | ForeachStatement)
public static class NamedStatements
{
	public static bool canParse(TokenList input)
	{
		return input.front.type == TokenType.Identifier;
	}
	public static TokenList parse(TokenList input)
	{
		auto in2 = input.consumeToken!(TokenType.Identifier).consumeToken!(TokenType.Colon);
		switch(in2.front.type)
		{
		case TokenType.While: return WhileStatement.parse(in2);
		case TokenType.Do: return DoStatement.parse(in2);
		case TokenType.For: return ForStatement.parse(in2);
		case TokenType.Foreach: return ForeachStatement.parse(in2);
		default: throw new ParseException("No match rules found", in2.front.at);
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
			
			if([TokenType.Var, TokenType.Val, TokenType.Const, TokenType.Auto].any!(a => input.front.type == a))
				return loop(LocalVariableDeclarator.parse(input));
			auto vdd = InferableType.drops(input);
			if(vdd.front.type == TokenType.Identifier)
				return loop(LocalVariableDeclarator.parse(input));
			
			return loop(Statement.parse(input));
		}
		return loop(input.consumeToken!(TokenType.OpenBrace));
	}
}

/// LocalVariableDeclarator = ("var" | "val" | "const" [InferableType]) VariableDeclarator ("," VariableDeclarator)* ";"
///		| InferableType VariableDeclarator ("," VariableDeclarator)* ";"
public static class LocalVariableDeclarator
{
	public static bool canParse(TokenList input)
	{
		return [TokenType.Var, TokenType.Val, TokenType.Const].any!(a => a == input.front.type)
			|| InferableType.canParse(input);
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
			auto in2_vd = InferableType.drops(input.dropOne);
			if(in2_vd.front.type == TokenType.Identifier)
			{
				return loop(VariableDeclarator.parse(InferableType.parse(input.dropOne))).consumeToken!(TokenType.Semicolon);
			}
			else
			{
				return loop(VariableDeclarator.parse(input.dropOne)).consumeToken!(TokenType.Semicolon);
			}
		}
		default: return loop(VariableDeclarator.parse(InferableType.parse(input))).consumeToken!(TokenType.Semicolon);
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
/// WhileStatement = "while" "(" Expression ")" Statement
public static class WhileStatement
{
	public static bool canParse(TokenList input)
	{
		return input.front.type == TokenType.While;
	}
	public static TokenList parse(TokenList input)
	{
		return Statement.parse(Expression.parse(input.consumeToken!(TokenType.While).consumeToken!(TokenType.OpenParenthese))
			.consumeToken!(TokenType.CloseParenthese));
	}
}
/// DoStatement = "do" Statement "while" "(" Expression ")" ";"
public static class DoStatement
{
	public static bool canParse(TokenList input)
	{
		return input.front.type == TokenType.Do;
	}
	public static TokenList parse(TokenList input)
	{
		return Expression.parse(Statement.parse(input.consumeToken!(TokenType.Do))
			.consumeToken!(TokenType.While).consumeToken!(TokenType.OpenParenthese))
			.consumeToken!(TokenType.CloseParenthese).consumeToken!(TokenType.Semicolon);
	}
}
/// ForStatement = "for" "(" (LocalVariableDeclarator | Expression ";" | ";") [Expression] ";" [Expression] ")" Statement
public static class ForStatement
{
	public static bool canParse(TokenList input)
	{
		return input.front.type == TokenType.For;
	}
	public static TokenList parse(TokenList input)
	{
		static TokenList cont2(TokenList input)
		{
			/// [Expression] ")" Statement
			if(input.front.type == TokenType.CloseParenthese) return Statement.parse(input.dropOne);
			else return Statement.parse(Expression.parse(input).consumeToken!(TokenType.CloseParenthese));
		}
		static TokenList cont(TokenList input)
		{
			/// [Expression] ";" [Expression] ")" Statement
			if(input.front.type == TokenType.Semicolon) return cont2(input.dropOne);
			else return cont2(Expression.parse(input).consumeToken!(TokenType.Semicolon));
		}
		
		auto in2 = input.consumeToken!(TokenType.For).consumeToken!(TokenType.OpenParenthese);
		if(in2.front.type == TokenType.Semicolon) return cont(in2.dropOne);
		if([TokenType.Val, TokenType.Var, TokenType.Const, TokenType.Auto].any!(a => a == in2.front.type))
		{
			return cont(LocalVariableDeclarator.parse(in2));
		}
		else
		{
			auto vdd = VariableDeclarator.drops(InferableType.drops(in2));
			if([TokenType.Semicolon, TokenType.Colon].any!(a => vdd.front.type == a))
			{
				return cont(LocalVariableDeclarator.parse(in2));
			}
			else
			{
				return cont(Expression.parse(in2).consumeToken!(TokenType.Semicolon));
			}
		}
	}
}
/// ForeachStatement = "foreach" "(" ["var" | "val" | "const" [InferableType] | InferableType]
///		Identifier ("[" Expression "]")* "in" Expression ")" Statement
public static class ForeachStatement
{
	public static bool canParse(TokenList input)
	{
		return input.front.type == TokenType.Foreach;
	}
	public static TokenList parse(TokenList input)
	{
		static TokenList loop(TokenList input)
		{
			/// ("[" Expression "]")*
			return input.front.type == TokenType.OpenBracket
				? loop(Expression.parse(input.dropOne).consumeToken!(TokenType.CloseBracket))
				: input;
		}
		static TokenList cont(TokenList input)
		{
			/// Identifier ("[" Expression "]")* "in" Expression ")" Statement
			return Statement.parse(Expression.parse(loop(input.consumeToken!(TokenType.Identifier)).consumeToken!(TokenType.In))
				.consumeToken!(TokenType.CloseParenthese));
		}
		
		auto in2 = input.consumeToken!(TokenType.Foreach).consumeToken!(TokenType.OpenParenthese);
		if([TokenType.Var, TokenType.Val].any!(a => a == in2.front.type))
		{
			return cont(in2.dropOne);
		}
		else if(in2.front.type == TokenType.Const)
		{
			auto it = InferableType.drops(in2.dropOne);
			if(it.front.type == TokenType.Identifier) return cont(InferableType.parse(in2.dropOne));
			else return cont(in2.dropOne);
		}
		else
		{
			auto vdd = InferableType.drops(in2);
			if(vdd.front.type == TokenType.Identifier) return cont(InferableType.parse(in2));
			else return cont(in2);
		}
	}
}
/// TryStatement = "try" Statement CatchClause* [FinallyClause]
public static class TryStatement
{
	public static bool canParse(TokenList input)
	{
		return input.front.type == TokenType.Try;
	}
	public static TokenList parse(TokenList input)
	{
		return Statement.parse(input.consumeToken!(TokenType.Try))
			.thenLoop!(a => CatchClause.canParse(a), a => CatchClause.parse(a))
			.thenIf!(a => FinallyClause.canParse(a), a => FinallyClause.parse(a));
	}
}
/// CatchClause = "catch" "(" ["const"] Type Identifier ")" Statement
public static class CatchClause
{
	public static bool canParse(TokenList input)
	{
		return input.front.type == TokenType.Catch;
	}
	public static TokenList parse(TokenList input)
	{
		return input.consumeToken!(TokenType.Catch).consumeToken!(TokenType.OpenParenthese)
			.thenIf!(a => a.front.type == TokenType.Const, a => a.dropOne)
			.then!(a => Type.parse(a).consumeToken!(TokenType.Identifier).consumeToken!(TokenType.CloseParenthese))
			.then!(a => Statement.parse(a));
	}
}
/// FinallyClause = "finally" Statement
public static class FinallyClause
{
	public static bool canParse(TokenList input)
	{
		return input.front.type == TokenType.Finally;
	}
	public static TokenList parse(TokenList input)
	{
		return Statement.parse(input.consumeToken!(TokenType.Finally));
	}
}
