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
	"bytes"
	"fmt"
	"io"
	"log"

	"github.com/google/note-maps/topicmaps/tmql/internal/lex"
)

type parser struct {
	lx      *lex.Lexer
	l       *lex.Lexeme
	rewound bool
	err     error
	q       *Query
}

// Parse reads TMQL from r until EOF.
//
// If parsing reaches EOF, Parse returns nil. Otherwise, Parse returns an error
// explaining why parsing stopped before EOF.
func Parse(r io.Reader, q *Query) error {
	parser := parser{
		lx: lex.NewLexer(r),
	}
	result := parser.readQuery()
	if result != nil {
		*q = *result
	}
	return parser.err
	if parser.err == io.EOF {
		return nil
	}
	return parser.err
}

// Loads the next lexeme and returns true only if a non-terminal lexeme.
func (p *parser) nextLexeme() bool {
	if p.l != nil && p.l.Type.Terminal() {
		return false
	} else if p.rewound {
		p.rewound = false
	} else {
		p.l = p.lx.Lexeme()
	}
	return !p.l.Type.Terminal()
}

// Loads the next lexeme excluding any spaces and returns true only if a
// non-terminal lexeme was found.
func (p *parser) skipSpace() bool {
	for p.nextLexeme() {
		if p.l.Type != lex.Space {
			break
		}
	}
	return !p.l.Type.Terminal()
}

// Loads the next lexeme excluding any spaces, line breaks, or comments, and
// returns true only if a non-terminal lexeme was found.
func (p *parser) skipMultiline() bool {
	for p.nextLexeme() {
		if p.l.Type != lex.Space && p.l.Type != lex.Break && p.l.Type != lex.Comment {
			break
		}
	}
	return !p.l.Type.Terminal()
}

func (p *parser) rewind() {
	if p.rewound {
		panic("cannot rewind twice")
	}
	p.rewound = true
}

func (p *parser) parseErrorf(msg string, args ...interface{}) {
	err := &lex.ErrorInfo{Message: fmt.Sprintf(msg, args...)}
	if p.l != nil {
		err.Start.Line = p.l.Start.Line
		err.Start.Column = p.l.Start.Column
		err.End.Line = p.l.End.Line
		err.End.Column = p.l.End.Column
	}
	p.err = err
}

func (p *parser) readMoreOfQuery(q *Query) bool {
	switch {
	case !p.skipMultiline():
		return false
	case p.l.Match(lex.Delimiter, "%"):
		if !(p.nextLexeme() && p.l.Type == lex.Name) {
			p.parseErrorf("expected identifier, got %s", p.l)
			return false
		}
		switch p.l.Value {
		case "prefix":
			return p.parsePrefixDirective(q)
		case "pragma":
			return p.parsePragmaDirective(q)
		default:
			return false
		}
	default:
		// A full TMQL implementation would also support SELECT expressions and FLWR
		// expressions. This is not a full implementation.
		q.Path = p.readPathExpression()
		return q.Path != nil
	}
}

func (p *parser) parsePrefixDirective(q *Query) bool {
	if p.l.Type != lex.Name {
		p.parseErrorf("expected prefix identifier")
		return false
	}
	name := p.l.Value
	if !(p.skipSpace() && p.l.Type == lex.IRI) {
		p.parseErrorf("expected IRI for prefix %q", name)
		return false
	}
	p.parseErrorf("pragma directive is not yet supported")
	return false
	// TODO: implement TMQL 6.3.1 Directives.
	//p.prefixes[name] = p.l.Value
}

func (p *parser) parsePragmaDirective(q *Query) bool {
	if p.l.Type != lex.Name {
		p.parseErrorf("expected pragma identifier, got %s", p.l)
		return false
	}
	//name := p.l.Value
	if !p.skipSpace() {
		p.parseErrorf("expected QIRI, got %s", p.l)
		return false
	}
	p.readQIRI()
	p.parseErrorf("pragma directive is not yet supported")
	return false
	// TODO: implement TMQL 6.3.2 Pragmas.
}

func (p *parser) parseBody(q *Query) bool {
	// A full TMQL implementation would also support SELECT expressions and FLWR
	// expressions.
	q.Path = p.readPathExpression()
	return q.Path != nil
}

type BooleanPrimitive struct {
	Invert   bool
	Min, Max uint
	Bindings BindingSet
	Satisify *BooleanExpression
}

type BooleanExpression struct {
}

type BindingSet map[string]Content

