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

package lex

import (
	"bytes"
	"fmt"
	"io"
	"strings"
	"unicode"

	"github.com/google/note-maps/topicmaps/internal/lex"
)

// Type identifies the type of lexemes read from a TMQL source.
type Type int

const (
	Error Type = iota
	Break
	Comment
	Delimiter
	EOF
	IRI
	Name
	Number
	Space
	String
)

func (t Type) String() string {
	switch t {
	case Error:
		return "Error"
	case Break:
		return "Break"
	case Comment:
		return "Comment"
	case Delimiter:
		return "Delimiter"
	case EOF:
		return "EOF"
	case IRI:
		return "IRI"
	case Name:
		return "Name"
	case Number:
		return "Number"
	case Space:
		return "Space"
	case String:
		return "String"
	default:
		return "(unrecognized lexeme type)"
	}
}

// Terminal returns true if t indicates that reading should stop.
func (t Type) Terminal() bool { return t == EOF || t == Error }

// Lexeme describes a lexical TMQL atom, including its position in a source
// text.
type Lexeme struct {
	Type       Type
	Value      string
	Start, End lex.Position
	// ErrMessage is set only when Type==Error.
	ErrMessage string
	// ErrInner is set only when Type==Error.
	ErrInner error
}

func (l Lexeme) String() string {
	return fmt.Sprintf("[:%d:%d :%d:%d] %s %q",
		l.Start.Line, l.Start.Column,
		l.End.Line, l.End.Column,
		l.Type, l.Value)
}

func (l Lexeme) Match(t Type, v string) bool { return l.Type == t && l.Value == v }

func (l Lexeme) err() *ErrorInfo {
	if l.Type != Error {
		return nil
	} else {
		return &ErrorInfo{
			Message: l.ErrMessage,
			Inner:   l.ErrInner,
			Start:   l.Start,
			End:     l.End,
		}
	}
}

// ErrorInfo desribes an lexical error along with the position in a source where
// the error occurred.
type ErrorInfo struct {
	Message    string
	Inner      error
	Start, End lex.Position
}

func (e ErrorInfo) Error() string {
	buf := bytes.NewBuffer(nil)
	if e.Start == e.End {
		fmt.Fprintf(buf, ":%d:%d %s",
			e.Start.Line, e.Start.Column, e.Message)
	} else if e.Start.Line == e.End.Line {
		fmt.Fprintf(buf, ":%d:%d..%d %s",
			e.Start.Line, e.Start.Column, e.End.Column, e.Message)
	} else {
		fmt.Fprintf(buf, ":%d:%d..%d:%d %s",
			e.Start.Line, e.Start.Column, e.End.Line, e.End.Column, e.Message)
	}
	if e.Inner != nil {
		fmt.Fprintf(buf, ": %s", e.Inner.Error())
	}
	return buf.String()
}

// Lexer supports lexing a TMQL source into lexical atoms.
type Lexer struct {
	*lex.RuneScanner
	ch    chan *Lexeme
	state lexState
	stop  *Lexeme
}

// NewLexer creates a lexer that can read lexical TMQL atoms from r.
func NewLexer(r io.Reader) *Lexer {
	lx := &Lexer{
		RuneScanner: lex.NewRuneScanner(r),
		ch:          make(chan *Lexeme, 2),
	}
	lx.state = lx.scanAny
	return lx
}

// Lexeme returns the next lexical TMQL atom, and never returns nil.
//
// At the end of available input, Lexeme returns a Lexeme with Type==EOF. If an
// error is encountered, a Lexeme is returned with Type==Error.
func (lx *Lexer) Lexeme() *Lexeme {
	for lx.stop == nil {
		if lx.Err != nil {
			lx.err("lexing error", lx.Err)
		}
		select {
		case l := <-lx.ch:
			if l.Type == Error || l.Type == EOF {
				lx.stop = l
			}
			return l
		default:
			if lx.state == nil {
				lx.emit(EOF)
				close(lx.ch)
			} else {
				lx.state = lx.state()
			}
		}
	}
	return lx.stop
}

