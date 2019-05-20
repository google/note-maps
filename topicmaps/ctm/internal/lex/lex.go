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

func (t Type) Terminal() bool { return t == EOF || t == Error }

// Lexeme describes a lexical CTM atom, including its position in a source
// text.
type Lexeme struct {
	Type       Type
	Value      string
	Start, End Position
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
	Start, End Position
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

type Position struct {
	Line, Column int
}

// Lexer supports lexing a CTM source into lexical atoms.
type Lexer struct {
	// Runes are read from Lexer.r and bufered into Lexer.runes. Each time a rune
	// is appended to Lexer.runes, the position of the next rune is appended to
	// Lexer.ps. Lexer.ps is initialized with the position of the first rune {1,1}.
	//
	// This implies the invariants len(Lexer.ps)==len(Lexer.runes)+1,
	// Lexer.inext>=0, Lexer.inext is always a valid index into Lexer.ps, and
	// always a valid upper found for a range within Lexer.runes.
	//
	// Lexer can also move backward through this buffer by decrementing
	// Lexer.inext. Whenever inext<len(Lexer.runes), the next rune to read is
	// Lexer.runes[inext]; otherwise the next rune is read from Lexer.r.

	r     io.RuneReader
	ch    chan *Lexeme
	state lexState
	ps    []Position
	inext int
	runes []rune
	stop  *Lexeme
}

// NewLexer creates a lexer that can read lexical CTM atoms from r.
func NewLexer(r io.Reader) *Lexer {
	rr, ok := r.(io.RuneReader)
	if !ok {
		rr = bufio.NewReader(r)
	}
	lx := &Lexer{
		r:  rr,
		ch: make(chan *Lexeme, 2),
		ps: []Position{{1, 1}},
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

// position returns the position of the rune at position n within the current
// lexeme, and supports negative indexing from the end.
func (lx *Lexer) position(n int) Position {
	if len(lx.ps) == 1 {
		return lx.ps[0]
	} else if n < 0 {
		return lx.ps[lx.inext+1+n]
	} else {
		return lx.ps[n]
	}
}

// lexeme creates and returns a lexeme, respecting rewind operations, and has
// no side-effects.
func (lx *Lexer) lexeme(t Type) *Lexeme {
	return &Lexeme{
		Type:  t,
		Value: string(lx.runes[0:lx.inext]),
		Start: lx.position(0),
		End:   lx.position(lx.inext - 1),
	}
}

func (lx *Lexer) err(m string, inner error) {
	l := lx.lexeme(Error)
	l.ErrMessage = m
	l.ErrInner = inner
	lx.ch <- l
}

func (lx *Lexer) emit(t Type) {
	l := lx.lexeme(t)
	if lx.inext > 0 {
		lx.ps = lx.ps[lx.inext:]
		lx.runes = lx.runes[lx.inext:]
		lx.inext = 0
	}
	lx.ch <- l
}

func (lx *Lexer) readRune() rune {
	lx.inext++
	if lx.inext <= len(lx.runes) {
		return lx.runes[lx.inext-1]
	}
	r, _, err := lx.r.ReadRune()
	if err != nil {
		if err != io.EOF {
			lx.err("while lexing", err)
		}
		r = eof
	}
	lx.runes = append(lx.runes, r)
	p := lx.ps[lx.inext-1]
	if r == '\n' {
		p.Line++
		p.Column = 1
	} else {
		p.Column++
	}
	lx.ps = append(lx.ps, p)
	return r
}

func (lx *Lexer) peekRune() rune {
	var r rune
	if lx.inext < len(lx.runes) {
		r = lx.runes[lx.inext]
	} else {
		r = lx.readRune()
		lx.unreadRune()
	}
	return r
}

func (lx *Lexer) unreadRune() {
	if lx.inext == 0 {
		panic("nothing to unread")
	}
	lx.inext--
}

func (lx *Lexer) advanceIf(runes string, ranges ...*unicode.RangeTable) bool {
	r := lx.readRune()
	if unicode.In(r, ranges...) || strings.IndexRune(runes, r) >= 0 {
		return true
	}
	lx.unreadRune()
	return false
}

// advanceWhile reads matching runes until EOF or a non-matching rune is found,
// rewinds one step, and finally returns true if and only if at least one
// matching rune was found.
func (lx *Lexer) advanceWhile(runes string, ranges ...*unicode.RangeTable) bool {
	start := lx.inext
	r := lx.readRune()
	for unicode.In(r, ranges...) || strings.IndexRune(runes, r) >= 0 {
		r = lx.readRune()
	}
	lx.unreadRune()
	return lx.inext > start
}

// advanceWhile reads non-matching runes until EOF or a matching rune is found,
// rewinds one step, and finally returns true if and only if at least one
// non-matching rune was found.
func (lx *Lexer) advanceWhileNot(runes string, ranges ...*unicode.RangeTable) bool {
	start := lx.inext
	r := lx.readRune()
	for !(r == eof || unicode.In(r, ranges...) || strings.IndexRune(runes, r) >= 0) {
		r = lx.readRune()
	}
	lx.unreadRune()
	return lx.inext > start
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
	case strings.IndexRune("%.:(),", r) >= 0:
		return lx.scanDelim
	case unicode.IsLetter(r), unicode.IsDigit(r):
		return lx.scanWord
	default:
		lx.err("unexpected rune", nil)
		return nil
	}
}

func (lx *Lexer) scanBreak() (next lexState) {
	if lx.readRune() == '\r' {
		lx.advanceIf("\n")
	}
	lx.emit(Break)
	return lx.scanAny
}

func (lx *Lexer) scanComment() lexState {
	if lx.readRune() != '#' {
		lx.err("expected comment", nil)
		return nil
	}
	lx.advanceWhileNot("\r\n", unicode.Zl, unicode.Zp)
	lx.emit(Comment)
	return lx.scanAny
}

func (lx *Lexer) scanDelim() lexState {
	lx.readRune()
	lx.emit(Delimiter)
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
	q := lx.readRune()
	if q != '\'' && q != '"' {
		lx.err("expected string", nil)
	}
String:
	for {
		switch lx.readRune() {
		case '\\':
			lx.readRune()
		case q:
			break String
		}
	}
	lx.emit(String)
	return lx.scanAny
}

func (lx *Lexer) scanWord() lexState {
	lx.advanceWhile("_.", unicode.Letter, unicode.Number)
	for lx.runes[lx.inext-1] == '.' {
		lx.unreadRune()
	}
	i := lx.inext
	if lx.readRune() == ':' && lx.readRune() == '/' && lx.readRune() == '/' {
		lx.advanceWhileNot(" \t\r\n", unicode.Space)
		for lx.runes[lx.inext-1] == '.' {
			lx.unreadRune()
		}
		lx.emit(IRI)
	} else {
		lx.inext = i
		lx.emit(Name)
	}
	return lx.scanAny
}
