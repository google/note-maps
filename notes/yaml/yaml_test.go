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

func TestMarshalUnmarshal(t *testing.T) {
	for _, test := range []struct {
		title     string
		skip      string
		note      note
		canonical string
	}{
		//{},
		//{ yaml: "note:\n- name: test", },
		{
			title: "note with one content",
			note: note{
				id: "10",
				contents: []notes.GraphNote{
					&note{id: "11", valuestring: "test content"},
				},
			},
			canonical: yamlString(
				"note: &10",
				"    - &11 test content",
			),
		}, {
			title: "note with an untyped value and no content",
			note: note{
				id:          "10",
				valuestring: "test value",
			},
			canonical: yamlString(
				"note: &10",
				"    - is: test value",
			),
		}, {
			title: "note with a value and multiple contents",
			note: note{
				id:          "10",
				valuestring: "value10",
				contents: []notes.GraphNote{
					&note{id: "11", valuestring: "value11"},
					&note{id: "12", valuestring: "value12"},
				},
			},
			canonical: yamlString(
				"note: &10",
				"    - is: value10",
				"    - &11 value11",
				"    - &12 value12",
			),
		}, {
			title: "note with a typed value",
			note: note{
				id:          "10",
				valuestring: "value10",
				valuetype:   note{id: "type11"},
			},
			canonical: yamlString(
				"note: &10",
				"    - is: !<type11> value10",
			),
		}, {
			title: "note with typed content",
			note: note{
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
			canonical: yamlString(
				"note: &10",
				"    - name: &11 topic name",
			),
		}, {
			title: "note with complex content",
			skip:  "this doesn't quite work yet",
			note: note{
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
								id: "en",
								types: []notes.GraphNote{
									&note{id: "lang"},
								},
							},
						},
					},
					&note{
						id:          "12",
						valuestring: "encrypted p2p database",
					},
				},
			},
			canonical: yamlString(
				"note: &10",
				"    - name: &11 ThreadsDB",
				"      lang: &en",
				"    - &12 encrypted p2p database",
			),
		},
	} {
		t.Run(test.title, func(t *testing.T) {
			if test.skip != "" {
				t.Skip(test.skip)
			}
			var (
				diff notes.Stage
				note = diff.Note(notes.EmptyID)
			)
			err := UnmarshalNote([]byte(test.canonical), note)
			if err != nil {
				t.Error(err)
			} else {
				t.Log("diff begin")
				for _, op := range diff.Ops {
					t.Log(op)
				}
				t.Log("diff end")
				notestest.ExpectEqual(t, note, test.note)
			}
			bs, err := MarshalNote(test.note)
			if err != nil {
				t.Error(err)
			} else if string(bs) != test.canonical {
				t.Errorf(
					"expected yaml: %#v actual yaml: %#v",
					test.canonical,
					string(bs))
			}
		})
	}
}
