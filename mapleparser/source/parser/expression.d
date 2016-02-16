module mlfe.mapleparser.parser.expression;

import mlfe.mapleparser.parser.base;
import mlfe.mapleparser.parser.symbol;
import mlfe.mapleparser.parser.type;
import mlfe.mapleparser.parser.statement;
import mlfe.mapleparser.parser.exceptions;
import mlfe.mapleparser.lexer.token;
import std.algorithm, std.range;

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
	assert(Cont("x = match(a) { case 0, 2 => true; default => false; }".asTokenList).matchExpression.succeeded);
	assert(Cont("x = match(a) { case 0, 2 => true; default => false }".asTokenList).matchExpression.succeeded);
	assert(Cont("fun = x => x + 2".asTokenList).matchExpression.succeeded);
	assert(Cont("fun2 = (x, y) { val a = x + y; }".asTokenList).matchExpression.succeeded);
	assert(Cont("v = ((x, y) => x * y)(2, 3)".asTokenList).matchExpression.succeeded);
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
/// PrimaryExpression = "(" Expression ")" / "[" [ExpressionList] "]" / NewExpression / MatchExpression
///		/ LambdaExpression / TemplateInstance / "." TemplateInstance / "global" "." TemplateInstance"
///		/ Literal / SpecialLiteral
public ParseResult matchPrimaryExpression(ParseResult input)
{
	return input.select!(
		x => x.matchToken!(TokenType.OpenParenthese).matchExpression.matchToken!(TokenType.CloseParenthese),
		x => x.matchToken!(TokenType.OpenBracket).ignorable!matchExpressionList.matchToken!(TokenType.CloseBracket),
		x => x.matchNewExpression,
		x => x.matchMatchExpression,
		x => x.matchLambdaExpression,
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
/// LambdaExpression = SingleLambdaExpression / MultipleLambdaExpression / ClosureExpression
public ParseResult matchLambdaExpression(ParseResult input)
{
	return input.select!(
		matchSingleLambdaExpression, matchMultipleLambdaExpression,
		matchClosureExpression
	);
}
/// SingleLambdaExpression = Identifier "=>" Expression
public ParseResult matchSingleLambdaExpression(ParseResult input)
{
	return input.matchToken!(TokenType.Identifier).matchToken!(TokenType.Equal_RightAngleBracket).matchExpression;
}
/// MultipleLambdaExpression = "(" [Identifier ("," Identifier)*] ")" "=>" Expression
public ParseResult matchMultipleLambdaExpression(ParseResult input)
{
	return input.matchToken!(TokenType.OpenParenthese)
		.ignorable!(x => x.matchToken!(TokenType.Identifier).matchUntilFail!(
			x => x.matchToken!(TokenType.Comma).matchToken!(TokenType.Identifier)
		))
		.matchToken!(TokenType.CloseParenthese)
		.matchToken!(TokenType.Equal_RightAngleBracket).matchExpression;
}
/// ClosureExpression = "(" [Identifier ("," Identifier)*] ")" StatementBlock
public ParseResult matchClosureExpression(ParseResult input)
{
	return input.matchToken!(TokenType.OpenParenthese)
		.ignorable!(x => x.matchToken!(TokenType.Identifier).matchUntilFail!(
			x => x.matchToken!(TokenType.Comma).matchToken!(TokenType.Identifier)
		))
		.matchToken!(TokenType.CloseParenthese)
		.matchStatementBlock;
}
/// MatchExpression = "match" "(" Expression ")" "{" (CaseClause | DefaultClause)* "}"
public ParseResult matchMatchExpression(ParseResult input)
{
	return input.matchToken!(TokenType.Match)
		.matchToken!(TokenType.OpenParenthese).matchExpression.matchToken!(TokenType.CloseParenthese)
		.matchToken!(TokenType.OpenBrace)
		.matchUntilFail!(select!(matchCaseClause, matchDefaultClause))
		.matchToken!(TokenType.CloseBrace);
}
/// DefaultClause = "default" "=>" Statement
public ParseResult matchDefaultClause(ParseResult input)
{
	return input.matchToken!(TokenType.Default).matchToken!(TokenType.Equal_RightAngleBracket).matchStatement;
}
/// CaseClause = ValueCaseClause | TypeMatchingCaseClause
public ParseResult matchCaseClause(ParseResult input)
{
	return input.select!(matchValueCaseClause, matchTypeMatchingCaseClause);
}
/// ValueCaseClause = "case" ExpressionList "=>" Statement
public ParseResult matchValueCaseClause(ParseResult input)
{
	return input.matchToken!(TokenType.Case).matchExpressionList
		.matchToken!(TokenType.Equal_RightAngleBracket).matchStatement;
}
/// TypeMatchingCaseClause = "case" Identifier ":" Type ("," Identifier ":" Type)* "=>" Statement
public ParseResult matchTypeMatchingCaseClause(ParseResult input)
{
	return input.matchToken!(TokenType.Case).matchToken!(TokenType.Identifier)
		.matchToken!(TokenType.Colon).matchType.matchUntilFail!(
			x => x.matchToken!(TokenType.Comma).matchToken!(TokenType.Identifier)
				.matchToken!(TokenType.Colon).matchType
		)
		.matchToken!(TokenType.Equal_RightAngleBracket).matchStatement;
}
