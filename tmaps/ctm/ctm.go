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

// Package ctm implements decoding from the CTM format.
package ctm

import (
	"bytes"
	"fmt"
	"io"

	"github.com/google/note-maps/store/pb"
	"github.com/google/note-maps/tmaps"
	"github.com/google/note-maps/tmaps/ctm/internal/lex"
)

type parserState func() parserState

type parser struct {
	lx          *lex.Lexer
	l           *lex.Lexeme
	rewound     bool
	state       parserState
	err         error
	m           tmaps.Merger
	topic       *pb.AnyItem
	association *pb.AnyItem
	prefixes    map[string]string
	ref         pb.Ref
}

// Parse reads CTM from r passing topics and associations into m until EOF.
//
// If parsing reaches EOF, Parse returns nil. Otherwise, Parse returns an error
// explaining why parsing stopped before EOF.
func Parse(r io.Reader, m tmaps.Merger) error {
	parser := parser{
		lx:       lex.NewLexer(r),
		m:        m,
		prefixes: make(map[string]string),
	}
	parser.state = parser.parseProlog
	for parser.state != nil {
		parser.state = parser.state()
	}
	if parser.err == io.EOF {
		return nil
	}
	return parser.err
}

func ParseString(s string, m tmaps.Merger) error {
	return Parse(bytes.NewReader([]byte(s)), m)
}

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

func (p *parser) skipSpace() bool {
	for p.nextLexeme() {
		if p.l.Type != lex.Space {
			break
		}
	}
	return !p.l.Type.Terminal()
}

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

func (p *parser) parseProlog() parserState {
	if !p.skipMultiline() {
		return nil
	} else if !p.l.Match(lex.Delimiter, "%") {
		p.rewind()
		return p.parseBody
	} else if !(p.nextLexeme() && p.l.Type == lex.Name) {
		return p.parseErrorf("expected directive name")
	}
	switch p.l.Value {
	case "encoding":
		return p.parseEncodingDirective
	case "version":
		return p.parseVersionDirective
	default:
		p.rewind()
		return p.parseDirective
	}
}

func (p *parser) parseEncodingDirective() parserState {
	if !(p.skipSpace() && p.l.Type == lex.String) {
		return p.parseErrorf("expected string, got %s", p.l)
	} else if p.l.Value != "\"UTF-8\"" {
		return p.parseErrorf("unsupported encoding")
	} else {
		return p.parseProlog
	}
}

func (p *parser) parseVersionDirective() parserState {
	if !(p.skipMultiline() && p.l.Type == lex.Number) {
		return p.parseErrorf("expected number")
	} else if p.l.Value != "1.0" {
		return p.parseErrorf("only CTM version 1.0 is supported")
	} else {
		return p.parseProlog
	}
}

func (p *parser) parseDirective() parserState {
	if !p.nextLexeme() || p.l.Type != lex.Name {
		return p.parseErrorf("expected directive name")
	}
	switch p.l.Value {
	case "prefix":
		p.skipSpace()
		return p.parsePrefixDirective
	case "include", "mergemap":
		return p.parseErrorf("unimplemented directive %q", p.l.Value)
	default:
		return p.parseErrorf("unrecognized directive %q", p.l.Value)
	}
}

func (p *parser) parsePrefixDirective() parserState {
	if p.l.Type != lex.Name {
		return p.parseErrorf("expected prefix name")
	}
	name := p.l.Value
	if !(p.skipSpace() && p.l.Type == lex.IRI) {
		return p.parseErrorf("expected IRI for prefix %q", name)
	}
	p.prefixes[name] = p.l.Value
	return p.parseBody
}

func (p *parser) parseBody() parserState {
	if !p.skipMultiline() {
		return nil
	} else if p.l.Type != lex.Name {
		return p.parseErrorf("expected word in body")
	} else if p.l.Match(lex.Delimiter, "%") {
		return p.parseDirective
	} else {
		return p.parseTopicOrAssociation
	}
}

func (p *parser) parseTopicOrAssociation() parserState {
	ref := p.readRef()
	if ref.Iri == "" {
		return p.parseErrorf("expected ref")
	}
	if !p.skipMultiline() {
		return p.parseErrorf("%s, expected topic or association", p.l)
	} else if p.l.Match(lex.Delimiter, "(") {
		p.association = &pb.AnyItem{TypeRef: &ref}
		return p.parseAssociation
	} else {
		p.topic = &pb.AnyItem{Refs: []*pb.Ref{&ref}}
		p.rewind()
		return p.parseTopicTail
	}
}