func (p *parser) readBooleanPrimitive() *BooleanPrimitive {
	p.skipMultiline()
	switch p.l.Type {
	case lex.Name:
		switch p.l.Value {
		case "not":
			negated := p.readBooleanPrimitive()
			negated.Invert = true
			return negated
		case "every":
			p.parseErrorf("'every' is not yet supported")
			// Can be implemented as inverted 'some'.
		case "some":
			p.parseErrorf("'some' is not yet supported")
		case "at":
			p.parseErrorf("'at least' and 'at most' are not supported")
		}
	}
	log.Println("")
	content := p.readContent()
	if content == nil {
		return nil
	}
	return &BooleanPrimitive{
		Min: 1,
		Max: ^uint(0),
		Bindings: BindingSet{
			"$_": content,
		},
		// Satisfy: nil == the default expression i.e. "not null"
	}
	return nil
}

// TMQL [18] step
//
// http://www.isotopicmaps.org/tmql/tmql.html#step
type Step struct {
	Direction StepDirection
	Axis      Axis
	Anchor    Anchor
}

type StepDirection int

const (
	StepForward StepDirection = iota
	StepBackward
)

func (p *parser) readStep() *Step {
	var step Step
	p.skipMultiline()
	switch {
	case p.l.Match(lex.Delimiter, ">>"):
		step.Direction = StepForward
	case p.l.Match(lex.Delimiter, "<<"):
		step.Direction = StepBackward
	default:
		return nil
	}
	p.skipMultiline()
	if p.l.Type == lex.Name {
		var ok bool
		step.Axis, ok = AxisByName(p.l.Value)
		if !ok {
			p.parseErrorf("not a valid navigation axis: %s", p.l)
		}
	} else {
		p.parseErrorf("expected a navigation axis: %s", p.l)
	}
	return nil
}

// TMQL [19] axis
//
// http://www.isotopicmaps.org/tmql/tmql.html#axis
type Axis int

const (
	AxisUnspecified Axis = iota
	AxisTypes
	AxisSupertypes
	AxisPlayers
	AxisRoles
	AxisTraverse
	AxisCharacteristics
	AxisScope
	AxisLocators
	AxisIndicators
	AxisItem
	AxisReifier
	AxisAtomify
)

// String returns the string representation of `a` as it would be expressed in
// TMQL.
func (a Axis) String() string {
	switch a {
	case AxisUnspecified:
		return "unspecifiedaxis"
	case AxisTypes:
		return "types"
	case AxisSupertypes:
		return "supertypes"
	case AxisPlayers:
		return "players"
	case AxisRoles:
		return "roles"
	case AxisTraverse:
		return "traverse"
	case AxisCharacteristics:
		return "characteristics"
	case AxisScope:
		return "scope"
	case AxisLocators:
		return "locators"
	case AxisIndicators:
		return "indicators"
	case AxisItem:
		return "item"
	case AxisReifier:
		return "reifier"
	case AxisAtomify:
		return "atomify"
	default:
		return "unrecognizedaxis"
	}
}

// AxisByName returns the Axis matching name `n`, or false if `n` is not valid.
func AxisByName(n string) (Axis, bool) {
	a, ok := map[string]Axis{
		"types":           AxisTypes,
		"supertypes":      AxisSupertypes,
		"players":         AxisPlayers,
		"roles":           AxisRoles,
		"traverse":        AxisTraverse,
		"characteristics": AxisCharacteristics,
		"scope":           AxisScope,
		"locators":        AxisLocators,
		"indicators":      AxisIndicators,
		"item":            AxisItem,
		"reifier":         AxisReifier,
		"atomify":         AxisAtomify,
	}[n]
	return a, ok
}

// TMQL [20] anchor
//
// http://www.isotopicmaps.org/tmql/tmql.html#anchor
type Anchor struct {
	Variable string
	Atom     string
	QIRI     string
}

func (p *parser) readAnchor() *Anchor {
	p.skipMultiline()
	if p.l.Type == lex.Delimiter {
		switch p.l.Value {
		case "$", "@", "%":
			prefix := p.l.Value
			p.nextLexeme()
			if p.l.Type != lex.Name {
				p.parseErrorf("expected variable name, got %s", p.l)
			}
			return &Anchor{Variable: prefix + p.l.Value}
		case ".":
			return &Anchor{Variable: "$0"}
		}
	}
	p.parseErrorf("expected anchor, got %s", p.l)
	return nil
}

// TMQL [21] simple-content
//
// http://www.isotopicmaps.org/tmql/tmql.html#simple-content
type SimpleContent struct {
	Anchor     *Anchor
	Navigation []*Step
}

func (p *parser) readSimpleContent() *SimpleContent {
	var sc SimpleContent
	sc.Anchor = p.readAnchor()
	if sc.Anchor == nil {
		return nil
	}
	for {
		step := p.readStep()
		if p.err != nil {
			return nil
		} else if step != nil {
			sc.Navigation = append(sc.Navigation, step)
		} else {
			break
		}
	}
	if p.err != nil {
		return nil
	}
	return &sc
}

