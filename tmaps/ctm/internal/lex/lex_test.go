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
	"testing"

	"github.com/google/note-maps/tmaps/internal/lex"
)

func TestLexer(t *testing.T) {
	for itest, test := range []struct {
		In   string
		Want []Lexeme
		Err  bool
	}{
		{
			In: "%version 1.0\n# comment",
			Want: []Lexeme{
				{Delimiter, "%", lex.Position{1, 1}, lex.Position{1, 1}, "", nil},
				{Name, "version", lex.Position{1, 2}, lex.Position{1, 8}, "", nil},
				{Space, " ", lex.Position{1, 9}, lex.Position{1, 9}, "", nil},
				{Number, "1.0", lex.Position{1, 10}, lex.Position{1, 12}, "", nil},
				{Break, "\n", lex.Position{1, 13}, lex.Position{1, 13}, "", nil},
				{Comment, "# comment", lex.Position{2, 1}, lex.Position{2, 9}, "", nil},
			},
		},
		{
			In: `"string"`,
			Want: []Lexeme{
				{String, `"string"`, lex.Position{1, 1}, lex.Position{1, 8}, "", nil},
			},
		},
		{
			In: `%encoding  "UTF-8"`,
			Want: []Lexeme{
				{Delimiter, `%`, lex.Position{1, 1}, lex.Position{1, 1}, "", nil},
				{Name, `encoding`, lex.Position{1, 2}, lex.Position{1, 9}, "", nil},
				{Space, `  `, lex.Position{1, 10}, lex.Position{1, 11}, "", nil},
				{String, `"UTF-8"`, lex.Position{1, 12}, lex.Position{1, 18}, "", nil},
			},
		},
		{
			In: `item - "name"`,
			Want: []Lexeme{
				{Name, `item`, lex.Position{1, 1}, lex.Position{1, 4}, "", nil},
				{Space, ` `, lex.Position{1, 5}, lex.Position{1, 5}, "", nil},
				{Delimiter, `-`, lex.Position{1, 6}, lex.Position{1, 6}, "", nil},
				{Space, ` `, lex.Position{1, 7}, lex.Position{1, 7}, "", nil},
				{String, `"name"`, lex.Position{1, 8}, lex.Position{1, 13}, "", nil},
			},
		},
		{
			In: `prefix:name`,
			Want: []Lexeme{
				{Name, `prefix`, lex.Position{1, 1}, lex.Position{1, 6}, "", nil},
				{Delimiter, `:`, lex.Position{1, 7}, lex.Position{1, 7}, "", nil},
				{Name, `name`, lex.Position{1, 8}, lex.Position{1, 11}, "", nil},
			},
		},
		{
			In: `scheme://iri.`,
			Want: []Lexeme{
				{IRI, `scheme://iri`, lex.Position{1, 1}, lex.Position{1, 12}, "", nil},
				{Delimiter, `.`, lex.Position{1, 13}, lex.Position{1, 13}, "", nil},
			},
		},
		{
			In: `
					# multiline literal
			`,
			Want: []Lexeme{
				{Break, "\n", lex.Position{1, 1}, lex.Position{1, 1}, "", nil},
				{Space, "\t\t\t\t\t", lex.Position{2, 1}, lex.Position{2, 5}, "", nil},
				{Comment, `# multiline literal`, lex.Position{2, 6}, lex.Position{2, 24}, "", nil},
				{Break, "\n", lex.Position{2, 25}, lex.Position{2, 25}, "", nil},
				{Space, "\t\t\t", lex.Position{3, 1}, lex.Position{3, 3}, "", nil},
			},
		},
	} {
		lexer := NewLexer(bytes.NewReader([]byte(test.In)))
		for ilex, want := range test.Want {
			got := lexer.Lexeme()
			if got.Type == Error {
				t.Errorf("%d %d: %s", itest, ilex, got)
				break
			}
			if *got != want {
				t.Errorf("%d %d: got %s, want %s", itest, ilex, got, want)
			}
		}
		got := lexer.Lexeme()
		if got.Type != EOF {
			t.Errorf("%d: got unexpected %s", itest, got)
		}
	}
}
