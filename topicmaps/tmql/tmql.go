// Copyright 2019 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Package tmql implements decoding TMQL queries.
package tmql

import (
	"io"

	"github.com/alecthomas/participle"
	"github.com/alecthomas/participle/lexer"
	"github.com/alecthomas/participle/lexer/ebnf"
)

// TMQL [1] constant
//
// http://www.isotopicmaps.org/tmql/tmql.html#constant
type Constant struct {
	Atom          *Atom          `( @@`
	ItemReference *ItemReference `| @@ )`
}

// TMQL [2] atom
//
// http://www.isotopicmaps.org/tmql/tmql.html#atom
type Atom struct {
	Keyword Keyword `( @"undef" | @"true" | @"false" )`
	Number  int     `| @Int`
	String  string  `| @String`
	//Date
	//DateTime
}

type Keyword string

func (k *Keyword) Capture(s []string) error {
	*k = Keyword(s[0])
	return nil
}

const (
	UndefKeyword Keyword = "undef"
	TrueKeyword  Keyword = "true"
	FalseKeyword Keyword = "false"
)

// TMQL [14] QName
//
// http://www.isotopicmaps.org/tmql/tmql.html#QName
type QName struct {
	Prefix     string `@Prefix`
	Identifier string `@Identifier`
}

// TMQL [17] item-reference
//
// http://www.isotopicmaps.org/tmql/tmql.html#item-reference
type ItemReference struct {
	Identifier string `( @Identifier`
	QIRI       string `| @QIRI )`
}

// TMQL [20] anchor
//
// http://www.isotopicmaps.org/tmql/tmql.html#anchor
type Anchor struct {
	Constant *Constant `( @@`
	Variable string    `| @Variable | @"." )`
}

// TMQL [21] simple-content
//
// http://www.isotopicmaps.org/tmql/tmql.html#simple-content
type SimpleContent struct {
	Anchor *Anchor `@@`
	//Navigation []*Step `@@`
}

// TMQL [23] content
//
// http://www.isotopicmaps.org/tmql/tmql.html#content
type Content struct {
	QueryExpression *QueryExpression `( "{" @@ "}"`
	PathExpression  *PathExpression  `| @@ )`
}
type OpContent struct {
	ContentInfixOperator string   `( @"++" | @"--" | @"==" )`
	Content              *Content `@@`
}
type CompositeContent struct {
	Content   *Content   `@@`
	OpContent *OpContent `@@*`
}

// TMQL [38] boolean-expression
//
// http://www.isotopicmaps.org/tmql/tmql.html#boolean-expression
type BooleanExpression struct {
	BooleanPrimitive *BooleanPrimitive `@@`
}

// TMQL [39] boolean-primitive
//
// http://www.isotopicmaps.org/tmql/tmql.html#boolean-primitive
type BooleanPrimitive struct {
	Negated      *BooleanPrimitive `( "not" @@`
	ForallClause *ForallClause     `| @@`
	ExistsClause *ExistsClause     `| @@ )`
}

// TMQL [40] exists-clause
//
// http://www.isotopicmaps.org/tmql/tmql.html#exists-clause
type ExistsClause struct {
	ExistsQuantifier  *ExistsQuantifier  `( @@`
	BindingSet        *BindingSet        `  @@`
	BooleanExpression *BooleanExpression `  "satisfies" @@ )`
	ExistsContent     *CompositeContent  `| "exists"? @@`
}

// TMQL [41] exists-quantifier
//
// http://www.isotopicmaps.org/tmql/tmql.html#exists-quantifier
type ExistsQuantifier struct {
	Some  bool `( @"some"`
	Least int  `| "at" ( "least" @Int`
	Most  int  `       | "most" @Int ))`
}

// TMQL [42] forall-clause
//
// http://www.isotopicmaps.org/tmql/tmql.html#forall-clause
type ForallClause struct {
	BindingSet        *BindingSet        `"every" @@`
	BooleanExpression *BooleanExpression `"satisfies" @@`
}

// TMQL [44] variable-assignment
//
// http://www.isotopicmaps.org/tmql/tmql.html#variable-assignment
type VariableAssignment struct {
	Variable         string            `@Variable`
	CompositeContent *CompositeContent `"in" @@`
}

// TMQL [45] binding-set
//
// http://www.isotopicmaps.org/tmql/tmql.html#binding-set
type BindingSet struct {
	VariableAssignments []*VariableAssignment `@@ ( "," @@ )*`
}

// TMQL [46] query-expression
//
// http://www.isotopicmaps.org/tmql/tmql.html#query-expression
type QueryExpression struct {
	PathExpression *PathExpression `@@`
}

// TMQL [53] path-expression
//
// http://www.isotopicmaps.org/tmql/tmql.html#path-expression
type PathExpression struct {
	PostfixedExpression *PostfixedExpression `@@`
	//PredicateInvocation *PredicateInvocation
}

// TMQL [54] postfixed-expression
//
// http://www.isotopicmaps.org/tmql/tmql.html#postfixed-expression
type PostfixedExpression struct {
	SimpleContent *SimpleContent `@@`
	Postfix       []*Postfix     `@@*`
}

// TMQL [55] postfix
//
// http://www.isotopicmaps.org/tmql/tmql.html#postfix
type Postfix struct {
	// TMQL [56] filter-postfix
	//
	// http://www.isotopicmaps.org/tmql/tmql.html#filter-postfix
	FilterPostfix *BooleanPrimitive `"[" @@ "]"`

	//ProjectionPostfix *TupleExpression
}

var (
	tmqlLexer = lexer.Must(ebnf.New(`
		Whitespace = " " | "\t" | "\n" | "\r" .
		Variable = ( "$" | "@" | "%" ) ( alpha | digit | "#" | "_" )
		           { alpha | digit | "#" } { "'" } .
		Prefix = word { word } ":" .
    Identifier = word { word } .
		QIRI = "<" iri { iri } ">" .

		Int = digit { digit } .
		String = "\"" { "\u0000"…"\uffff"-"\"" } "\"" .
		Delim = delim { delim } .

		iri = "\u0021"…"\uffff"-"^"-"<"-">"-"'"-"{"-"}"-"|"-"^" .
		alpha = "a"…"z" | "A"…"Z" .
		digit = "0"…"9" .
		word = alpha | digit | "_" .
		delim = "@" | "$" | "%" | "^" | "&" | "|" | "*" | "-" | "+" | "=" | "(" |
		        ")" | "{" | "}" | "[" | "]" | "\"" | "'" | "/" | "\\" | "<" | ">" |
		        ":" | "." | "," | "~" .
  `))
	parser = participle.MustBuild(&QueryExpression{},
		participle.Lexer(tmqlLexer),
		participle.Elide("Whitespace"),
	)
)

func Parse(r io.Reader, v interface{}) error    { return parser.Parse(r, v) }
func ParseBytes(b []byte, v interface{}) error  { return parser.ParseBytes(b, v) }
func ParseString(s string, v interface{}) error { return parser.ParseString(s, v) }
