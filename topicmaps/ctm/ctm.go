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
	"log"

	"github.com/google/note-maps/topicmaps"
	"github.com/google/note-maps/topicmaps/ctm/internal/lex"
)

type parserState func() parserState

type parser struct {
	lx      *lex.Lexer
	l       *lex.Lexeme
	rewound bool
	state   parserState
	err     error
	m       topicmaps.Merger
	topic   *topicmaps.Topic
	//association *topicmaps.Association
}

// Parse reads CTM from r passing topics and associations into m until EOF.
//
// If parsing reaches EOF, Parse returns nil. Otherwise, Parse returns an error
// explaining why parsing stopped before EOF.
func Parse(r io.Reader, m topicmaps.Merger) error {
	parser := parser{
		lx: lex.NewLexer(r),
		m:  m,
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

// skipLexemes skips past the given lexeme types and returns true if there is
// still something left to read.
func (p *parser) skipLexemes(skips ...lex.Type) bool {
Skipping:
	for p.nextLexeme() {
		for _, t := range skips {
			if t == p.l.Type {
				log.Println("skipping", p.l)
				continue Skipping
			}
		}
		break
	}
	log.Println("stopped skipping", p.l)
	return !p.l.Type.Terminal()
}

func (p *parser) rewind() {
	if p.rewound {
		panic("cannot unread twice")
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
	log.Println("returning error", err)
	return nil
}

func (p *parser) parseProlog() parserState {
	log.Println("parsing prolog")
	if !p.skipLexemes(lex.Space, lex.Break) {
		log.Println("parsing prolog: terminated")
		return nil
	}
	if !p.l.Match(lex.Delimiter, "%") {
		log.Println("parsing prolog: ending prolog at", p.l, "and rewinding")
		p.rewind()
		return p.parseDirectiveOrReifier
	}
	if !p.nextLexeme() || p.l.Type != lex.Name {
		log.Println("parsing prolog: that's weird", p.l)
		return p.parseErrorf("expected directive name")
	}
	log.Println("parsing prolog directive:", p.l.Value)
	switch p.l.Value {
	case "encoding":
		return p.parseEncoding
	case "version":
		return p.parseVersion
	default:
		return p.parseErrorf("unrecognized directive")
	}
}

func (p *parser) parseEncoding() parserState {
	log.Println("parsing encoding")
	if !(p.skipLexemes(lex.Space) && p.l.Type == lex.String) {
		return p.parseErrorf("expected string, got %s", p.l)
	} else if p.l.Value != "\"UTF-8\"" {
		return p.parseErrorf("unsupported encoding")
	} else {
		return p.parseProlog
	}
}

func (p *parser) parseVersion() parserState {
	log.Println("parsing version")
	if !(p.skipLexemes(lex.Space, lex.Break) && p.l.Type == lex.Number) {
		return p.parseErrorf("expected number")
	} else if p.l.Value != "1.0" {
		return p.parseErrorf("only CTM version 1.0 is supported")
	} else {
		return p.parseDirectiveOrReifier
	}
}

func (p *parser) parseDirectiveOrReifier() parserState {
	log.Println("parsing directive or reifier")
	if !p.skipLexemes(lex.Space, lex.Break, lex.Comment) {
		return nil
	} else if p.l.Match(lex.Delimiter, "%") {
		return p.parseErrorf("additional directives not yet supported")
	} else if p.l.Match(lex.Delimiter, "~") {
		return p.parseErrorf("topic map reification not yet supported")
	} else {
		p.rewind()
		return p.parseBody
	}
}

func (p *parser) parseBody() parserState {
	log.Println("parsing body")
	if !p.skipLexemes(lex.Space, lex.Break, lex.Comment) {
		return nil
	} else if p.l.Type != lex.Name {
		return p.parseErrorf("expected word in body")
	} else {
		start := p.l
		if !p.skipLexemes(lex.Space, lex.Break, lex.Comment) {
			return p.parseErrorf("unexpected EOF")
		} else if p.l.Match(lex.Delimiter, "(") {
			return p.parseErrorf("associations not yet supported")
		} else {
			p.rewind()
			p.topic = &topicmaps.Topic{SelfRefs: []topicmaps.TopicRef{{Type: topicmaps.II, IRI: start.Value}}}
			return p.parseTopic
		}
	}
}

func (p *parser) parseTopic() parserState {
	if !p.skipLexemes(lex.Space, lex.Break, lex.Comment) {
		return nil
	} else if p.l.Match(lex.Delimiter, "-") {
		return p.parseName
	} else if p.l.Match(lex.Delimiter, ".") {
		p.m.MergeTopic(p.topic)
		p.topic = nil
		return p.parseBody
	} else {
		return p.parseErrorf("got %s, want topic detail", p.l)
	}
}

func (p *parser) parseName() parserState {
	if !p.skipLexemes(lex.Space, lex.Break, lex.Comment) {
		return nil
	} else if p.l.Type != lex.String {
		return p.parseErrorf("expected string as name")
	} else {
		p.topic.Names = append(p.topic.Names, &topicmaps.Name{
			Valued: topicmaps.Valued{unquote(p.l.Value)},
		})
		return p.parseTopic
	}
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
