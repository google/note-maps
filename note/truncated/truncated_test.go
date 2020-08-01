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

package truncated

import (
	"testing"

	"github.com/google/note-maps/note"
	"github.com/google/note-maps/note/dbtest"
)

type findloader map[note.ID]note.TruncatedNote

func (x findloader) FindNoteIDs(q *note.Query) ([]note.ID, error) {
	var ids []note.ID
	for id := range x {
		ids = append(ids, id)
	}
	return ids, nil
}
func (x findloader) LoadTruncatedNotes(ids []note.ID) ([]note.TruncatedNote, error) {
	tns := make([]note.TruncatedNote, len(ids))
	for i, id := range ids {
		var ok bool
		tns[i], ok = x[id]
		if !ok {
			tns[i] = note.TruncatedNote{ID: id}
		}
	}
	return tns, nil
}

func TestExpandLoader(t *testing.T) {
	fl := make(findloader)
	for _, tn := range []note.TruncatedNote{
		{ID: "one", ValueString: "value1", ValueType: "two", Contents: []note.ID{"three", "four"}},
		{ID: "two", ValueString: "value2", ValueType: "three"},
		{ID: "three", ValueString: "value3"},
	} {
		fl[tn.ID] = tn
	}
	l := ExpandLoader(fl)
	dbtest.TestLoader(t, l)
	ns, err := l.Load([]note.ID{"one", "two"})
	if err != nil {
		t.Fatal(err)
	}
	if len(ns) != 2 {
		t.Fatal("expected two ns, got ", len(ns))
	}
	one, two := ns[0], ns[1]
	if _, vt, err := one.GetValue(); err != nil {
		t.Error(err)
	} else if vt != two {
		t.Errorf("value type of %v: exepcted %v != actual %v", ns[0], ns[1], vt)
	}
	expectIDs := []note.ID{"one", "two"}
	expectValueStrings := []string{"value1", "value2"}
	expectValueTypeValueStrings := []string{"value2", "value3"}
	for i := range expectIDs {
		if ns[i].GetID() != expectIDs[i] {
			t.Errorf("%v: expected %v, got %v", i, expectIDs[i], ns[i].GetID())
		}
		if vs, vt, err := ns[i].GetValue(); err != nil {
			t.Errorf("%v: %v", i, err)
		} else {
			if vs != expectValueStrings[i] {
				t.Errorf("%v: expected %v, got %v", i, expectValueStrings[i], vs)
			}
			if vs, vt, err = vt.GetValue(); err != nil {
				t.Errorf("%v: %v", i, err)
			} else if vs != expectValueTypeValueStrings[i] {
				t.Errorf("%v: expected %v, got %v", i, expectValueTypeValueStrings[i], vs)
			}
		}
	}
	ns, err = l.Load([]note.ID{"three", "four"})
	if err != nil {
		t.Fatal(err)
	}
	three, four := ns[0], ns[1]
	cs, err := one.GetContents()
	if err != nil {
		t.Fatal(err)
	}
	if three != cs[0] {
		t.Errorf("expected %v, got %v", three, cs[0])
	}
	if four != cs[1] {
		t.Errorf("expected %v, got %v", four, cs[1])
	}
}
