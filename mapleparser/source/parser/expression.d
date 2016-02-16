module mlfe.mapleparser.parser.expression;

import mlfe.mapleparser.parser.base;
import mlfe.mapleparser.parser.symbol;
import mlfe.mapleparser.parser.type;
import mlfe.mapleparser.parser.statement;
import mlfe.mapleparser.parser.exceptions;
import mlfe.mapleparser.lexer.token;
import std.algorithm, std.range;
/*
/// Expression = TriExpression [AssignOps Expression]
public static class Expression
{
	public static immutable canParse = TriExpression.canParse;
	public static TokenList drops(TokenList input)
	{
		return TriExpression.drops(input)
			.thenIf!(a => AssignOps.canParse(a), a => Expression.drops(AssignOps.drops(a)));
	}
	public static TokenList parse(TokenList input)
	{
		auto in2_tx = TriExpression.parse(input);
		if(AssignOps.canParse(in2_tx))
		{
			return in2_tx.then!(AssignOps.parse).then!(Expression.parse);
		}
		else return in2_tx;
	}
}
*/

/// ExpressionList = Expression ("," Expression)*
public ParseResult matchExpressionList(ParseResult input)
{
	return input.matchExpression
		.matchUntilFail!(x => x.matchToken!(TokenType.Comma).matchExpression);
}
/// Expression = PostfixExpression AssignOps Expression / TriExpression
public ParseResult matchExpression(ParseResult input)
{
	return input.select!(
		x => x.matchPostfixExpression.matchAssignOps.matchExpression,
		matchTriExpression
	);
}
unittest
{
	import mlfe.mapleparser.lexer : asTokenList;
	assert(Cont("123456".asTokenList).matchExpression.succeeded);
	assert(Cont("this".asTokenList).matchExpression.succeeded);
	assert(Cont("[]".asTokenList).matchExpression.succeeded);
	assert(Cont("[2, 3, 6]".asTokenList).matchExpression.succeeded);
	assert(Cont("new TypeTrait#float()".asTokenList).matchExpression.succeeded);
	assert(Cont("++x.counter".asTokenList).matchExpression.succeeded);
	assert(Cont("-+x.counter--**.getValue()".asTokenList).matchExpression.succeeded);
	assert(Cont("data.element->double".asTokenList).matchExpression.succeeded);
	assert(Cont("2 + 3".asTokenList).matchExpression.succeeded);
	assert(Cont("x = 3.4f * vec.length".asTokenList).matchExpression.succeeded);
}

/// AssignOps(Set of tokens) = "=" | "+=" | "-=" | "*=" | "/=" | "%="
///			| "&=" | "|=" | "^=" | ">>=" | "<<="
public ParseResult matchAssignOps(ParseResult input)
{
	return input.selectByType!(
		TokenType.Equal, x => Cont(x.dropOne),
		TokenType.Plus_Equal, x => Cont(x.dropOne),
		TokenType.Minus_Equal, x => Cont(x.dropOne),
		TokenType.Asterisk_Equal, x => Cont(x.dropOne),
		TokenType.Slash_Equal, x => Cont(x.dropOne),
		TokenType.Percent_Equal, x => Cont(x.dropOne),
		TokenType.Ampasand_Equal, x => Cont(x.dropOne),
		TokenType.VerticalLine_Equal, x => Cont(x.dropOne),
		TokenType.Accent_Equal, x => Cont(x.dropOne),
		TokenType.RightAngleBracket2_Equal, x => Cont(x.dropOne),
		TokenType.LeftAngleBracket2_Equal, x => Cont(x.dropOne)
	);
}

/// TriExpression = LogicalExpression ["?" TriExpression ":" TriExpression]
public ParseResult matchTriExpression(ParseResult input)
{
	return input.matchLogicalExpression.ignorable!(
		x => x.matchToken!(TokenType.Hatena).matchTriExpression
			.matchToken!(TokenType.Colon).matchTriExpression
	);
}
/// Template method of Binary operator expression parsing
/// Generates: BinaryExpression = ContainedRule (Operator ContainedRule / ...)*
public ParseResult matchBinaryExpression(alias ContainedRule, Operators...)(ParseResult input)
{
	import std.meta : staticMap;
	template PartialParseFunc(TokenType Operator)
	{
		ParseResult PartialParseFunc(ParseResult x) { return ContainedRule(x.matchToken!Operator); }
	}
	
	return ContainedRule(input).matchUntilFail!(select!(
		staticMap!(PartialParseFunc, Operators)
	));
}
/// LogicalExpression = ComparisonExpression ("&&" ComparisonExpression / "||" ComparisonExpression)*
alias matchLogicalExpression = matchBinaryExpression!(matchComparisonExpression,
	TokenType.Ampasand2, TokenType.VerticalLine2);
