module mlfe.mapleparser.parser.statement;

import mlfe.mapleparser.parser.expression;
import mlfe.mapleparser.parser.base;
import mlfe.mapleparser.parser.exceptions;
import mlfe.mapleparser.parser.type;
import mlfe.mapleparser.lexer.token;
import std.algorithm, std.range;

/// Statement = IfStatement | WhileStatement | DoStatement | ForStatement | ForeachStatement
///	| NamedStatements | "break" [Identifier] ";" | "continue" [Identifier] ";" | "return" [Expression] ";"
/// | "throw" Expression ";" | TryStatement | SwitchStatement
///	| StatementBlock | Expression ";" | ";"
public static class Statement
{
	public static bool canParse(TokenList input)
	{
		return [TokenType.Semicolon, TokenType.OpenBrace,
			TokenType.If, TokenType.While, TokenType.Do, TokenType.For, TokenType.Foreach,
			TokenType.Identifier, TokenType.Break, TokenType.Continue, TokenType.Return,
			TokenType.Throw, TokenType.Try, TokenType.Switch]
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
		case TokenType.Switch: return SwitchStatement.parse(input);
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
		return input.consumeToken!(TokenType.For).consumeToken!(TokenType.OpenParenthese)
			.then!((a)
			{
				if(a.front.type == TokenType.Semicolon) return a.dropOne;
				if([TokenType.Val, TokenType.Var, TokenType.Const, TokenType.Auto].any!(b => b == a.front.type))
				{
					return LocalVariableDeclarator.parse(a);
				}
				auto vdd = VariableDeclarator.drops(InferableType.drops(a));
				if([TokenType.Semicolon, TokenType.Colon].any!(b => vdd.front.type == b))
				{
					return LocalVariableDeclarator.parse(a);
				}
				else return Expression.parse(a).consumeToken!(TokenType.Semicolon);
			})
			.then!(a => a.front.type == TokenType.Semicolon ? a.dropOne : Expression.parse(a).consumeToken!(TokenType.Semicolon))
			.then!(a => a.front.type == TokenType.CloseParenthese ? a.dropOne : Expression.parse(a).consumeToken!(TokenType.CloseParenthese))
			.then!(a => Statement.parse(a));
	}
}
/// ForeachStatement = "foreach" "(" ("var" | "val" | "const" [InferableType] | InferableType)
///		Identifier "in" Expression ")" Statement
public static class ForeachStatement
{
	public static bool canParse(TokenList input)
	{
		return input.front.type == TokenType.Foreach;
	}
	public static TokenList parse(TokenList input)
	{
		return input.consumeToken!(TokenType.Foreach).consumeToken!(TokenType.OpenParenthese)
			.then!((a)
			{
				if([TokenType.Var, TokenType.Val].any!(b => b == a.front.type))
				{
					return a.dropOne;
				}
				if(a.front.type == TokenType.Const)
				{
					auto it = InferableType.drops(a.dropOne);
					return it.front.type == TokenType.Identifier ? InferableType.parse(a.dropOne) : a.dropOne;
				}
				return InferableType.parse(a);
			})
			.then!(a => Expression.parse(a.consumeToken!(TokenType.Identifier).consumeToken!(TokenType.In)))
			.then!(a => Statement.parse(a.consumeToken!(TokenType.CloseParenthese)));
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
/// SwitchStatement = "switch" "(" Expression ")" "{" (CaseClause | DefaultClause)* "}"
public static class SwitchStatement
{
	public static bool canParse(TokenList input)
	{
		return input.front.type == TokenType.Switch;
	}
	public static TokenList parse(TokenList input)
	{
		return input.consumeToken!(TokenType.Switch)
			.then!(a => Expression.parse(a.consumeToken!(TokenType.OpenParenthese)).consumeToken!(TokenType.CloseParenthese))
			.consumeToken!(TokenType.OpenBrace)
			.thenLoop!(a => CaseClause.canParse(a) || DefaultClause.canParse(a), (a)
			{
				return CaseClause.canParse(a) ? CaseClause.parse(a) : DefaultClause.parse(a);
			})
			.consumeToken!(TokenType.CloseBrace);
	}
}
/// DefaultClause = "default" "=>" Statement
public static class DefaultClause
{
	public static bool canParse(TokenList input)
	{
		return input.front.type == TokenType.Default;
	}
	public static TokenList parse(TokenList input)
	{
		return input.consumeToken!(TokenType.Default).consumeToken!(TokenType.Equal_RightAngleBracket)
			.then!(a => Statement.parse(a));
	}
}
/// CaseClause = ValueCaseClause | TypeMatchingCaseClause
public static class CaseClause
{
	public static bool canParse(TokenList input)
	{
		return input.front.type == TokenType.Case;
	}
	public static TokenList parse(TokenList input)
	{
		if(input.take(3).map!(a => a.type).equal([TokenType.Case, TokenType.Identifier, TokenType.Colon]))
		{
			return TypeMatchingCaseClause.parse(input);
		}
		else return ValueCaseClause.parse(input);
	}
}
/// ValueCaseClause = "case" ExpressionList "=>" Statement
public static class ValueCaseClause
{
	public static bool canParse(TokenList input)
	{
		return input.front.type == TokenType.Case;
	}
	public static TokenList parse(TokenList input)
	{
		return input.consumeToken!(TokenType.Case)
			.then!(a => ExpressionList.parse(a).consumeToken!(TokenType.Equal_RightAngleBracket))
			.then!(Statement.parse);
	}
}
/// TypeMatchingCaseClause = "case" Identifier ":" Type ("," Identifier ":" Type)* "=>" Statement
public static class TypeMatchingCaseClause
{
	public static bool canParse(TokenList input)
	{
		return input.front.type == TokenType.Case;
	}
	public static TokenList parse(TokenList input)
	{
		return input.consumeToken!(TokenType.Case).consumeToken!(TokenType.Identifier).consumeToken!(TokenType.Colon)
			.then!(Type.parse)
			.thenLoop!(a => a.front.type == TokenType.Comma,
				a => Type.parse(a.dropOne.consumeToken!(TokenType.Identifier).consumeToken!(TokenType.Colon)))
			.then!(a => Statement.parse(a.consumeToken!(TokenType.Equal_RightAngleBracket)));
	}
}
