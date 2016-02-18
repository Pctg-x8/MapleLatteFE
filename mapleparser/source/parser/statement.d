module mlfe.mapleparser.parser.statement;

import mlfe.mapleparser.parser.expression;
import mlfe.mapleparser.parser.base;
import mlfe.mapleparser.parser.exceptions;
import mlfe.mapleparser.parser.type;
import mlfe.mapleparser.lexer.token;
import std.algorithm, std.range;

/// Statement = NamedStatement / IfStatement / WhileStatement / DoWhileStatement
/// / ForStatement / ForeachStatement / ControlPathStatements
/// / ThrowStatement / TryStatement / SwitchStatement
/// / StatementBlock / Expression ";" / ";"
public ParseResult matchStatement(ParseResult input)
{
	return input.select!(
		matchNamedStatement,
		matchIfStatement, matchWhileStatement, matchDoWhileStatement,
		matchForStatement, matchForeachStatement, matchControlPathStatements,
		matchThrowStatement, matchTryStatement, matchSwitchStatement,
		matchStatementBlock,
		x => x.matchExpression.matchToken!(TokenType.Semicolon),
		matchToken!(TokenType.Semicolon)
	);
}
unittest
{
	import mlfe.mapleparser.lexer : asTokenList;

	assert(Cont("if(true) a = 0; else b = 0;".asTokenList).matchStatement.succeeded);
	assert(Cont("if(x < 2) a = true;".asTokenList).matchStatement.succeeded);
	assert(Cont("while(true) a++;".asTokenList).matchStatement.succeeded);
	assert(Cont("for(int x = 0; x < 3; x++) writeln(x);".asTokenList).matchStatement.succeeded);
	assert(Cont("for(var b = 0; b < 3; b++) println(x);".asTokenList).matchStatement.succeeded);
	assert(Cont("do a++; while(true);".asTokenList).matchStatement.succeeded);
	assert(Cont("foreach(var a in chars) a.die();".asTokenList).matchStatement.succeeded);
	assert(!Cont("do a++ while(true);".asTokenList).matchStatement.succeeded);
	assert(Cont("lp0: while(true) update();".asTokenList).matchStatement.succeeded);
	assert(Cont("while(true) { a++; if(a > 30) break; }".asTokenList).matchStatement.succeeded);
	assert(Cont("lp0: foreach(line in lines) { if(a.empty) continue lp0; }".asTokenList).matchStatement.succeeded);
	assert(Cont("return true;".asTokenList).matchStatement.succeeded);
	assert(Cont("throw new Exception(\"null\");".asTokenList).matchStatement.succeeded);
	assert(Cont("try { func_except(); } catch(Exception e) { return e; } finally resource_freeing();".asTokenList)
		.matchStatement.succeeded);
	assert(Cont("switch(a) { case 1: writeln(\"hit!\"); default: /* nothing */; }".asTokenList).matchStatement.succeeded);
	assert(!Cont("switch(a) { case 1: writeln(\"hit!\"); break; default: break; }".asTokenList).matchStatement.succeeded);
}

/// StatementBlock = "{" (LocalVariableDeclarator | Statement)* "}"
public ParseResult matchStatementBlock(ParseResult input)
{
	return input.matchToken!(TokenType.OpenBrace)
		.matchUntilFail!(select!(
			matchLocalVariableDeclarator, matchStatement
		))
		.matchToken!(TokenType.CloseBrace);
}
/// LocalVariableDeclarator = ("var" / "val" / "const" [InferableType] / InferableType)
///	VariableDeclarator ("," VariableDeclarator)* ";"
public ParseResult matchLocalVariableDeclarator(ParseResult input)
{
	return input.select!(
		x => x.matchToken!(TokenType.Var),
		x => x.matchToken!(TokenType.Val),
		x => x.matchToken!(TokenType.Const).ignorable!matchInferableType,
		x => x.matchInferableType
	).matchVariableDeclarator.matchUntilFail!(
		x => x.matchToken!(TokenType.Comma).matchVariableDeclarator
	).matchToken!(TokenType.Semicolon);
}
/// VariableDeclarator = Identifier ["=" TriExpression]
public ParseResult matchVariableDeclarator(ParseResult input)
{
	return input.matchToken!(TokenType.Identifier)
		.ignorable!(x => x.matchToken!(TokenType.Equal).matchTriExpression);
}

/// NamedStatement = Identifier ":" (WhileStatement / DoWhileStatement / ForStatement / ForeachStatement)
public ParseResult matchNamedStatement(ParseResult input)
{
	return input.matchToken!(TokenType.Identifier).matchToken!(TokenType.Colon).select!(
		matchWhileStatement, matchDoWhileStatement, matchForStatement, matchForeachStatement
	);
}