/// ComparisonExpression = ShiftExpression ("==" ShiftExpression / "!=" ShiftExpression
///		/ "<" ShiftExpression / ">" ShiftExpression / "<=" ShiftExpression / ">=" ShiftExpression)*
alias matchComparisonExpression = matchBinaryExpression!(matchShiftExpression,
	TokenType.Equal2, TokenType.Exclamation_Equal, TokenType.LeftAngleBracket, TokenType.RightAngleBracket,
	TokenType.LeftAngleBracket_Equal, TokenType.RightAngleBracket_Equal);
/// ShiftExpression = BitExpression ("<<" BitExpression / ">>" BitExpression)*
alias matchShiftExpression = matchBinaryExpression!(matchBitExpression,
	TokenType.LeftAngleBracket2, TokenType.RightAngleBracket2);
/// BitExpression = AddExpression ("&" AddExpression / "|" AddExpression / "^" AddExpression)*
alias matchBitExpression = matchBinaryExpression!(matchAddExpression,
	TokenType.Ampasand, TokenType.VerticalLine, TokenType.Accent);
/// AddExpression = MultiExpression ("+" MultiExpression / "-" MultiExpression)*
alias matchAddExpression = matchBinaryExpression!(matchMultiExpression, TokenType.Plus, TokenType.Minus);
/// MultiExpression = PrefixExpression ("*" PrefixExpression / "/" PrefixExpression / "%" PrefixExpression)*
alias matchMultiExpression = matchBinaryExpression!(matchPrefixExpression,
	TokenType.Asterisk, TokenType.Slash, TokenType.Percent);

/// PrefixExpression = "++" PrefixExpression / "--" PrefixExpression / "**" PrefixExpression
///		/ "+" PrefixExpression / "-" PrefixExpression / PostfixExpression
public ParseResult matchPrefixExpression(ParseResult input)
{
	return input.select!(
		x => x.matchToken!(TokenType.Plus2).matchPrefixExpression,
		x => x.matchToken!(TokenType.Minus2).matchPrefixExpression,
		x => x.matchToken!(TokenType.Asterisk2).matchPrefixExpression,
		x => x.matchToken!(TokenType.Plus).matchPrefixExpression,
		x => x.matchToken!(TokenType.Minus).matchPrefixExpression,
		matchPostfixExpression
	);
}
/// PostfixExpression = PrimaryExpression ("++" / "--" / "**"
///		/ "(" [ExpressionList] ")" / "[" Expression "]" / "." TemplateInstance
///		/ "->" Type)*
public ParseResult matchPostfixExpression(ParseResult input)
{
	return input.matchPrimaryExpression.matchUntilFail!(select!(
		matchToken!(TokenType.Plus2),
		matchToken!(TokenType.Minus2),
		matchToken!(TokenType.Asterisk2),
		x => x.matchToken!(TokenType.OpenParenthese).ignorable!matchExpressionList.matchToken!(TokenType.CloseParenthese),
		x => x.matchToken!(TokenType.OpenBracket).matchExpression.matchToken!(TokenType.CloseBracket),
		x => x.matchToken!(TokenType.Period).matchTemplateInstance,
		x => x.matchToken!(TokenType.Minus_RightAngleBracket).matchType
	));
}
/// PrimaryExpression = "(" Expression ")" / "[" [ExpressionList] "]" / NewExpression
///		/ TemplateInstance / "." TemplateInstance / "global" "." TemplateInstance" / Literal / SpecialLiteral
public ParseResult matchPrimaryExpression(ParseResult input)
{
	return input.select!(
		x => x.matchToken!(TokenType.OpenParenthese).matchExpression.matchToken!(TokenType.CloseParenthese),
		x => x.matchToken!(TokenType.OpenBracket).ignorable!matchExpressionList.matchToken!(TokenType.CloseBracket),
		x => x.matchNewExpression,
		x => x.matchTemplateInstance,
		x => x.matchToken!(TokenType.Period).matchTemplateInstance,
		x => x.matchToken!(TokenType.Global).matchToken!(TokenType.Period).matchTemplateInstance,
		x => x.matchLiteral,
		x => x.matchSpecialLiteral
	);
}

