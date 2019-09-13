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
	"regexp"

	"github.com/alecthomas/participle"
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
	Undefined bool    `( @"undef"`
	True      bool    `| @"true"`
	False     bool    `| @"false"`
	Number    float64 `| ( @Int | @Float )`
	//Date
	//DateTime
	IRI string `| @String )`
}

// TMQL [17] item-reference
//
// http://www.isotopicmaps.org/tmql/tmql.html#item-reference
type ItemReference struct {
	QIRI string `"<" @String ">"`
}

// TMQL [20] anchor
//
// http://www.isotopicmaps.org/tmql/tmql.html#anchor
type Anchor struct {
	Constant *Constant `@@`
	//Variable string    `| @Variable )`
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
	ExistsQuantifier  *ExistsQuantifier  `@@`
	BindingSet        *BindingSet        `@@`
	BooleanExpression *BooleanExpression `"satisfies" @@`
}

// TMQL [41] exists-quantifier
//
// http://www.isotopicmaps.org/tmql/tmql.html#exists-quantifier
type ExistsQuantifier struct {
	Some  bool `( @"some"`
	Least int  `| "at" ( "least" @Integer`
	Most  int  `       | "most" @Integer ) )`
}

// TMQL [42] forall-clause
//
// http://www.isotopicmaps.org/tmql/tmql.html#forall-clause
type ForallClause struct {
	BindingSet        *BindingSet        `"every" @@`
	BooleanExpression *BooleanExpression `"satisfies" @@`
}

// TMQL [43] variable
//
// http://www.isotopicmaps.org/tmql/tmql.html#variable
var Variable = regexp.MustCompile(`[$@%][\w#]+'*`)

// TMQL [44] variable-assignment
//
// http://www.isotopicmaps.org/tmql/tmql.html#variable-assignment
type VariableAssignment struct {
	Variable string   `@Variable`
	Content  *Content `"in" @@`
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
	PathExpression *PathExpression
}

// TMQL [53] path-expression
//
// http://www.isotopicmaps.org/tmql/tmql.html#path-expression
type PathExpression struct {
	PostfixedExpression *PostfixedExpression
	//PredicateInvocation *PredicateInvocation
}

// TMQL [54] postfixed-expression
//
// http://www.isotopicmaps.org/tmql/tmql.html#postfixed-expression
type PostfixedExpression struct {
	Simple  *SimpleContent
	Postfix *Postfix
}

// TMQL [55] postfix
//
// http://www.isotopicmaps.org/tmql/tmql.html#postfix
type Postfix struct {
	FilterPostfix *FilterPostfix
	//ProjectionPostfix *ProjectionPostfix
}

// TMQL [56] filter-postfix
//
// http://www.isotopicmaps.org/tmql/tmql.html#filter-postfix
type FilterPostfix struct {
	BooleanPrimitives []*BooleanPrimitive
}

var (
	parser = participle.MustBuild(&SimpleContent{})
)

func Parse(r io.Reader, v interface{}) error    { return parser.Parse(r, v) }
func ParseBytes(b []byte, v interface{}) error  { return parser.ParseBytes(b, v) }
func ParseString(s string, v interface{}) error { return parser.ParseString(s, v) }
