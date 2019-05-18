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

// Package lex implements lexing for the CTM data format.
package lex

import (
	"bufio"
	"bytes"
	"fmt"
	"io"
	"strings"
	"unicode"
)

const (
	eof = rune(0)
)

// Type identifies the type of lexemes read from a CTM source.
type Type int

const (
	Error Type = iota
	Break
	Comment
	Delimiter
	EOF
	Number
	Space
	String
	Word
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
	case Number:
		return "Number"
	case Space:
		return "Space"
	case String:
		return "String"
	case Word:
		return "Word"
	default:
		return "(unrecognized lexeme type)"
	}
}

func (t Type) Terminal() bool { return t == EOF || t == Error }

// Lexeme describes a lexical CTM atom, including its position in a source
// text.
type Lexeme struct {
	Type                   Type
	Value                  string
	StartLine, StartColumn int
	EndLine, EndColumn     int
	ErrMessage             string
	errInner               error
}

func (l Lexeme) String() string {
	return fmt.Sprintf("[:%d:%d :%d:%d] %s %q",
		l.StartLine, l.StartColumn,
		l.EndLine, l.EndColumn,
		l.Type, l.Value)
}

func (l Lexeme) Match(t Type, v string) bool { return l.Type == t && l.Value == v }

func (l Lexeme) err() *ErrorInfo {
	if l.Type != Error {
		return nil
	} else {
		return &ErrorInfo{
			Message:     l.ErrMessage,
			Inner:       l.errInner,
			StartLine:   l.StartLine,
			StartColumn: l.StartColumn,
			EndLine:     l.EndLine,
			EndColumn:   l.EndColumn,
		}
	}
}

// ErrorInfo desribes an lexical error along with the position in a source where
// the error occurred.
type ErrorInfo struct {
	Message                string
	Inner                  error
	StartLine, StartColumn int
	EndLine, EndColumn     int
}

func (e ErrorInfo) Error() string {
	buf := bytes.NewBuffer(nil)
	if e.StartLine == e.EndLine && e.StartColumn == e.EndColumn {
		fmt.Fprintf(buf, ":%d:%d %s",
			e.StartLine, e.StartColumn, e.Message)
	} else if e.StartLine == e.EndLine {
		fmt.Fprintf(buf, ":%d:%d..%d %s",
			e.StartLine, e.StartColumn, e.EndColumn, e.Message)
	} else {
		fmt.Fprintf(buf, ":%d:%d..%d:%d %s",
			e.StartLine, e.StartColumn, e.EndLine, e.EndColumn, e.Message)
	}
	if e.Inner != nil {
		fmt.Fprintf(buf, ": %s", e.Inner.Error())
	}
	return buf.String()
}

// Lexer supports lexing a CTM source into lexical atoms.
type Lexer struct {
	r          io.RuneReader
	ch         chan *Lexeme
	state      lexState
	line0      int
	column0    int
	line1      int
	column1    int
	runes      []rune
	prevRune   rune
	prevColumn int
	rewound    bool
	lbr        bool
	stop       *Lexeme
}

// NewLexer creates a lexer that can read lexical CTM atoms from r.
func NewLexer(r io.Reader) *Lexer {
	rr, ok := r.(io.RuneReader)
	if !ok {
		rr = bufio.NewReader(r)
	}
	lx := &Lexer{
		r:       rr,
		ch:      make(chan *Lexeme, 2),
		line0:   1,
		column0: 1,
		line1:   1,
		column1: 0,
	}
	lx.state = lx.scanAny
	return lx
}

