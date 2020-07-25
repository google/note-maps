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

func yamlString(lines ...string) string { return strings.Join(lines, "\n") + "\n" }

func TestMarshalUnmarshal(t *testing.T) {
	for _, test := range []struct {
		title string
		note  note
		yaml  string
	}{
		//{},
		//{ yaml: "note:\n- name: test", },
		{
			"note with one content",
			note{
				id: "10",
				contents: []notes.GraphNote{
					&note{id: "11", valuestring: "test content"},
				},
			},
			yamlString(
				"note: &10",
				"    - &11 test content",
			),
		}, {
			"note with an untyped value and no content",
			note{
				id:          "10",
				valuestring: "test value",
			},
			yamlString(
				"note: &10",
				"    - is: test value",
			),
		}, {
			"note with a value and multiple contents",
			note{
				id:          "10",
				valuestring: "value10",
				contents: []notes.GraphNote{
					&note{id: "11", valuestring: "value11"},
					&note{id: "12", valuestring: "value12"},
				},
			},
			yamlString(
				"note: &10",
				"    - is: value10",
				"    - &11 value11",
				"    - &12 value12",
			),
		}, {
			"note with a typed value",
			note{
				id:          "10",
				valuestring: "value10",
				valuetype:   note{id: "type11"},
			},
			yamlString(
				"note: &10",
				"    - is: !<type11> value10",
			),
		},
	} {
		t.Run(test.title, func(t *testing.T) {
			var (
				diff notes.Stage
				note = diff.Note(notes.EmptyID)
			)
			err := UnmarshalNote([]byte(test.yaml), note)
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
			} else if string(bs) != test.yaml {
				t.Errorf(
					"expected yaml: %#v actual yaml: %#v",
					test.yaml,
					string(bs))
			}
		})
	}
}