// TMQL [23] content
//
// http://www.isotopicmaps.org/tmql/tmql.html#content
type Content interface{}
type ContentInfix struct {
	L, R Content
	Op   InfixOperator
}

type InfixOperator string

const (
	InfixUnion        InfixOperator = "++"
	InfixDifference   InfixOperator = "--"
	InfixIntersection InfixOperator = "=="
)

func (p *parser) readContent() Content {
	switch p.l.Type {
	case lex.Delimiter:
		switch p.l.Value {
		case "{":
			p.parseErrorf("sub-query content with '{ ... }' is not yet supported")
			return nil
		}
	case lex.Name:
		switch p.l.Value {
		case "if":
			p.parseErrorf("conditional content with 'if' is not yet supported")
			return nil
		}
	}
	path := p.readPathExpression()
	if path == nil {
		return nil
	}
	p.skipMultiline()
	var op InfixOperator
	switch {
	case p.l.Match(lex.Delimiter, "++"):
		op = InfixUnion
	case p.l.Match(lex.Delimiter, "--"):
		op = InfixDifference
	case p.l.Match(lex.Delimiter, "=="):
		op = InfixIntersection
	}
	if op != "" {
		c := &ContentInfix{L: path, Op: op, R: p.readPathExpression()}
		if c.R == nil {
			return nil
		}
		return c
	}
	return path
}

// TMQL [46] query-expression
//
// http://www.isotopicmaps.org/tmql/tmql.html#query-expression
type Query struct {
	// environment-clause
	// select OR flwr OR path
	Path *PathExpression
}

func (p *parser) readQuery() *Query {
	var q Query
	for p.readMoreOfQuery(&q) {
	}
	if p.err != nil {
		return nil
	}
	return &q
}

// TMQL [53] path-expression
//
// http://www.isotopicmaps.org/tmql/tmql.html#path-expression
type PathExpression struct {
	Simple  *SimpleContent
	Postfix []*Postfix
}

func (p *parser) readPathExpression() *PathExpression {
	var path PathExpression
	path.Simple = p.readSimpleContent()
	if path.Simple == nil && p.err != nil {
		return nil
	}
	for p.readMorePathExpression(&path) {
	}
	if p.err != nil {
		return nil
	}
	return &path
}

func (p *parser) readMorePathExpression(path *PathExpression) bool {
	switch p.l.Type {
	case lex.Delimiter:
		switch p.l.Value {
		case "[":
			boolean := p.readBooleanPrimitive()
			if p.err != nil {
				return false
			}
			p.skipMultiline()
			if p.l.Type != lex.Delimiter && p.l.Value != "]" {
				p.parseErrorf("expected ']', got %s", p.l)
				return false
			}
			path.Postfix = append(path.Postfix, &Postfix{Filter: boolean})
			return true
		}
	}
	return false
}

// TMQL [55] postfix
//
// http://www.isotopicmaps.org/tmql/tmql.html#postfix
type Postfix struct {
	// TMQL [56] filter-postfix
	//
	// http://www.isotopicmaps.org/tmql/tmql.html#filter-postfix
	Filter *BooleanPrimitive

	// TMQL [57] projection-postfix is not supported yet.
	//
	// http://www.isotopicmaps.org/tmql/tmql.html#projection-postfix
}

func (p *parser) readQIRI() string {
	switch p.l.Type {
	case lex.IRI:
		return p.l.Value
	case lex.Name:
		//base, qname := p.q.Prefixes[p.l.Value]
		base, qname := "", false // TODO
		if qname {
			if p.nextLexeme() && p.l.Match(lex.Delimiter, ":") {
				if !(p.nextLexeme() && p.l.Type == lex.Name) {
					p.parseErrorf("expected qualified name")
					return ""
				} else {
					return base + p.l.Value
				}
			} else {
				// Ignore that lexeme as it's not part of the IRI after all.
				p.rewind()
				return p.l.Value
			}
		} else {
			return p.l.Value
		}
	default:
		p.parseErrorf("expected IRI, found %s", p.l)
	}
	return ""
}

func unquote(s string) string {
	var (
		b   = bytes.NewBuffer(nil)
		q   rune
		esc bool
	)
	for i, r := range s {
		switch {
		case i == 0:
			q = r
		case esc:
			b.WriteRune(r)
		case r == q:
			break
		case r == '\\':
			esc = true
			continue
		default:
			b.WriteRune(r)
		}
	}
	return b.String()
}