/// Literal(Set of Tokens) = [NumericLiteral] | [FloatLiteral] | [DoubleLiteral] | [StringLiteral] | [CharacterLiteral]
///			| [LongLiteral] | [UlongLiteral]
public ParseResult matchLiteral(ParseResult input)
{
	return input.selectByType!(
		TokenType.NumericLiteral, x => Cont(x.dropOne),
		TokenType.FloatLiteral, x => Cont(x.dropOne),
		TokenType.DoubleLiteral, x => Cont(x.dropOne),
		TokenType.StringLiteral, x => Cont(x.dropOne),
		TokenType.CharacterLiteral, x => Cont(x.dropOne),
		TokenType.LongLiteral, x => Cont(x.dropOne),
		TokenType.UlongLiteral, x => Cont(x.dropOne)
	);
}
/// SpecialLiteral = "this" | "super" | "true" | "false"
public ParseResult matchSpecialLiteral(ParseResult input)
{
	return input.selectByType!(
		TokenType.This, x => Cont(x.dropOne),
		TokenType.Super, x => Cont(x.dropOne),
		TokenType.True, x => Cont(x.dropOne),
		TokenType.False, x => Cont(x.dropOne)
	);
}

/// NewExpression = "new" Type ("[" [Expression] "]")* ["(" [ExpressionList] ")"]
public ParseResult matchNewExpression(ParseResult input)
{
	return input.matchToken!(TokenType.New).matchType
		.matchUntilFail!(x => x.matchToken!(TokenType.OpenBracket)
			.ignorable!matchExpression.matchToken!(TokenType.CloseBracket))
		.ignorable!(x => x.matchToken!(TokenType.OpenParenthese)
			.ignorable!matchExpressionList.matchToken!(TokenType.CloseParenthese));
}

/*
/// SwitchExpression = "switch" "(" Expression ")" "{" (CaseClause | DefaultClause)* "}"
public static class SwitchExpression
{
	public static bool canParse(TokenList input)
	{
		return input.front.type == TokenType.Switch;
	}
	public static TokenList drops(TokenList input)
	{
		if(input.front.type != TokenType.Switch) return input;
		if(input.dropOne.front.type != TokenType.OpenParenthese) return input;
		auto ine = Expression.drops(input.drop(2));
		if(ine.front.type != TokenType.CloseParenthese) return input;
		if(ine.dropOne.front.type != TokenType.OpenBrace) return input;
		auto in3 = ine.drop(2)
			.thenLoop!(a => CaseClause.canParse(a) || DefaultClause.canParse(a), (a)
			{
				return CaseClause.canParse(a) ? CaseClause.drops(a) : DefaultClause.drops(a);
			});
		if(in3.front.type != TokenType.CloseBrace) return input;
		return in3.dropOne;
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
	public static TokenList drops(TokenList input)
	{
		if(input.front.type != TokenType.Default) return input;
		if(input.dropOne.front.type != TokenType.Equal_RightAngleBracket) return input;
		return Statement.drops(input.drop(2));
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
	public static TokenList drops(TokenList input)
	{
		if(input.take(3).map!(a => a.type).equal([TokenType.Case, TokenType.Identifier, TokenType.Colon]))
		{
			return TypeMatchingCaseClause.drops(input);
		}
		else return ValueCaseClause.drops(input);
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
	public static TokenList drops(TokenList input)
	{
		if(input.front.type != TokenType.Case) return input;
		auto in2 = ExpressionList.drops(input.dropOne);
		if(in2.front.type != TokenType.Equal_RightAngleBracket) return input;
		return Statement.drops(in2.dropOne);
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
	public static TokenList drops(TokenList input)
	{
		if(input.front.type != TokenType.Case) return input;
		if(input.dropOne.front.type != TokenType.Identifier) return input;
		if(input.drop(2).front.type != TokenType.Colon) return input;
		auto in2 = Type.drops(input.drop(3))
			.thenLoop!(a => a.front.type == TokenType.Comma, (a)
			{
				if(a.dropOne.front.type != TokenType.Identifier) return a;
				if(a.drop(2).front.type != TokenType.Colon) return a;
				return Type.drops(a.drop(3));
			});
		if(in2.front.type != TokenType.Equal_RightAngleBracket) return input;
		return Statement.drops(in2.dropOne);
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
*/
