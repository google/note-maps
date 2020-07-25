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
	"errors"
	"reflect"
	"strings"
	"testing"

	"github.com/google/note-maps/notes"
	"github.com/google/note-maps/notes/notestest"
)

type nn struct {
	notes.ID
	VS string
	VT notes.Note
	CS []notes.Note
}

func (n nn) GetID() notes.ID                       { return n.ID }
func (n nn) GetValue() (string, notes.Note, error) { return n.VS, n.VT, nil }
func (n nn) GetContents() ([]notes.Note, error)    { return n.CS, nil }

type brokenValue struct{ nn }

func (n brokenValue) GetValue() (string, notes.Note, error) {
	return "", nil, errors.New("brokenValue")
}

type brokenContents struct{ nn }

func (n brokenContents) GetContents() ([]notes.Note, error) {
	return nil, errors.New("brokenContents")
}

func TestTruncateNote(t *testing.T) {
	actual, err := TruncateNote(nn{
		ID: "id",
		VS: "value",
		VT: notes.EmptyNote("vt"),
		CS: []notes.Note{notes.EmptyNote("c0"), notes.EmptyNote("c1")},
	})
	if err != nil {
		t.Fatal(err)
	}
	expected := TruncatedNote{
		ID:          "id",
		ValueString: "value",
		ValueType:   "vt",
		Contents:    []notes.ID{"c0", "c1"},
	}
	if !reflect.DeepEqual(actual, expected) {
		t.Errorf("got %#v, expected %#v", actual, expected)
	}
}

func TestTruncateNote_errorIfValueBroken(t *testing.T) {
	_, err := TruncateNote(brokenValue{nn{
		ID: "id",
		VS: "value",
		VT: notes.EmptyNote("vt"),
		CS: []notes.Note{notes.EmptyNote("c0"), notes.EmptyNote("c1")},
	}})
	if err == nil || !strings.HasSuffix(err.Error(), "brokenValue") {
		t.Fatal("got", err, "expected brokenValue")
	}
}

func TestTruncateNote_errorIfContentsBroken(t *testing.T) {
	_, err := TruncateNote(brokenContents{nn{
		ID: "id",
		VS: "value",
		VT: notes.EmptyNote("vt"),
		CS: []notes.Note{notes.EmptyNote("c0"), notes.EmptyNote("c1")},
	}})
	if err == nil || !strings.HasSuffix(err.Error(), "brokenContents") {
		t.Fatal("got", err, "expected brokenContents")
	}
}

func TestTruncateNote_Equals(t *testing.T) {
	for _, test := range []struct {
		A, B  TruncatedNote
		Equal bool
	}{
		{TruncatedNote{}, TruncatedNote{}, true},
		{
			TruncatedNote{},
			TruncatedNote{"", "", "", []notes.ID{}},
			true,
		},
		{TruncatedNote{ID: "0"}, TruncatedNote{}, false},
		{TruncatedNote{ID: "0"}, TruncatedNote{ID: "0"}, true},
		{
			TruncatedNote{ValueString: "x"},
			TruncatedNote{ValueString: "y"},
			false,
		},
		{
			TruncatedNote{ValueString: "x"},
			TruncatedNote{ValueString: "x"},
			true,
		},
		{
			TruncatedNote{ValueType: "x"},
			TruncatedNote{ValueType: "y"},
			false,
		},
		{
			TruncatedNote{ValueType: "x"},
			TruncatedNote{ValueType: "x"},
			true,
		},
		{
			TruncatedNote{Contents: []notes.ID{"x"}},
			TruncatedNote{Contents: []notes.ID{"y"}},
			false,
		},
		{
			TruncatedNote{Contents: []notes.ID{"x"}},
			TruncatedNote{Contents: []notes.ID{"x"}},
			true,
		},
	} {
		if test.A.Equals(test.B) != test.B.Equals(test.A) {
			t.Errorf("A.Equals(B) != B.Equals(A) : %v != %v",
				test.A.Equals(test.B), test.B.Equals(test.A))
		}
		if test.A.Equals(test.B) != test.Equal {
			t.Errorf("%#v==%#v got %v, expected %v",
				test.A, test.B, !test.Equal, test.Equal)
		}
	}
}

type findloader map[notes.ID]TruncatedNote

func (x findloader) FindNoteIDs(q *notes.Query) ([]notes.ID, error) {
	var ids []notes.ID
	for id := range x {
		ids = append(ids, id)
	}
	return ids, nil
}
func (x findloader) LoadTruncatedNotes(ids []notes.ID) ([]TruncatedNote, error) {
	tns := make([]TruncatedNote, len(ids))
	for i, id := range ids {
		var ok bool
		tns[i], ok = x[id]
		if !ok {
			tns[i] = TruncatedNote{ID: id}
		}
	}
	return tns, nil
}

func TestExpandLoader(t *testing.T) {
	fl := make(findloader)
	for _, tn := range []TruncatedNote{
		{ID: "one", ValueString: "value1", ValueType: "two", Contents: []notes.ID{"three", "four"}},
		{ID: "two", ValueString: "value2", ValueType: "three"},
		{ID: "three", ValueString: "value3"},
	} {
		fl[tn.ID] = tn
	}
	l := ExpandLoader(fl)
	notestest.TestLoader(t, l)
	ns, err := l.Load([]notes.ID{"one", "two"})
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
	expectIDs := []notes.ID{"one", "two"}
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
	ns, err = l.Load([]notes.ID{"three", "four"})
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

func TestDiffPatch(t *testing.T) {
	for _, test := range []struct {
		Title string
		A, B  TruncatedNote
	}{
		{Title: "empty notes"},
		{Title: "change value string",
			A: TruncatedNote{ValueString: "a"},
			B: TruncatedNote{ValueString: "b"}},
		{Title: "change value type",
			A: TruncatedNote{ValueType: "vt0"},
			B: TruncatedNote{ValueType: "vt1"}},
		{Title: "add content",
			A: TruncatedNote{Contents: []notes.ID{"a"}},
			B: TruncatedNote{Contents: []notes.ID{"a", "b"}}},
		{Title: "remove content",
			A: TruncatedNote{Contents: []notes.ID{"a", "b"}},
			B: TruncatedNote{Contents: []notes.ID{"a"}}},
		{Title: "insert content",
			A: TruncatedNote{Contents: []notes.ID{"a", "b"}},
			B: TruncatedNote{Contents: []notes.ID{"a", "c", "b"}}},
		{Title: "swap content",
			A: TruncatedNote{Contents: []notes.ID{"a", "b"}},
			B: TruncatedNote{Contents: []notes.ID{"b", "a"}}},
	} {
		t.Run(test.Title, func(t *testing.T) {
			ops := Diff(test.A, test.B)
			newB := test.A
			if err := Patch(&newB, ops); err != nil {
				t.Error(err)
			} else if !newB.Equals(test.B) {
				t.Errorf("got %#v, expected %#v, applying %#v to %#v",
					newB, test.B, ops, test.A)
			}
		})
	}
}
