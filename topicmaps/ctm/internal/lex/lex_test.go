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
)

func TestLexer_Position(t *testing.T) {
	lexer := NewLexer(bytes.NewReader([]byte("abc")))
	lexer.nextRune()
	for itest, test := range []struct {
		Index int
		Want  Position
	}{
		{0, Position{1, 1}},
		{1, Position{1, 2}},
		{-1, Position{1, 2}},
		{-2, Position{1, 1}},
	} {
		got := lexer.position(test.Index)
		if got != test.Want {
			t.Error(itest, "got", got, "want", test.Want)
		}
	}
}

func TestLexer(t *testing.T) {
	for itest, test := range []struct {
		In   string
		Want []Lexeme
		Err  bool
	}{
		{
			In: "%version 1.0\n# comment",
			Want: []Lexeme{
				{Delimiter, "%", Position{1, 1}, Position{1, 1}, "", nil},
				{Word, "version", Position{1, 2}, Position{1, 8}, "", nil},
				{Space, " ", Position{1, 9}, Position{1, 9}, "", nil},
				{Number, "1.0", Position{1, 10}, Position{1, 12}, "", nil},
				{Break, "\n", Position{1, 13}, Position{1, 13}, "", nil},
				{Comment, "# comment", Position{2, 1}, Position{2, 9}, "", nil},
				{EOF, "", Position{2, 10}, Position{2, 10}, "", nil},
			},
		},
		{
			In: `"string"`,
			Want: []Lexeme{
				{String, `"string"`, Position{1, 1}, Position{1, 8}, "", nil},
				{EOF, ``, Position{1, 9}, Position{1, 9}, "", nil},
			},
		},
		{
			In: `%encoding  "UTF-8"`,
			Want: []Lexeme{
				{Delimiter, `%`, Position{1, 1}, Position{1, 1}, "", nil},
				{Word, `encoding`, Position{1, 2}, Position{1, 9}, "", nil},
				{Space, `  `, Position{1, 10}, Position{1, 11}, "", nil},
				{String, `"UTF-8"`, Position{1, 12}, Position{1, 18}, "", nil},
				{EOF, ``, Position{1, 19}, Position{1, 19}, "", nil},
			},
		},
		{
			In: `item - "name"`,
			Want: []Lexeme{
				{Word, `item`, Position{1, 1}, Position{1, 4}, "", nil},
				{Space, ` `, Position{1, 5}, Position{1, 5}, "", nil},
				{Delimiter, `-`, Position{1, 6}, Position{1, 6}, "", nil},
				{Space, ` `, Position{1, 7}, Position{1, 7}, "", nil},
				{String, `"name"`, Position{1, 8}, Position{1, 13}, "", nil},
				{EOF, ``, Position{1, 14}, Position{1, 14}, "", nil},
			},
		},
		{
			In: `
					# multiline literal
			`,
			Want: []Lexeme{
				{Break, "\n", Position{1, 1}, Position{1, 1}, "", nil},
				{Space, "\t\t\t\t\t", Position{2, 1}, Position{2, 5}, "", nil},
				{Comment, `# multiline literal`, Position{2, 6}, Position{2, 24}, "", nil},
				{Break, "\n", Position{2, 25}, Position{2, 25}, "", nil},
				{Space, "\t\t\t", Position{3, 1}, Position{3, 3}, "", nil},
				{EOF, "", Position{3, 4}, Position{3, 4}, "", nil},
			},
		},
	} {
		t.Logf("test.In = %q", test.In)
		lexer := NewLexer(bytes.NewReader([]byte(test.In)))
		for ilex, want := range test.Want {
			got := lexer.Lexeme()
			if got.Type == Error {
				t.Errorf("%d %d: %s", itest, ilex, got)
				break
			}
			if *got != want {
				t.Errorf("%d %d: got %s, want %s", itest, ilex, got, want)
			} else {
				t.Logf("%d %d: got %s", itest, ilex, got)
			}
		}
		got := lexer.Lexeme()
		if got.Type != EOF {
			t.Errorf("%d: got unexpected %s", itest, got)
		}
	}
}