/// IfStatement = "if" "(" Expression ")" Statement ["else" Statement]
public ParseResult matchIfStatement(ParseResult input)
{
	return input.matchToken!(TokenType.If).matchToken!(TokenType.OpenParenthese)
		.matchExpression.matchToken!(TokenType.CloseParenthese)
		.matchStatement.ignorable!(x => x.matchToken!(TokenType.Else).matchStatement);
}
/// WhileStatement = "while" "(" Expression ")" Statement
public ParseResult matchWhileStatement(ParseResult input)
{
	return input.matchToken!(TokenType.While).matchToken!(TokenType.OpenParenthese)
		.matchExpression.matchToken!(TokenType.CloseParenthese).matchStatement;
}
/// DoWhileStatement = "do" Statement "while" "(" Expression ")" ";"
public ParseResult matchDoWhileStatement(ParseResult input)
{
	return input.matchToken!(TokenType.Do).matchStatement
		.matchToken!(TokenType.While).matchToken!(TokenType.OpenParenthese)
		.matchExpression.matchToken!(TokenType.CloseParenthese).matchToken!(TokenType.Semicolon);
}
/// ForStatement = "for" "(" [ForPrimaryClause] ";" [Expression] ";" [Expression] ")" Statement
public ParseResult matchForStatement(ParseResult input)
{
	return input.matchToken!(TokenType.For).matchToken!(TokenType.OpenParenthese)
		.ignorable!matchForPrimaryClause.matchToken!(TokenType.Semicolon)
		.ignorable!matchExpression.matchToken!(TokenType.Semicolon)
		.ignorable!matchExpression.matchToken!(TokenType.CloseParenthese)
		.matchStatement;
}
/// ForPrimaryClause = ("var" / "val" / "const" [InferableType] / InferableType) VariableDeclarator / Expression
public ParseResult matchForPrimaryClause(ParseResult input)
{
	return input.select!(
		x => x.matchToken!(TokenType.Var).matchVariableDeclarator,
		x => x.matchToken!(TokenType.Val).matchVariableDeclarator,
		x => x.matchToken!(TokenType.Const).ignorable!matchInferableType.matchVariableDeclarator,
		x => x.matchInferableType.matchVariableDeclarator,
		x => x.matchExpression
	);
}
/// ForeachStatement = "foreach" "(" ForeachAggregatorClause "in" Expression ")" Statement
public ParseResult matchForeachStatement(ParseResult input)
{
	return input.matchToken!(TokenType.Foreach).matchToken!(TokenType.OpenParenthese)
		.matchForeachAggregatorClause.matchToken!(TokenType.In)
		.matchExpression.matchToken!(TokenType.CloseParenthese).matchStatement;
}
/// ForeachAggregatorClause = ["var" / "val" / "const" [InferableType] / InferableType] Identifier ("," Identifier)*
public ParseResult matchForeachAggregatorClause(ParseResult input)
{
	return input.select!(
		x => x.matchToken!(TokenType.Val).matchToken!(TokenType.Identifier),
		x => x.matchToken!(TokenType.Var).matchToken!(TokenType.Identifier),
		x => x.matchToken!(TokenType.Const).ignorable!matchInferableType.matchToken!(TokenType.Identifier),
		x => x.matchInferableType.matchToken!(TokenType.Identifier),
		x => x.matchToken!(TokenType.Identifier)
	).matchUntilFail!(
		x => x.matchToken!(TokenType.Comma).matchToken!(TokenType.Identifier)
	);
}
/// ControlPathStatements = "break" [Identifier] ";" / "continue" [Identifier] ";" / "return" [Expression] ";"
public ParseResult matchControlPathStatements(ParseResult input)
{
	alias matchIdentifier = matchToken!(TokenType.Identifier);

	return input.selectByType!(
		TokenType.Break, x => x.dropOne.ignorable!matchIdentifier.matchToken!(TokenType.Semicolon),
		TokenType.Continue, x => x.dropOne.ignorable!matchIdentifier.matchToken!(TokenType.Semicolon),
		TokenType.Return, x => x.dropOne.ignorable!matchExpression.matchToken!(TokenType.Semicolon)
	);
}
/// ThrowStatement = "throw" Expression ";"
public ParseResult matchThrowStatement(ParseResult input)
{
	return input.matchToken!(TokenType.Throw).matchExpression.matchToken!(TokenType.Semicolon);
}
/// TryStatement = "try" Statement CatchClause* [FinallyClause]
public ParseResult matchTryStatement(ParseResult input)
{
	return input.matchToken!(TokenType.Try).matchStatement
		.matchUntilFail!matchCatchClause.ignorable!matchFinallyClause;
}
/// CatchClause = "catch" "(" Type [Identifier] ")" Statement
public ParseResult matchCatchClause(ParseResult input)
{
	return input.matchToken!(TokenType.Catch).matchToken!(TokenType.OpenParenthese)
		.matchType.ignorable!(matchToken!(TokenType.Identifier)).matchToken!(TokenType.CloseParenthese)
		.matchStatement;
}
/// FinallyClause = "finally" Statement
public ParseResult matchFinallyClause(ParseResult input)
{
	return input.matchToken!(TokenType.Finally).matchStatement;
}

