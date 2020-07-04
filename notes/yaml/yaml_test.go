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
	"github.com/google/note-maps/notes/change"
)

type note struct {
	id          uint64
	types       []notes.Note
	supertypes  []notes.Note
	valuestring string
	valuetype   notes.Note
	contents    []notes.Note
}

func (n note) GetId() uint64                         { return n.id }
func (n note) GetTypes() ([]notes.Note, error)       { return n.types, nil }
func (n note) GetSupertypes() ([]notes.Note, error)  { return n.supertypes, nil }
func (n note) GetValue() (string, notes.Note, error) { return n.valuestring, n.valuetype, nil }
func (n note) GetContents() ([]notes.Note, error)    { return n.contents, nil }

func getNote(d *notes.Stage, focus uint64) *note {
	ns := make(map[uint64]*note)
	get := func(id uint64) *note {
		if focus == 0 {
			focus = id
		}
		n, exists := ns[id]
		if !exists {
			n = &note{id: id}
			ns[id] = n
		}
		return n
	}
	for _, dop := range d.Ops {
		switch op := dop.(type) {
		case *change.SetValue:
			n := get(op.Id)
			n.valuestring = op.Lexical
			n.valuetype = get(op.Datatype)
		case *change.AddContent:
			n := get(op.Id)
			n.contents = append(n.contents, get(op.Add))
		default:
			panic("unknown operation type")
		}
	}
	return get(focus)
}

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
				id: 10,
				contents: []notes.Note{
					&note{id: 11, valuestring: "test content"},
				},
			},
			yamlString(
				"note: &10",
				"    - &11 test content",
			),
		}, {
			"note with a value and no content",
			note{
				id:          10,
				valuestring: "test value",
			},
			yamlString(
				"note: &10",
				"    - is: test value",
			),
		},
	} {
		t.Run(test.title, func(t *testing.T) {
			var (
				diff notes.Stage
				note = diff.Note(notes.EmptyId)
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
				if equal, err := notes.Equal(note, test.note); err != nil {
					t.Error(err)
				} else if !equal {
					diff, a, b, err := notes.DebugDiff(note, test.note)
					if err != nil {
						t.Error(err)
					} else {
						t.Errorf("mismatched notes: %s got %#v, expected %#v", diff, a, b)
					}
				}
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
