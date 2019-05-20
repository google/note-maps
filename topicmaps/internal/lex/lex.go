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

// Package lex implements common lexing utilities.
package lex

import (
	"bufio"
	"io"
	"strings"
	"unicode"
)

const (
	eof = rune(0)
)

type Position struct {
	Line, Column int
}

type RuneScanner struct {
	// Runes are read from RuneScanner.r and buffered into RuneScanner.runes.
	// Each time a rune is appended to RuneScanner.runes, the position of the
	// next rune is appended to RuneScanner.ps. RuneScanner.ps is initialized
	// with the position of the first rune {1,1}.
	//
	// This implies the invariants len(RuneScanner.ps)==len(RuneScanner.runes)+1,
	// RuneScanner.inext>=0, RuneScanner.inext is always a valid index into
	// RuneScanner.ps, and always a valid upper found for a range within
	// RuneScanner.runes.
	//
	// RuneScanner can also move backward through this buffer by decrementing
	// RuneScanner.inext. Whenever inext<len(RuneScanner.runes), the next rune to
	// read is RuneScanner.runes[inext]; otherwise the next rune is read from
	// RuneScanner.r.

	r     io.RuneReader
	inext int
	runes []rune
	ps    []Position

	Err error
}

// NewLexer creates a lexer that reads runes from r.
func NewRuneScanner(r io.Reader) *RuneScanner {
	rr, ok := r.(io.RuneReader)
	if !ok {
		rr = bufio.NewReader(r)
	}
	rs := &RuneScanner{
		r:  rr,
		ps: []Position{{1, 1}},
	}
	return rs
}

func (rs *RuneScanner) Runes() []rune { return rs.runes[:rs.inext] }

func (rs *RuneScanner) Clear() {
	if rs.inext > 0 {
		rs.ps = rs.ps[rs.inext:]
		rs.runes = rs.runes[rs.inext:]
		rs.inext = 0
	}
}

func (rs *RuneScanner) Index() int {
	return rs.inext
}

func (rs *RuneScanner) Seek(n int) {
	rs.inext = n
}

// Position returns the position of the rune at position n within the current
// buffer, and supports negative indexing from the end. Panics if
// abs(n)>=rs.Size().
func (rs *RuneScanner) Position(n int) Position {
	if len(rs.ps) == 1 {
		return rs.ps[0]
	} else if n < 0 {
		return rs.ps[rs.inext+1+n]
	} else {
		return rs.ps[n]
	}
}

// Rune reads and returns the next available rune.
func (rs *RuneScanner) Rune() rune {
	rs.inext++
	if rs.inext <= len(rs.runes) {
		return rs.runes[rs.inext-1]
	}
	r, _, err := rs.r.ReadRune()
	if err != nil {
		if err != io.EOF {
			rs.Err = err
		}
		r = eof
	}
	rs.runes = append(rs.runes, r)
	p := rs.ps[rs.inext-1]
	if r == '\n' {
		p.Line++
		p.Column = 1
	} else {
		p.Column++
	}
	rs.ps = append(rs.ps, p)
	return r
}

// Peek returns the rune that would be returned from a subsequent call to Rune.
func (rs *RuneScanner) Peek() rune {
	var r rune
	if rs.inext < len(rs.runes) {
		r = rs.runes[rs.inext]
	} else {
		r = rs.Rune()
		rs.Unrune()
	}
	return r
}

// Unrune moves backward by one in the rune buffer of runes that have been
// read, such that a subsequent call to Rune will re-read a rune that was read
// before. Panics if the rune buffer is empty.
func (rs *RuneScanner) Unrune() {
	if rs.inext == 0 {
		panic("nothing to unread")
	}
	rs.inext--
}

// AdvanceIf reads a matching rune and returns true, or else leaves rs where it
// was and returns false.
func (rs *RuneScanner) AdvanceIf(runes string, ranges ...*unicode.RangeTable) bool {
	r := rs.Rune()
	if unicode.In(r, ranges...) || strings.IndexRune(runes, r) >= 0 {
		return true
	}
	rs.Unrune()
	return false
}

// AdvanceWhile reads matching runes until EOF or a non-matching rune is found,
// rewinds one step, and finally returns true if and only if at least one
// matching rune was found.
func (rs *RuneScanner) AdvanceWhile(runes string, ranges ...*unicode.RangeTable) bool {
	start := rs.inext
	r := rs.Rune()
	for unicode.In(r, ranges...) || strings.IndexRune(runes, r) >= 0 {
		r = rs.Rune()
	}
	rs.Unrune()
	return rs.inext > start
}

// AdvanceWhile reads non-matching runes until EOF or a matching rune is found,
// rewinds one step, and finally returns true if and only if at least one
// non-matching rune was found.
func (rs *RuneScanner) AdvanceWhileNot(runes string, ranges ...*unicode.RangeTable) bool {
	start := rs.inext
	r := rs.Rune()
	for !(r == eof || unicode.In(r, ranges...) || strings.IndexRune(runes, r) >= 0) {
		r = rs.Rune()
	}
	rs.Unrune()
	return rs.inext > start
}