/// SwitchStatement = "switch" "(" Expression ")" "{" (CaseClause / DefaultClause)* "}"
public ParseResult matchSwitchStatement(ParseResult input)
{
	return input.matchToken!(TokenType.Switch).matchToken!(TokenType.OpenParenthese)
		.matchExpression.matchToken!(TokenType.CloseParenthese).matchToken!(TokenType.OpenBrace)
		.matchUntilFail!(select!(matchCaseClause, matchDefaultClause)).matchToken!(TokenType.CloseBrace);
}
/// CaseClause = ValueCaseClause / TypeMatchingCaseClause
public ParseResult matchCaseClause(ParseResult input)
{
	return input.select!(matchValueCaseClause, matchTypeMatchingCaseClause);
}
/// ValueCaseClause = "case" ExpressionList ":" Statement
public ParseResult matchValueCaseClause(ParseResult input)
{
	return input.matchToken!(TokenType.Case).matchExpressionList.matchToken!(TokenType.Colon)
		.matchStatement;
}
/// TypeMatchingCaseClause = "case" Identifier ":" InferableType ("," Identifier ":" InferableType)* ":" Statement
public ParseResult matchTypeMatchingCaseClause(ParseResult input)
{
	return input.matchToken!(TokenType.Case).matchToken!(TokenType.Identifier).matchToken!(TokenType.Colon)
		.matchInferableType.matchUntilFail!(
			x => x.matchToken!(TokenType.Comma).matchToken!(TokenType.Identifier)
				.matchToken!(TokenType.Colon).matchInferableType
		).matchToken!(TokenType.Colon).matchStatement;
}
/// DefaultClause = "default" ":" Statement
public ParseResult matchDefaultClause(ParseResult input)
{
	return input.matchToken!(TokenType.Default).matchToken!(TokenType.Colon).matchStatement;
}

/*
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
			TokenType.Throw, TokenType.Try, TokenType.Switch]
			.any!(a => a == input.front.type)
			|| Expression.canParse(input);
	}
	public static TokenList drops(TokenList input)
	{
		switch(input.front.type)
		{
		case TokenType.If: return IfStatement.drops(input);
		case TokenType.While: return WhileStatement.drops(input);
		case TokenType.Do: return DoStatement.drops(input);
		case TokenType.For: return ForStatement.drops(input);
		case TokenType.Foreach: return ForeachStatement.drops(input);
		case TokenType.Break:
			if(input.dropOne.front.type == TokenType.Semicolon) return input.drop(2);
			return input.dropOne.thenIf!(a => a.front.type == TokenType.Identifier, dropOne)
				.thenIf!(a => a.front.type == TokenType.Semicolon, dropOne);
		case TokenType.Continue:
			if(input.dropOne.front.type == TokenType.Semicolon) return input.drop(2);
			return input.dropOne.thenIf!(a => a.front.type == TokenType.Identifier, dropOne)
				.thenIf!(a => a.front.type == TokenType.Semicolon, dropOne);
		case TokenType.Return:
			if(input.dropOne.front.type == TokenType.Semicolon) return input.drop(2);
			return Expression.drops(input.dropOne)
				.thenIf!(a => a.front.type == TokenType.Semicolon, dropOne);
		case TokenType.Identifier:
			if(input.dropOne.front.type == TokenType.Colon)
			{
				return NamedStatements.drops(input);
			}
			else goto default;
		case TokenType.Throw:
			return Expression.drops(input.dropOne).thenIf!(a => a.front.type == TokenType.Semicolon, dropOne);
		case TokenType.Try: return TryStatement.drops(input);
		case TokenType.OpenBrace: return StatementBlock.drops(input);
		case TokenType.Semicolon: return input.dropOne;
		default:
			return Expression.drops(input).thenIf!(a => a.front.type == TokenType.Semicolon, dropOne);
		}
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
		default:
			return input.then!(Expression.parse).consumeToken!(TokenType.Semicolon);
		}
	}
}
*/
