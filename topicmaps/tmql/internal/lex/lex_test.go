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
	}{
		{In: "", Want: []Lexeme{}},
		{In: ".", Want: []Lexeme{{Type: Delimiter, Value: "."}}},
		{In: "//", Want: []Lexeme{
			{Type: Delimiter, Value: "//"},
		}},
		{In: "// $topic", Want: []Lexeme{
			{Type: Delimiter, Value: "//"},
			{Type: Space, Value: " "},
			{Type: Delimiter, Value: "$"},
			{Type: Name, Value: "topic"},
		}},
		{In: "//[exists ./name]", Want: []Lexeme{
			{Type: Delimiter, Value: "//"},
			{Type: Delimiter, Value: "["},
			{Type: Name, Value: "exists"},
			{Type: Space, Value: " "},
			{Type: Delimiter, Value: "."},
			{Type: Delimiter, Value: "/"},
			{Type: Name, Value: "name"},
			{Type: Delimiter, Value: "]"},
		}},
	} {
		t.Logf("%d %q", itest, test.In)
		lexer := NewLexer(bytes.NewReader([]byte(test.In)))
		for iwant, want := range test.Want {
			got := lexer.Lexeme()
			if got == nil {
				t.Fatalf("%v %v: got nil lexeme", itest, iwant)
			}
			if got.Type != want.Type || got.Value != want.Value {
				t.Errorf("%v %v: want %#v, got %#v", itest, iwant, want, *got)
			}
		}
		final := lexer.Lexeme()
		if final == nil || final.Type != EOF {
			t.Errorf("%v: test complete but got non-EOF lexeme %#v", itest, final)
		}
	}
}