// Lexeme returns the next lexical CTM atom, and never returns nil.
//
// At the end of available input, Lexeme returns a Lexeme with Type==EOF. If an
// error is encountered, a Lexeme is returned with Type==Error.
func (lx *Lexer) Lexeme() *Lexeme {
	for lx.stop == nil {
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

func (lx *Lexer) err(m string, inner error) {
	lx.ch <- &Lexeme{
		Type:        Error,
		ErrMessage:  m,
		errInner:    inner,
		StartLine:   lx.line0,
		StartColumn: lx.column0,
		EndLine:     lx.line1,
		EndColumn:   lx.column1,
	}
	lx.line0, lx.column0 = lx.line1, lx.column1
}

func (lx *Lexer) emit(t Type) {
	line1, column1 := lx.line1, lx.column1
	size := len(lx.runes)
	// If emitting EOF then lx.prevRune should be eof. However, we may or may not
	// have unread that rune. As a result, we get inconsistent results here.
	if lx.rewound && t == EOF {
		lx.rewound = false
		size = 0
	}
	if lx.rewound {
		size--
		if column1 <= lx.prevColumn {
			column1 = lx.prevColumn
			line1--
		} else {
			column1--
		}
	}
	lx.ch <- &Lexeme{
		Type:        t,
		Value:       string(lx.runes),
		StartLine:   lx.line0,
		StartColumn: lx.column0,
		EndLine:     line1,
		EndColumn:   column1,
	}
	lx.runes = lx.runes[0:0]
	lx.line0, lx.column0 = lx.line1, lx.column1
}

func (lx *Lexer) nextRune() rune {
	lbr := false
	if lx.rewound {
		lx.rewound = false
		lx.runes = append(lx.runes, lx.prevRune)
	} else {
		lbr = lx.prevRune == '\n'
		var err error
		lx.prevRune, _, err = lx.r.ReadRune()
		if err != nil {
			if err != io.EOF {
				lx.err("while lexing", err)
			}
			lx.prevRune = eof
		}
		lx.prevColumn = lx.column1
		if lbr {
			lx.line1++
			lx.column1 = 1
		} else {
			lx.column1++
		}
		if len(lx.runes) == 0 {
			lx.line0, lx.column0 = lx.line1, lx.column1
		}
		lx.runes = append(lx.runes, lx.prevRune)
	}
	return lx.prevRune
}

func (lx *Lexer) peekRune() rune {
	r := lx.nextRune()
	lx.unreadRune()
	return r
}

func (lx *Lexer) unreadRune() {
	if len(lx.runes) == 0 {
		panic("nothing to unread")
	} else if lx.rewound {
		panic("cannot unread twice")
	}
	lx.rewound = true
	lx.runes = lx.runes[:len(lx.runes)-1]
}

type lexState func() lexState

func (lx *Lexer) scanAny() lexState {
	r := lx.peekRune()
	switch {
	case r == eof:
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
	case strings.IndexRune("%.", r) >= 0:
		return lx.scanDelim
	case unicode.IsLetter(r), unicode.IsDigit(r), strings.IndexRune("%.", r) >= 0:
		return lx.scanWord
	default:
		lx.err("unexpected rune", nil)
		return nil
	}
}

func (lx *Lexer) scanBreak() (next lexState) {
	if lx.nextRune() == '\r' {
		lx.advanceIf("\n")
	}
	lx.emit(Break)
	return lx.scanAny
}

func (lx *Lexer) scanComment() lexState {
	if lx.nextRune() != '#' {
		lx.err("expected comment", nil)
		return nil
	}
	lx.advanceWhileNot("\r\n", unicode.Zl, unicode.Zp)
	lx.emit(Comment)
	return lx.scanAny
}

func (lx *Lexer) scanNumber() lexState {
	lx.advanceIf("-+")
	if lx.advanceWhile("0123456789", unicode.Number) {
		if lx.advanceIf(".") {
			lx.advanceWhile("", unicode.Number)
		}
		lx.emit(Number)
	} else {
		lx.emit(Delimiter)
	}
	return lx.scanAny
}

func (lx *Lexer) scanSpace() lexState {
	lx.advanceWhile("\t", unicode.Zs)
	lx.emit(Space)
	return lx.scanAny
}

func (lx *Lexer) scanString() lexState {
	q := lx.nextRune()
	if q != '\'' && q != '"' {
		lx.err("expected string", nil)
	}
String:
	for {
		switch lx.nextRune() {
		case '\\':
			lx.nextRune()
		case q:
			break String
		}
	}
	lx.emit(String)
	return lx.scanAny
}

func (lx *Lexer) advanceIf(runes string, ranges ...*unicode.RangeTable) bool {
	r := lx.nextRune()
	if unicode.In(r, ranges...) || strings.IndexRune(runes, r) >= 0 {
		return true
	}
	lx.unreadRune()
	return false
}

func (lx *Lexer) advanceWhile(runes string, ranges ...*unicode.RangeTable) bool {
	start := len(lx.runes)
	r := lx.nextRune()
	for unicode.In(r, ranges...) || strings.IndexRune(runes, r) >= 0 {
		r = lx.nextRune()
	}
	lx.unreadRune()
	return len(lx.runes) > start
}

func (lx *Lexer) advanceWhileNot(runes string, ranges ...*unicode.RangeTable) bool {
	start := len(lx.runes)
	r := lx.nextRune()
	for !(r == eof || unicode.In(r, ranges...) || strings.IndexRune(runes, r) >= 0) {
		r = lx.nextRune()
	}
	lx.unreadRune()
	return len(lx.runes) > start
}

// scanDelim emits nextRune as a Delimiter.
func (lx *Lexer) scanDelim() lexState {
	lx.nextRune()
	lx.emit(Delimiter)
	return lx.scanAny
}

func (lx *Lexer) scanWord() lexState {
	if !lx.advanceIf("_", unicode.Letter) {
		lx.err(fmt.Sprintf("expected word, found %q", string(lx.peekRune())), nil)
	}
	lx.advanceWhile("_", unicode.Letter, unicode.Number)
	lx.emit(Word)
	return lx.scanAny
}
