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

	"github.com/google/note-maps/note"
	"github.com/google/note-maps/note/notetest"
)

type N struct {
	id          note.ID
	valuestring string
	valuetype   note.GraphNote
	contents    []note.GraphNote
	types       []note.GraphNote
}

func (n N) GetID() note.ID { return n.id }
func (n N) GetValue() (string, note.GraphNote, error) {
	vt := n.valuetype
	if vt == nil {
		vt = note.EmptyNote(note.EmptyID)
	}
	return n.valuestring, vt, nil
}
func (n N) GetContents() ([]note.GraphNote, error) { return n.contents, nil }
func (n N) GetTypes() ([]note.GraphNote, error)    { return n.types, nil }

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
	GN N
	// Canonical YAML
	CY string
}{
	{
		N: "note with one content",
		GN: N{
			id: "10",
			contents: []note.GraphNote{
				&N{id: "11", valuestring: "test content"},
			},
		},
		CY: yamlString(
			"note: &10",
			"    - &11 test content",
		),
	}, {
		N: "note with an untyped value and no content",
		GN: N{
			id:          "10",
			valuestring: "test value",
		},
		CY: yamlString(
			"note: &10",
			"    - is: test value",
		),
	}, {
		N: "note with a value and multiple contents",
		GN: N{
			id:          "10",
			valuestring: "value10",
			contents: []note.GraphNote{
				&N{id: "11", valuestring: "value11"},
				&N{id: "12", valuestring: "value12"},
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
		GN: N{
			id:          "10",
			valuestring: "value10",
			valuetype:   N{id: "type11"},
		},
		CY: yamlString(
			"note: &10",
			"    - is: !<type11> value10",
		),
	}, {
		N: "note with typed content",
		GN: N{
			id: "10",
			contents: []note.GraphNote{
				&N{
					id:          "11",
					valuestring: "topic name",
					types: []note.GraphNote{
						&N{id: "name"},
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
		GN: N{
			id: "10",
			contents: []note.GraphNote{
				&N{
					id:          "11",
					valuestring: "ThreadsDB",
					types: []note.GraphNote{
						&N{id: "name"},
					},
					contents: []note.GraphNote{
						&N{
							id:          "13",
							types:       []note.GraphNote{&N{id: "question"}},
							valuestring: "can one DB have many threads?",
						},
					},
				},
				&N{
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
			var actual note.Plain
			err = UnmarshalNote([]byte(test.CY), &actual)
			if err != nil {
				t.Error(err)
			} else if !notetest.ExpectEqual(t, actual.GraphNote(), test.GN) {
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
			var m note.Plain
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