// lexeme creates and returns a lexeme, respecting rewind operations, and has
// no side-effects.
func (lx *Lexer) lexeme(t Type) *Lexeme {
	return &Lexeme{
		Type:  t,
		Value: string(lx.Runes()),
		Start: lx.Position(0),
		End:   lx.Position(lx.Index() - 1),
	}
}

func (lx *Lexer) err(m string, inner error) {
	l := lx.lexeme(Error)
	l.ErrMessage = m
	l.ErrInner = inner
	lx.ch <- l
}

func (lx *Lexer) emit(t Type) {
	lx.ch <- lx.lexeme(t)
	lx.Clear()
}

type lexState func() lexState

func (lx *Lexer) scanAny() lexState {
	r := lx.Peek()
	switch {
	case r == '\x00':
		return nil
	case r == '#':
		return lx.scanComment
	case r == '"', r == '\'':
		return lx.scanString
	case unicode.In(r, unicode.Number), r == '+', r == '-':
		return lx.scanNumber
	case r == '\r', r == '\n', unicode.In(r, unicode.Zl, unicode.Zp):
		return lx.scanBreak
	case unicode.IsSpace(r), unicode.In(r, unicode.Space):
		return lx.scanSpace
	case strings.IndexRune("@$%^&|*-+=(){}[]\"'/\\<>:.,~", r) >= 0:
		return lx.scanDelim
	case unicode.IsLetter(r), unicode.IsDigit(r):
		return lx.scanWord
	default:
		lx.err("unexpected rune", nil)
		return nil
	}
}

func (lx *Lexer) scanBreak() (next lexState) {
	if lx.Rune() == '\r' {
		lx.AdvanceIf("\n")
	}
	lx.emit(Break)
	return lx.scanAny
}

func (lx *Lexer) scanComment() lexState {
	if lx.Rune() != '#' {
		lx.err("expected comment", nil)
		return nil
	}
	lx.AdvanceWhileNot("\r\n", unicode.Zl, unicode.Zp)
	lx.emit(Comment)
	return lx.scanAny
}

func (lx *Lexer) scanDelim() lexState {
	next := lx.scanAny
	r := lx.Rune()
	if strings.IndexRune("/><", r) >= 0 {
		if lx.Peek() == r {
			lx.Rune()
		}
	} else if r == '$' {
		next = lx.scanWord
	}
	lx.emit(Delimiter)
	return next
}

func (lx *Lexer) scanNumber() lexState {
	lx.AdvanceIf("-+")
	if lx.AdvanceWhile("0123456789", unicode.Number) {
		if lx.AdvanceIf(".") {
			lx.AdvanceWhile("", unicode.Number)
		}
		lx.emit(Number)
	} else {
		lx.emit(Delimiter)
	}
	return lx.scanAny
}

func (lx *Lexer) scanSpace() lexState {
	lx.AdvanceWhile("\t", unicode.Zs)
	lx.emit(Space)
	return lx.scanAny
}

func (lx *Lexer) scanString() lexState {
	q := lx.Rune()
	if q != '\'' && q != '"' {
		lx.err("expected string", nil)
	}
String:
	for {
		switch lx.Rune() {
		case '\\':
			lx.Rune()
		case q:
			break String
		}
	}
	lx.emit(String)
	return lx.scanAny
}

func (lx *Lexer) scanWord() lexState {
	lx.AdvanceWhile("_.", unicode.Letter, unicode.Number)
	for lx.Runes()[lx.Index()-1] == '.' {
		lx.Unrune()
	}
	i := lx.Index()
	if lx.Rune() == ':' && lx.Rune() == '/' && lx.Rune() == '/' {
		lx.AdvanceWhileNot(" \t\r\n", unicode.Space)
		for lx.Runes()[lx.Index()-1] == '.' {
			lx.Unrune()
		}
		lx.emit(IRI)
	} else {
		lx.Seek(i)
		lx.emit(Name)
	}
	return lx.scanAny
}