func (p *parser) parseTopicTail() parserState {
	if !p.skipMultiline() {
		return p.parseErrorf("unexpected EOF while parsing topic")
	} else if p.l.Match(lex.Delimiter, "-") {
		return p.parseName
	} else if p.l.Match(lex.Delimiter, ";") {
		return p.parseTopicTail
	} else if p.l.Match(lex.Delimiter, ".") {
		if err := p.m.Merge(p.topic); err != nil {
			return p.parseErrorf("%s: %v: merge error: %s", p.l, p.topic, err)
		}
		p.topic = nil
		return p.parseBody
	}
	p.ref = p.readRef()
	if p.ref.Iri == "" {
		return p.parseErrorf("expected ref while parsing topic")
	}
	p.skipMultiline()
	if p.l.Match(lex.Delimiter, ":") {
		return p.parseOccurrence
	}
	return p.parseErrorf("failed while parsing topic")
}

func (p *parser) parseName() parserState {
	if !p.skipMultiline() {
		return nil
	} else if p.l.Type != lex.String {
		return p.parseErrorf("expected string as name")
	} else {
		p.topic.Names = append(p.topic.Names, &pb.AnyItem{
			TypeRef: &pb.Ref{
				Type: pb.RefType_SubjectIdentifier,
				Iri:  tmaps.TopicNameSI,
			},
			Value: unquote(p.l.Value),
		})
		return p.parseTopicTail
	}
}

func (p *parser) parseOccurrence() parserState {
	typ := p.ref
	o := &pb.AnyItem{TypeRef: &typ}
	p.skipMultiline()
	switch p.l.Type {
	case lex.Name, lex.IRI:
		ref := p.readRef()
		if ref.Iri == "" {
			return p.parseErrorf("expected valid IRI in occurrence value")
		}
		o.Value = ref.Iri
	case lex.String:
		o.Value = unquote(p.l.Value)
	default:
		return p.parseErrorf("unsupported occurrence value type: %v", p.l.Type)
	}
	p.topic.Occurrences = append(p.topic.Occurrences, o)
	return p.parseTopicTail
}

func (p *parser) parseAssociation() parserState {
	p.skipMultiline()
	roleType := p.readRef()
	if roleType.Iri == "" {
		return p.parseErrorf("expected role type ref, got %s", p.l)
	} else if !(p.skipMultiline() && p.l.Match(lex.Delimiter, ":")) {
		return p.parseErrorf("expected colon ':' after role type ref, got %s", p.l)
	}
	p.skipMultiline()
	player := p.readRef()
	if player.Iri == "" {
		return p.parseErrorf("expected player ref")
	}
	p.association.Roles = append(p.association.Roles, &pb.AnyItem{
		TypeRef:   &roleType,
		PlayerRef: &player,
	})
	p.skipMultiline()
	if p.l.Match(lex.Delimiter, ",") {
		return p.parseAssociation
	} else if p.l.Match(lex.Delimiter, ")") {
		p.m.Merge(p.association)
		p.association = nil
		return p.parseBody
	} else {
		return p.parseErrorf("expected comma ',' or parenthesis ')'")
	}
}

func (p *parser) readRef() (ref pb.Ref) {
	switch p.l.Type {
	case lex.IRI:
		ref.Type = pb.RefType_SubjectIdentifier
		ref.Iri = p.l.Value
	case lex.Name:
		base, qname := p.prefixes[p.l.Value]
		if qname {
			if p.nextLexeme() && p.l.Match(lex.Delimiter, ":") {
				if !(p.nextLexeme() && p.l.Type == lex.Name) {
					p.parseErrorf("expected qualified name")
					ref.Iri = ""
				} else {
					ref.Type = pb.RefType_SubjectIdentifier
					ref.Iri = base + p.l.Value
				}
			} else {
				// Ignore that lexeme as it's not part of the IRI after all.
				p.rewind()
				ref.Type = pb.RefType_ItemIdentifier
				ref.Iri = p.l.Value
			}
		} else {
			ref.Type = pb.RefType_ItemIdentifier
			ref.Iri = p.l.Value
		}
	default:
		p.parseErrorf("%s, want ref", p.l)
	}
	return ref
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
