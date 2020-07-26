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

// +build ignore

package otgen

import (
	"bytes"
	"go/ast"
	"go/importer"
	"go/parser"
	"go/token"
	"go/types"
	"regexp"
	"testing"
)

var tests = []struct {
	Name       string
	Source     string
	Substrings []string
}{
	{
		Name: "docs",
		Source: `
package input

import "github.com/google/note-maps/kv"

const (
	DocumentPrefix kv.Component = 3
	TitlePrefix    kv.Component = 4
)

type Document struct{ Title string }

func (d *Document) Encode() []byte          { return nil }
func (d *Document) Decode(src []byte) error { return nil }
func (d *Document) IndexTitle() []kv.String { return nil }
`,
		Substrings: []string{
			`type Txn struct.?{`,
			`func \(.* Txn\) EntitiesMatchingDocumentTitle\(v kv\.String\)`,
		},
	},
}

type Implementer struct {
	Name   string
	Direct bool
	Type   *types.Named
}
type ImplementerReport struct {
	Name         string
	Interface    *types.Interface
	Implementers []*Implementer
}

func TestStuff(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping slow test in -short mode")
	}
	for _, test := range tests {
		fset := token.NewFileSet()
		f, err := parser.ParseFile(fset, "input.go", test.Source, 0)
		if err != nil {
			t.Errorf("%s: %s", test.Name, err)
		}
		conf := types.Config{
			Importer: importer.For("source", nil),
		}
		pkg, err := conf.Check("input", fset, []*ast.File{f}, nil)
		if err != nil {
			t.Errorf("%s: %s", test.Name, err)
		}
		var buf bytes.Buffer
		if err := gen(pkg, &buf); err != nil {
			t.Error(err)
		}
		generated := buf.String()
		t.Log(generated)
		fgen, err := parser.ParseFile(fset, "kvschema.go", generated, 0)
		if err != nil {
			t.Errorf("%s: %s", test.Name, err)
		}
		_, err = conf.Check("input", fset, []*ast.File{f, fgen}, nil)
		if err != nil {
			t.Errorf("%s: %s", test.Name, err)
		}
		for _, want := range test.Substrings {
			if match, err := regexp.MatchString(want, generated); err != nil {
				t.Fatalf("bad regexp %#v in test: %s", match, err)
			} else if !match {
				t.Errorf(
					"%s: want pattern %#v, but did not find it in generated result",
					test.Name, want)
			}
		}
	}
}
