// Copyright 2020 Google LLC
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

package yaml

import (
	"encoding/json"
	"strings"
	"testing"

	"github.com/google/note-maps/notes"
	"github.com/google/note-maps/notes/notestest"
)

type note struct {
	id          notes.ID
	valuestring string
	valuetype   notes.GraphNote
	contents    []notes.GraphNote
	types       []notes.GraphNote
}

func (n note) GetID() notes.ID { return n.id }
func (n note) GetValue() (string, notes.GraphNote, error) {
	vt := n.valuetype
	if vt == nil {
		vt = notes.EmptyNote(notes.EmptyID)
	}
	return n.valuestring, vt, nil
}
func (n note) GetContents() ([]notes.GraphNote, error) { return n.contents, nil }
func (n note) GetTypes() ([]notes.GraphNote, error)    { return n.types, nil }

func yamlString(lines ...string) string { return strings.Join(lines, "\n") + "\n" }

var TestCases = []struct {
	// Name of test case
	N string
	// Reason to skip the test case
	Skip string
	// Alternative input YAML docs that should represent the same thing, each
	// with a key that describes what is different about that YAML doc.
	IY map[string]string
	// GraphNote representation of note
	GN note
	// Canonical YAML
	CY string
}{
	{
		N: "note with one content",
		GN: note{
			id: "10",
			contents: []notes.GraphNote{
				&note{id: "11", valuestring: "test content"},
			},
		},
		CY: yamlString(
			"note: &10",
			"    - &11 test content",
		),
	}, {
		N: "note with an untyped value and no content",
		GN: note{
			id:          "10",
			valuestring: "test value",
		},
		CY: yamlString(
			"note: &10",
			"    - is: test value",
		),
	}, {
		N: "note with a value and multiple contents",
		GN: note{
			id:          "10",
			valuestring: "value10",
			contents: []notes.GraphNote{
				&note{id: "11", valuestring: "value11"},
				&note{id: "12", valuestring: "value12"},
			},
		},
		CY: yamlString(
			"note: &10",
			"    - is: value10",
			"    - &11 value11",
			"    - &12 value12",
		),
	}, {
		N: "note with a typed value",
		GN: note{
			id:          "10",
			valuestring: "value10",
			valuetype:   note{id: "type11"},
		},
		CY: yamlString(
			"note: &10",
			"    - is: !<type11> value10",
		),
	}, {
		N: "note with typed content",
		GN: note{
			id: "10",
			contents: []notes.GraphNote{
				&note{
					id:          "11",
					valuestring: "topic name",
					types: []notes.GraphNote{
						&note{id: "name"},
					},
				},
			},
		},
		CY: yamlString(
			"note: &10",
			"    - name: &11 topic name",
		),
	}, {
		N: "note with complex content",
		GN: note{
			id: "10",
			contents: []notes.GraphNote{
				&note{
					id:          "11",
					valuestring: "ThreadsDB",
					types: []notes.GraphNote{
						&note{id: "name"},
					},
					contents: []notes.GraphNote{
						&note{
							id:          "13",
							types:       []notes.GraphNote{&note{id: "question"}},
							valuestring: "can one DB have many threads?",
						},
					},
				},
				&note{
					id:          "12",
					valuestring: "encrypted p2p database",
				},
			},
		},
		CY: yamlString(
			"note: &10",
			"    - name: &11",
			"        - is: ThreadsDB",
			"        - question: &13 can one DB have many threads?",
			"    - &12 encrypted p2p database",
		),
	},
}

func TestMarshal(t *testing.T) {
	for _, test := range TestCases {
		t.Run(test.N, func(t *testing.T) {
			if test.Skip != "" {
				t.Skip(test.Skip)
			}
			bs, err := MarshalNote(test.GN)
			if err != nil {
				t.Error(err)
			} else if string(bs) != test.CY {
				t.Errorf(
					"expected yaml:\n%vactual yaml:\n%v",
					test.CY,
					string(bs))
			}
		})
	}
}

func TestUnmarshal(t *testing.T) {
	for _, test := range TestCases {
		t.Run(test.N, func(t *testing.T) {
			if test.Skip != "" {
				t.Skip(test.Skip)
			}
			t.Logf("CY %v", test.CY)
			t.Logf("GN %#v", test.GN)
			bss, err := json.Marshal(test.GN)
			if err != nil {
				t.Fatal(err)
			}
			var actual NoteModel
			err = UnmarshalNote([]byte(test.CY), &actual)
			if err != nil {
				t.Error(err)
			} else if !notestest.ExpectEqual(t, &actual, test.GN) {
				bs0, err := json.Marshal(actual)
				if err != nil {
					t.Fatal(err)
				}
				bs1, err := json.Marshal(test.GN)
				if err != nil {
					t.Fatal(err)
				}
				t.Log("got  ", string(bs0))
				t.Log("want ", string(bs1))
				t.Log("wan0 ", string(bss))
			}
		})
	}
}

func TestUnmarshalMarshal_canonical(t *testing.T) {
	for _, test := range TestCases {
		t.Run(test.N, func(t *testing.T) {
			if test.Skip != "" {
				t.Skip(test.Skip)
			}
			var m NoteModel
			err := UnmarshalNote([]byte(test.CY), &m)
			if err != nil {
				t.Error(err)
			} else {
				bs, err := MarshalNote(test.GN)
				if err != nil {
					t.Error(err)
				} else if string(bs) != test.CY {
					t.Errorf(
						"expected yaml:\n%vactual yaml:\n%v",
						test.CY,
						string(bs))
				}
			}
		})
	}
}
