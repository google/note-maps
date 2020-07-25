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

package notestest

import (
	"errors"
	"math/rand"
	"strconv"
	"testing"

	"github.com/google/note-maps/notes"
)

// RandomID returns a pseudo-random ID using package math/rand.
func RandomID() notes.ID {
	return notes.ID(strconv.FormatUint(rand.Uint64(), 10))
}

// BreakingLoader is an optionally partly broken proxy to a Loader.
type BreakingLoader struct {
	notes.Loader
	Count      int
	ErrAtCount int
	Err        error
}

// Load returns l.Err when l.Count==l.ErrAtCount, and otherwise return
// l.Loader.Load(ids).
//
// In any case, Load() will increment Count.
//
// When l.Err is nil, l is just a Count incrementing proxy to l.Loader.
func (l *BreakingLoader) Load(ids []notes.ID) ([]notes.Note, error) {
	if len(ids) == 0 {
		return nil, nil
	}
	l.Count++
	if l.ErrAtCount == l.Count-1 && l.Err != nil {
		return nil, l.Err
	}
	return l.Loader.Load(ids)
}

// BrokenNote implements notes.Note but always returns an error when attempting
// to read anything other than the ID.
type BrokenNote struct {
	notes.ID
	Err error
}

// GetID always gets the ID.
func (n BrokenNote) GetID() notes.ID { return n.ID }

// GetValue always returns n.Err.
func (n BrokenNote) GetValue() (string, notes.Note, error) { return "", nil, n.Err }

// GetContents always returns n.Err.
func (n BrokenNote) GetContents() ([]notes.Note, error) { return nil, n.Err }

// BrokenNoteLoader loads instances of BrokenNote.
type BrokenNoteLoader struct{ Err error }

// Load will always successfully load all requested notes without error, but
// the returned notes will always return errors when attempts are made to read
// them.
func (l *BrokenNoteLoader) Load(ids []notes.ID) ([]notes.Note, error) {
	ns := make([]notes.Note, len(ids))
	for i, id := range ids {
		if id.Empty() {
			return nil, notes.InvalidID
		}
		ns[i] = BrokenNote{ID: id, Err: l.Err}
	}
	return ns, nil
}

// TestLoader will run a few tests against l that are meant to fail if l does
// not implement the notes.Loader interface correctly.
func TestLoader(t testing.TB, l notes.Loader) {
	t.Log("loading zero notes...")
	ns, err := l.Load(nil)
	if err != nil {
		t.Error(err)
	} else if len(ns) != 0 {
		t.Error("expected zero notes, got", len(ns))
	}
	t.Log("loading one note...")
	id := RandomID()
	ns, err = l.Load([]notes.ID{id})
	if err != nil {
		t.Error(err)
	} else if len(ns) != 1 {
		t.Error("expected one note, got", len(ns), "and no error")
	} else if len(ns) >= 1 {
		if actual := ns[0].GetID(); actual != id {
			t.Error("expected", id, "got", actual)
		}
	}
	t.Log("loading multiple notes...")
	ids := []notes.ID{RandomID(), RandomID(), RandomID()}
	ns, err = l.Load(ids)
	if err != nil {
		t.Error(err)
	} else if len(ns) != len(ids) {
		t.Error("expected", len(ids), "notes, got", len(ns))
	}
	for i, expected := range ids {
		if i < len(ns) && ns[i].GetID() != expected {
			t.Error(i, "expected ID", expected, "got ID", ns[i].GetID())
		}
	}
	t.Log("sending EmptyID...")
	ids = []notes.ID{RandomID(), RandomID(), RandomID()}
	for i := range ids {
		bads := append([]notes.ID{}, ids...)
		bads[i] = notes.EmptyID
		_, err := l.Load(bads)
		if !errors.Is(err, notes.InvalidID) {
			t.Error("with bad ID at", i, "expected", notes.InvalidID)
		}
	}
}
