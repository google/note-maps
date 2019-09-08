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

	"github.com/google/note-maps/topicmaps/tmql/internal/lex"
)

type parserState func() parserState

type parser struct {
	lx      *lex.Lexer
	l       *lex.Lexeme
	rewound bool
	state   parserState
	err     error
	q       *Query
}

type Query struct{}

// Parse reads TMQL from r until EOF.
//
// If parsing reaches EOF, Parse returns nil. Otherwise, Parse returns an error
// explaining why parsing stopped before EOF.
func Parse(r io.Reader, q *Query) error {
	parser := parser{
		lx: lex.NewLexer(r),
		q:  q,
	}
	parser.state = parser.parseEnvironmentClause
	for parser.state != nil {
		parser.state = parser.state()
	}
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

func (p *parser) parseErrorf(msg string, args ...interface{}) parserState {
	err := &lex.ErrorInfo{Message: fmt.Sprintf(msg, args...)}
	if p.l != nil {
		err.Start.Line = p.l.Start.Line
		err.Start.Column = p.l.Start.Column
		err.End.Line = p.l.End.Line
		err.End.Column = p.l.End.Column
	}
	p.err = err
	return nil
}

func (p *parser) parseEnvironmentClause() parserState {
	if !p.skipMultiline() {
		return nil
	} else if !p.l.Match(lex.Delimiter, "%") {
		p.rewind()
		return p.parseBody
	} else if !(p.nextLexeme() && p.l.Type == lex.Name) {
		return p.parseErrorf("expected identifier, got %s", p.l)
	}
	switch p.l.Value {
	case "prefix":
		return p.parsePrefixDirective
	case "pragma":
		return p.parsePragmaDirective
	default:
		return p.parseErrorf("expected 'prefix' or 'pragma', got %s", p.l.Value)
	}
}

func (p *parser) parsePrefixDirective() parserState {
	if p.l.Type != lex.Name {
		return p.parseErrorf("expected prefix identifier")
	}
	name := p.l.Value
	if !(p.skipSpace() && p.l.Type == lex.IRI) {
		return p.parseErrorf("expected IRI for prefix %q", name)
	}
	return p.parseErrorf("pragma directive is not yet supported")
	// TODO: implement TMQL 6.3.1 Directives.
	//p.prefixes[name] = p.l.Value
}

func (p *parser) parsePragmaDirective() parserState {
	if p.l.Type != lex.Name {
		return p.parseErrorf("expected pragma identifier, got %s", p.l)
	}
	//name := p.l.Value
	if !p.skipSpace() {
		return p.parseErrorf("expected QIRI, got %s", p.l)
	}
	_, parseErr := p.readQIRI()
	if parseErr != nil {
		return parseErr
	}
	return p.parseErrorf("pragma directive is not yet supported")
	// TODO: implement TMQL 6.3.2 Pragmas.
}

func (p *parser) parseBody() parserState {
	// A full TMQL implementation would also support SELECT expressions and FLWR expressions.
	return p.parsePathExpression()
}

func (p *parser) parsePathExpression() parserState {
	return p.parseErrorf("path expressions are not yet supported")
}

func (p *parser) readQIRI() (iri string, parseErr parserState) {
	switch p.l.Type {
	case lex.IRI:
		iri = p.l.Value
		return
	case lex.Name:
		//base, qname := p.q.Prefixes[p.l.Value]
		base, qname := "", false // TODO
		if qname {
			if p.nextLexeme() && p.l.Match(lex.Delimiter, ":") {
				if !(p.nextLexeme() && p.l.Type == lex.Name) {
					parseErr = p.parseErrorf("expected qualified name")
					return
				} else {
					iri = base + p.l.Value
					return
				}
			} else {
				// Ignore that lexeme as it's not part of the IRI after all.
				p.rewind()
				iri = p.l.Value
				return
			}
		} else {
			iri = p.l.Value
			return
		}
	default:
		parseErr = p.parseErrorf("expected IRI, found %s", p.l)
	}
	return
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
