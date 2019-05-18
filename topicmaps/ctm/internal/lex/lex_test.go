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

func TestLexer(t *testing.T) {
	for itest, test := range []struct {
		In   string
		Want []Lexeme
		Err  bool
	}{
		{
			In: "%version 1.0\n# comment",
			Want: []Lexeme{
				{Delimiter, "%", 1, 1, 1, 1, "", nil},
				{Word, "version", 1, 2, 1, 8, "", nil},
				{Space, " ", 1, 9, 1, 9, "", nil},
				{Number, "1.0", 1, 10, 1, 12, "", nil},
				{Break, "\n", 1, 13, 1, 13, "", nil},
				{Comment, "# comment", 2, 1, 2, 9, "", nil},
				{EOF, "", 2, 10, 2, 10, "", nil},
			},
		},
		{
			In: `"string"`,
			Want: []Lexeme{
				{String, `"string"`, 1, 1, 1, 8, "", nil},
				{EOF, ``, 1, 9, 1, 9, "", nil},
			},
		},
		{
			In: `%encoding  "UTF-8"`,
			Want: []Lexeme{
				{Delimiter, `%`, 1, 1, 1, 1, "", nil},
				{Word, `encoding`, 1, 2, 1, 9, "", nil},
				{Space, `  `, 1, 10, 1, 11, "", nil},
				{String, `"UTF-8"`, 1, 12, 1, 18, "", nil},
				{EOF, ``, 1, 19, 1, 19, "", nil},
			},
		},
		{
			In: `item - "name"`,
			Want: []Lexeme{
				{Word, `item`, 1, 1, 1, 4, "", nil},
				{Space, ` `, 1, 5, 1, 5, "", nil},
				{Delimiter, `-`, 1, 6, 1, 6, "", nil},
				{Space, ` `, 1, 7, 1, 7, "", nil},
				{String, `"name"`, 1, 8, 1, 13, "", nil},
				{EOF, ``, 1, 14, 1, 14, "", nil},
			},
		},
		{
			In: `
					# multiline literal
			`,
			Want: []Lexeme{
				{Break, "\n", 1, 1, 1, 1, "", nil},
				{Space, "\t\t\t\t\t", 2, 1, 2, 5, "", nil},
				{Comment, `# multiline literal`, 2, 6, 2, 24, "", nil},
				{Break, "\n", 2, 25, 2, 25, "", nil},
				{Space, "\t\t\t", 3, 1, 3, 3, "", nil},
				{EOF, "", 3, 4, 3, 4, "", nil},
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
